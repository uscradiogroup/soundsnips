//
//  BaseViewController.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 3/30/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import "BaseViewController.h"
#import "AudioStreamer.h"
#import "MusicPlayerViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

	if ([[MusicPlayerViewController sharedMusicPlayerViewController].audioStreamer isPlaying]) {
		
		// Now Playing Button
		UIImage* nowPlayingImage = [UIImage imageNamed:@"NowPlayingButton"];
		UIButton* nowPlayingButton = [UIButton buttonWithType:UIButtonTypeCustom];
		nowPlayingButton.frame = CGRectMake(0, 0,  nowPlayingImage.size.width,  nowPlayingImage.size.height);
		[nowPlayingButton setImage: nowPlayingImage forState:UIControlStateNormal];
		[nowPlayingButton addTarget:self action:@selector(nowPlayingAction:) forControlEvents:UIControlEventTouchUpInside];
		
		UIBarButtonItem* nowPlayingBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:nowPlayingButton]; 
		self.navigationItem.rightBarButtonItem = nowPlayingBarButtonItem;
	}
	else {
		self.navigationItem.rightBarButtonItem = nil;
	}	
 
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)nowPlayingAction:(id)sender
{
	[self.navigationController pushViewController:[MusicPlayerViewController sharedMusicPlayerViewController]
										 animated:YES];

}

@end
