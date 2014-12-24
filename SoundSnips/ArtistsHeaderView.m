//
//  ArtistsHeaderView.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 3/15/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import "ArtistsHeaderView.h"
#import <QuartzCore/QuartzCore.h>

@implementation ArtistsHeaderView

@synthesize textLabel = _textLabel;

- (id)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 320, ArtistsHeaderViewHeight)];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
		self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 2, 300, 20)];
		self.textLabel.backgroundColor = [UIColor clearColor];
		self.textLabel.opaque = NO;
		self.textLabel.textColor = [UIColor whiteColor];
		self.textLabel.shadowOffset = CGSizeMake(0, 0.5f);
		self.textLabel.shadowColor = [UIColor blackColor];
		self.textLabel.font = [UIFont boldSystemFontOfSize:18];
		[self addSubview:self.textLabel];
		
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, 0, 0);
	CGContextAddLineToPoint(context, 320, 0);
	CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5].CGColor);
	CGContextStrokePath(context);
	
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, 0, self.frame.size.height - 1);
	CGContextAddLineToPoint(context, 320, self.frame.size.height - 1);
	CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5].CGColor);
	CGContextStrokePath(context);
}


@end
