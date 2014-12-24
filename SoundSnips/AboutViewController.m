//
//  LinkWebViewController.m
//  SpotFinder
//
//  Created by Sherwin Zadeh on 11/24/11.
//  Copyright (c) 2011 Artamata, Inc. All rights reserved.
//

#import "AboutViewController.h"
#import "GANTracker.h"

#define ABOUT_URL (@"http://soundsnips.org/about")

@implementation AboutViewController

@synthesize webView = _webView;
@synthesize spinner = _spinner;

- (id)init
{
    self = [super init];
    if (self) {
		self.title = @"About";
		self.tabBarItem.image = [UIImage imageNamed:@"About"];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	NSURL* url = [NSURL URLWithString:ABOUT_URL];
	NSURLRequest* request = [NSURLRequest requestWithURL:url];
	
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavBarBackground"] 
												  forBarMetrics:UIBarMetricsDefault];	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"PlaylistBackground"]];
	

	self.webView.alpha = 0;
	self.webView.scalesPageToFit = YES;
	[self.webView loadRequest:request];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	NSError* error = nil;
	if (![[GANTracker sharedTracker] trackPageview:@"/about"
										 withError:&error]) {
		NSLog(@"error in trackPageview");
	}
	
}

- (void)viewDidUnload
{
	[self setSpinner:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[self.spinner startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
	[self.spinner stopAnimating];
	[UIView animateWithDuration:1 animations:^{
			self.webView.alpha = 1;
	}];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType 
{
	NSLog(@"expected:%d, got:%d", UIWebViewNavigationTypeLinkClicked, navigationType);
	if (navigationType == UIWebViewNavigationTypeLinkClicked)  {
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	}
	
	return YES;
}


@end
