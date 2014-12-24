//
//  WebService.m
//  FlavorInfusion
//
//  Created by Sherwin Zadeh on 12/8/11.
//  Copyright (c) 2011 Artamata, Inc. All rights reserved.
//

#include <libkern/OSAtomic.h>
#import "WebService.h"


static int s_numberOfRunningWebServices = 0;

// Private interface

@interface WebService ()

@property (retain) NSURL* url;
@property (copy) WebServiceBlock finishedBlock;
@property (assign) UIBackgroundTaskIdentifier	backgroundTaskId;
@property (strong) NSURLConnection*				connection;
@property (strong) NSMutableData*				receivedData;
@property (assign) long long					expectedDataSize;

@end

// Implementation

@implementation WebService

@synthesize url = _url;
@synthesize finishedBlock = _finishedBlock;
@synthesize backgroundTaskId = _backgroundTaskId;
@synthesize connection = _connection;
@synthesize receivedData = _receivedData;
@synthesize expectedDataSize = _expectedDataSize;

-(id)init
{
	self = [super init];
	if (self) {
	}
	return self;
}


-(BOOL)isDownloading 
{
	return (self.url != nil);
}

-(NSURLRequest*)requestWithURL:(NSURL*)url
{
	return [NSURLRequest requestWithURL:url
							cachePolicy:NSURLRequestUseProtocolCachePolicy
						timeoutInterval:90.0];
}

-(void)beginRequestWithURL:(NSURL*)url finished:(WebServiceBlock)finishedBlock 
{
	OSAtomicIncrement32(&s_numberOfRunningWebServices);
	NSLog(@"NumberOfRunningWebServices++ == %d", s_numberOfRunningWebServices);
	
	self.finishedBlock = finishedBlock;
	
	NSLog(@"Beginning WebService Request: %@", url.absoluteString);

	self.backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		if ([self isDownloading]) {
			
			self.connection = nil;
			self.receivedData = nil;
			
			self.finishedBlock(nil);
		}		
	}];
	
	self.url = url;
	
	// create the request
	NSURLRequest* request = [self requestWithURL:url];
	
	self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (self.connection) {
		self.receivedData = [NSMutableData data];
	} 
	else {
		if (self.finishedBlock != nil) {
			self.finishedBlock(nil);
			
			OSAtomicDecrement32(&s_numberOfRunningWebServices);
			NSLog(@"NumberOfRunningWebServices-- == %d", s_numberOfRunningWebServices);			
			if (s_numberOfRunningWebServices == 0) {
				[[NSNotificationCenter defaultCenter] postNotificationName:WEBSERVICES_ALL_FINISHED_NOTIFICATION object:nil];
			}
				
		}
	}	
}

-(NSData*)cachedDataWithURL:(NSURL*)url
{
	NSURLRequest* request = [self requestWithURL:url];
	NSCachedURLResponse* cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
	if (cachedResponse == nil)
		return nil;

	NSData* data = [cachedResponse data];
	return data;
}


#pragma mark - NSURLConnectionDelegate

- (void)connection: (NSURLConnection*) connection didReceiveResponse: (NSHTTPURLResponse*) response
{
    NSInteger statusCode = [response statusCode];
    if (statusCode == 200) {
        self.expectedDataSize = [response expectedContentLength];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (connection == self.connection) {
		
        [self.receivedData appendData:data];
		
//		float progress = ((float)self.receivedData.length / (float)self.expectedDataSize);				
//		NSLog(@"Downloading (%f percent)", progress);		
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    self.connection = nil;
	
    // receivedData is declared as a method instance elsewhere
    self.receivedData = nil;
	
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
	
	self.url = nil;	
	
	self.finishedBlock(nil);
	
	OSAtomicDecrement32(&s_numberOfRunningWebServices);
	NSLog(@"NumberOfRunningWebServices-- == %d", s_numberOfRunningWebServices);
	if (s_numberOfRunningWebServices == 0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:WEBSERVICES_ALL_FINISHED_NOTIFICATION object:nil];
	}
	
	[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"Succeeded! (%@) Received %d bytes of data", self.url.relativeString, [self.receivedData length]);
			
    // release the connection
    self.connection = nil;
	
	self.url = nil;
	
	[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
	
	if (self.finishedBlock) {
		self.finishedBlock(self.receivedData);
	}
	
	OSAtomicDecrement32(&s_numberOfRunningWebServices);
	NSLog(@"NumberOfRunningWebServices-- == %d", s_numberOfRunningWebServices);
	if (s_numberOfRunningWebServices == 0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:WEBSERVICES_ALL_FINISHED_NOTIFICATION object:nil];
	}
	
    self.receivedData = nil;	
}

+(int)numberOfRunningWebServices
{
//	int count = [s_allWebServices count];
//	return count;
	return s_numberOfRunningWebServices;
}

@end
