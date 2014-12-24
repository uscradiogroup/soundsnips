//
//  ScrubberControl.h
//  SoundSnips
//
//  Created by Sherwin Zadeh on 4/4/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef struct 
{
	float start;
	float end;
} TickRange;


@interface ScrubberControl : UIControl

@property (nonatomic, strong) NSArray*	tickArray; // NSNumber array MUST BE SORTED

@property (nonatomic, readonly, getter = isTracking) BOOL	tracking;

@property (nonatomic, assign) float value;
@property (nonatomic, assign) float maximumValue;

//-(CGPoint)locationOfScrubHead;
-(CGFloat)locationOfLastTickMark;
-(TickRange)curTickRange;


@end
