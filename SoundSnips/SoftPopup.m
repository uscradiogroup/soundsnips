//
//  SoftPopup.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 5/10/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import "SoftPopup.h"
#import <QuartzCore/QuartzCore.h>

SoftPopup* g_softPopup = nil;

@interface SoftPopup()

@property (strong) UIImageView*	imageView;
@property (strong) UILabel*		label;

@end

@implementation SoftPopup

@synthesize imageView = _imageView;
@synthesize label = _label;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
		self.layer.cornerRadius = 10.0f;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

+(SoftPopup*)sharedSoftPopup
{
	if (g_softPopup == nil) {
		g_softPopup = [[SoftPopup alloc] initWithFrame:CGRectMake(0, 0, 75, 75)];
		g_softPopup.center = CGPointMake(320.0/2,480.0/2);
	}
	
	return g_softPopup;
}


-(void)show:(UIImage*)image text:(NSString*)text
{
	self.alpha = 1.0;

	if (self.label == nil) {
		self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.bounds.size.height * .66, self.frame.size.width, 20)];
		self.label.backgroundColor = [UIColor clearColor];
		self.label.text = text;
		self.label.textColor = [UIColor whiteColor];
		self.label.textAlignment = UITextAlignmentCenter;
		self.label.font = [UIFont boldSystemFontOfSize:10];
		[self addSubview:self.label];
	}
	
	if (self.imageView == nil) {
		self.imageView = [[UIImageView alloc] initWithImage:image];
		self.imageView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
		[self addSubview:self.imageView];
	}
	
	[[[[UIApplication sharedApplication] delegate] window] addSubview:g_softPopup];

	[NSTimer scheduledTimerWithTimeInterval:1
									 target:self
								   selector:@selector(timerEvent:)
								   userInfo:nil 
									repeats:NO];
}

- (void)timerEvent:(NSTimer*)theTimer
{
	[UIView animateWithDuration:2
					 animations:^{
						 self.alpha = 0;
					 } 
					 completion:^(BOOL finished) {
						 [self removeFromSuperview];
					 }];
}

@end
