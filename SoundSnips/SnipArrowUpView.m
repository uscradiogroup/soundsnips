//
//  SnipArrowUpView.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 4/16/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import "SnipArrowUpView.h"

#define ARROW_WIDTH 20



@interface SnipArrowUpView() {
	float _arrowLocation;
}

@end


@implementation SnipArrowUpView

@dynamic arrowLocation;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
//		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	float xPosition = self.arrowLocation;
	float lineWidth = 0;
	float yTopPosition = lineWidth;
	float yBottomPosition = self.frame.size.height - 1;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	
	// Create Path
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, xPosition - ARROW_WIDTH / 2, yBottomPosition);
	CGPathAddLineToPoint(path, NULL, xPosition, yTopPosition);
	CGPathAddLineToPoint(path, NULL, xPosition + ARROW_WIDTH / 2, yBottomPosition);
	CGPathAddLineToPoint(path, NULL, xPosition - ARROW_WIDTH / 2, yBottomPosition);
	
	// Fill
	CGContextAddPath(context, path);
	CGContextSetFillColorWithColor(context, [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8].CGColor);
	CGContextFillPath(context);
	
	CGContextRestoreGState(context);
	CGPathRelease(path);	
}

-(float)arrowLocation 
{
	return _arrowLocation;
}

-(void)setArrowLocation:(float)arrowLocation
{
	_arrowLocation = arrowLocation;
	[self setNeedsDisplay];
}

@end
