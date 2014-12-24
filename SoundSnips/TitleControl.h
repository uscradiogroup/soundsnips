//
//  TitleControl.h
//  SleepTunes
//
//  Created by Sherwin Zadeh on 7/13/09.
//  Copyright 2009 Artamata, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TitleControl : UIView 
{
	UILabel*	_artistLabel;
	UILabel*	_titleLabel;
	UILabel*	_albumTitleLabel;
}

@property (retain) UILabel*	artistLabel;
@property (retain) UILabel*	titleLabel;
@property (retain) UILabel*	albumTitleLabel;

@end
