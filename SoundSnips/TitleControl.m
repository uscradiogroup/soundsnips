//
//  TitleControl.m
//  SleepTunes
//
//  Created by Sherwin Zadeh on 7/13/09.
//  Copyright 2009 Artamata, Inc.. All rights reserved.
//

#import "TitleControl.h"


@implementation TitleControl

@synthesize	artistLabel = _artistLabel;
@synthesize	titleLabel = _titleLabel;
@synthesize	albumTitleLabel = _albumTitleLabel;

- (id)initWithFrame:(CGRect)frame 
{
    if (self = [super initWithFrame:frame]) 
	{
        // Initialization code
		self.backgroundColor = [UIColor clearColor];
		
		float width = frame.size.width;
		float height = 14;
		float yStart = (frame.size.height - 3 * height) / 2.0;
		UIFont* labelFont = [UIFont boldSystemFontOfSize:12];

		UIColor* dimLabelColor = [UIColor colorWithRed:119.0/255.0 green:204.0/255.0 blue:200.0/255.0 alpha:1];
		UIColor* brightLabelColor = [UIColor whiteColor];
		UIColor* labelShadowColor = [UIColor blackColor];
		CGSize labelShadowOffset = CGSizeMake(0, -0.5f);
		
		CGRect artistLabelRect = CGRectMake(0, yStart, width, height);
		self.artistLabel = [[UILabel alloc] initWithFrame:artistLabelRect];
		self.artistLabel.font = labelFont;
		self.artistLabel.textAlignment = UITextAlignmentCenter;
		self.artistLabel.textColor = dimLabelColor;
		self.artistLabel.shadowColor = labelShadowColor;
		self.artistLabel.shadowOffset = labelShadowOffset;
		self.artistLabel.backgroundColor = [UIColor clearColor];
		
		CGRect titleLabelRect = CGRectOffset(artistLabelRect, 0, height);
		self.titleLabel = [[UILabel alloc] initWithFrame:titleLabelRect];
		self.titleLabel.font = labelFont;
		self.titleLabel.textAlignment = UITextAlignmentCenter;
		self.titleLabel.textColor = brightLabelColor;
		self.titleLabel.shadowColor = labelShadowColor;
		self.titleLabel.shadowOffset = labelShadowOffset;
		self.titleLabel.backgroundColor = [UIColor clearColor];
		
		CGRect albumTitleLabelRect = CGRectOffset(titleLabelRect, 0, height);
		self.albumTitleLabel = [[UILabel alloc] initWithFrame:albumTitleLabelRect];
		self.albumTitleLabel.font = labelFont;
		self.albumTitleLabel.textAlignment = UITextAlignmentCenter;
		self.albumTitleLabel.textColor = dimLabelColor;
		self.albumTitleLabel.shadowColor = labelShadowColor;
		self.albumTitleLabel.shadowOffset = labelShadowOffset;
		self.albumTitleLabel.backgroundColor = [UIColor clearColor];
		
		[self addSubview:self.artistLabel];
		[self addSubview:self.titleLabel];
		[self addSubview:self.albumTitleLabel];
		
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
}


- (void)dealloc {

}


@end
