//
//  WebService.h
//  FlavorInfusion
//
//  Created by Sherwin Zadeh on 12/8/11.
//  Copyright (c) 2011 Artamata, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^WebServiceBlock)(NSData*);
#define WEBSERVICES_ALL_FINISHED_NOTIFICATION (@"WebService_All_Notifications_Finished")


@interface WebService : NSObject <NSURLConnectionDelegate>

-(void)beginRequestWithURL:(NSURL*)url finished:(WebServiceBlock)finishedBlock;
-(NSData*)cachedDataWithURL:(NSURL*)url;

+(int)numberOfRunningWebServices;


@end
