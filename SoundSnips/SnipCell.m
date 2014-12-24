//
//  SnipCell.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 4/12/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "SnipCell.h"
#import "SnipLabel.h"


#define FONT_SIZE 32
#define CELL_CONTENT_VERT_MARGIN 15.0f
#define CELL_CONTENT_HORZ_MARGIN 30.0f
#define CELL_CONTENT_WIDTH (320.0f - 2 * CELL_CONTENT_HORZ_MARGIN)

static UIFont* s_font = nil;

@implementation SnipCell

@synthesize shouldDrawBottomSeparator = _shouldDrawBottomSeparator;
@synthesize snipLabel = _snipLabel;

static NSString* s_reuseIdentifier = @"SnipCell";

+(NSString*)reuseIdentifier
{
	return s_reuseIdentifier;
}

+(CGFloat)heightForText:(NSString*)text
{	
	CGSize constraint = CGSizeMake(CELL_CONTENT_WIDTH, FLT_MAX);
	
	CGSize size = [text sizeWithFont:[SnipCell font] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
	size.height = MAX(size.height, 44.0f) + (CELL_CONTENT_VERT_MARGIN * 2);	
	
//	CGSize constraintSize = CGSizeMake(280, 0);
//	return [text sizeWithFont:[[self class] font] constrainedToSize:constraintSize];
	return size.height;
}

+(UIFont*)font
{
	if (s_font == nil) {
//		s_font = [UIFont boldSystemFontOfSize:FONT_SIZE];
		s_font = [UIFont fontWithName:@"Wendy LP Std" size:FONT_SIZE];
		
	}
	
	return s_font;
}

- (id)init
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:s_reuseIdentifier];
    if (self) {
		self.shouldDrawBottomSeparator = YES;
		
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		self.backgroundView = nil;
		self.backgroundView.opaque = NO;
		self.contentView.opaque = NO;
		self.contentView.backgroundColor = [UIColor clearColor];
		
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		self.snipLabel = [[SnipLabel alloc] initWithFrame:CGRectZero];
		self.snipLabel.font = [SnipCell font];
		[self.contentView addSubview:self.snipLabel];
		
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews
{
	[super layoutSubviews];

	CGRect constraint = CGRectMake(CELL_CONTENT_HORZ_MARGIN, 0, CELL_CONTENT_WIDTH, FLT_MAX);
	self.snipLabel.frame = [self.snipLabel textRectForBounds:constraint limitedToNumberOfLines:0];
}

- (void)drawRect:(CGRect)rect
{
}



@end
