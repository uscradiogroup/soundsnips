//
//  SnipLabel.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 5/1/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SnipLabel.h"

@implementation SnipLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.backgroundColor = [UIColor clearColor];
		self.textColor = [UIColor blackColor];
		self.clipsToBounds = NO;
		self.textAlignment = UITextAlignmentLeft;
		self.userInteractionEnabled = NO;
		self.lineBreakMode = UILineBreakModeWordWrap;
		self.numberOfLines = 0;
		self.layer.shadowColor = [UIColor whiteColor].CGColor;
		self.layer.shadowOffset = CGSizeMake(0, 0.5);
		self.layer.shadowOpacity = 1.0;
		self.layer.shadowRadius = 0.5;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextScaleCTM(context, 0.9, 0.9);
	CGContextTranslateCTM(context, 10, 12);
	
	[super drawRect:rect];
}

@end
