//
//  HomeCell.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 3/6/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import "HomeCell.h"

@implementation HomeCell

static NSString* s_reuseIdentifier = @"HomeCell";

+(NSString*)reuseIdentifier
{
	return s_reuseIdentifier;
}

- (id)init	
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:s_reuseIdentifier];
    if (self) {
		self.opaque = NO;
		self.backgroundView = nil;
		self.backgroundView.opaque = NO;
		self.contentView.opaque = NO;
		self.contentView.backgroundColor = [UIColor clearColor];
		self.textLabel.textColor = [UIColor whiteColor];
		self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DisclosureArrow"]];
		self.textLabel.font = [UIFont fontWithName:@"Wendy LP Std" size:36];
		
		self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
		self.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:193/255.0 green:205/255.0 blue:36/255.0 alpha:1];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, 0, 0);
	CGContextAddLineToPoint(context, self.frame.size.width, 0);
	CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5].CGColor);
	CGContextStrokePath(context);

	CGContextBeginPath(context);
	CGContextMoveToPoint(context, 0, self.frame.size.height - 1);
	CGContextAddLineToPoint(context, self.frame.size.width, self.frame.size.height - 1);
	CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5].CGColor);
	CGContextStrokePath(context);
}

- (void)layoutSubviews
{
	[super layoutSubviews];

	CGRect textFrame = self.textLabel.frame;
	textFrame.origin.y += 12;
	textFrame.origin.x -= 10;
	self.textLabel.frame = textFrame;
}


@end
