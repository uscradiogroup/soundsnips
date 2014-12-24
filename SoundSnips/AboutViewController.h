//
//  LinkWebViewController.h
//  SpotFinder
//
//  Created by Sherwin Zadeh on 11/24/11.
//  Copyright (c) 2011 Artamata, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AboutViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView*				webView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView*	spinner;

@end
