 //
//  ScrubberControl.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 4/4/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import "ScrubberControl.h"

#define LEFT_CAP 0
#define VERT_MARGIN 7

@interface ScrubberControl () <UIGestureRecognizerDelegate>
{
	NSArray* _tickArray;
}

@property (strong) UIImage*			scrubberThumbImage;
//@property (strong) UISlider*		topSlider;
@property (strong) NSMutableArray*	tickViews;
//@property (strong) UISlider*		bottomSlider;
//@property (strong) UIProgressView*	bottomProgressView;
@property (assign) int				isScrubbing;

//@property (nonatomic, assign) float minimumValue;

@property (strong) UIImage* scrubberMinimumImage;
@property (strong) UIImage* scrubberMaximumImage;
@property (strong) UIImageView* scrubberMinimumImageView;
@property (strong) UIImageView* scrubberMaximumImageView;
@property (strong) UIImageView* scrubberThumbImageView;


@end


@implementation ScrubberControl

@dynamic tickArray;
@synthesize scrubberThumbImage = _scrubberThumbImage;
@synthesize tickViews = _tickViews;
//@synthesize topSlider = _topSlider;
//@synthesize bottomSlider = _bottomSlider;
@dynamic value;
@synthesize maximumValue = _maximumValue;
//@dynamic maximumValue;
@synthesize isScrubbing = _isScrubbing;

@synthesize scrubberMinimumImage = _scrubberMinimumImage;
@synthesize scrubberMaximumImage = _scrubberMaximumImage;
@synthesize scrubberMinimumImageView = _scrubberMinimumImageView;
@synthesize scrubberMaximumImageView = _scrubberMaximumImageView;
@synthesize scrubberThumbImageView = _scrubberThumbImageView;

//@dynamic tracking;

- (id)initWithFrame:(CGRect)frame
{
//	CGRect frame = CGRectMake(0, 0, 320, 70);
    self = [super initWithFrame:frame];
    if (self) {
		self.maximumValue = 1;
		self.backgroundColor = [UIColor clearColor];
		self.scrubberThumbImage	= [UIImage imageNamed:@"ScrubberThumb"];
		
		self.clipsToBounds = NO;
		
		self.scrubberMinimumImage	= [UIImage imageNamed:@"ScrubberTrackMinimum"];
		self.scrubberMaximumImage	= [UIImage imageNamed:@"ScrubberTrackMaximum"];
		
		self.scrubberMaximumImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, VERT_MARGIN, self.frame.size.width, self.frame.size.height - 2 * VERT_MARGIN)];
		self.scrubberMaximumImageView.image = self.scrubberMaximumImage;
		self.scrubberMaximumImageView.contentMode = UIViewContentModeScaleToFill;
		[self addSubview:self.scrubberMaximumImageView];
		
		self.scrubberMinimumImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, VERT_MARGIN, 0, self.frame.size.height - 2 * VERT_MARGIN)];
		self.scrubberMinimumImageView.image = self.scrubberMinimumImage;
		self.scrubberMinimumImageView.contentMode = UIViewContentModeScaleToFill;
		[self addSubview:self.scrubberMinimumImageView];
		
		UIImage* scrubberOutlineImage	= [[UIImage imageNamed:@"ScrubberOutline"] stretchableImageWithLeftCapWidth:3 topCapHeight:0.0];
		UIImageView* scrubberOutlineImageView = [[UIImageView alloc] initWithImage:scrubberOutlineImage];
		scrubberOutlineImageView.frame = CGRectMake(self.bounds.origin.x - 1, self.bounds.origin.y, self.bounds.size.width + 2, self.bounds.size.height);
		[self addSubview:scrubberOutlineImageView];
		
		self.scrubberThumbImageView = [[UIImageView alloc] initWithImage:self.scrubberThumbImage];
		self.scrubberThumbImageView.center = CGPointMake(0, self.bounds.size.height / 2);
		self.scrubberThumbImageView.userInteractionEnabled = YES;
		[self addSubview:self.scrubberThumbImageView];
		
		UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panScrubberThumb:)];
		[panGesture setMaximumNumberOfTouches:1];
		[panGesture setDelegate:self];
		[self.scrubberThumbImageView addGestureRecognizer:panGesture];

		
		
		
		//
		// Bottom Slider
		//
/*		
		CGRect sliderFrame = CGRectMake(0, 0, frame.size.width, self.scrubberThumbImage.size.height);

		self.bottomSlider = [[UISlider alloc] initWithFrame:sliderFrame];
		self.bottomSlider.backgroundColor = [UIColor clearColor];	
		[self.bottomSlider setThumbImage:transparentThumbImage forState:UIControlStateNormal];
		[self.bottomSlider setThumbImage:transparentThumbImage forState:UIControlStateDisabled];
		[self.bottomSlider setMinimumTrackImage:scrubberMinimumImage forState:UIControlStateNormal];
		[self.bottomSlider setMinimumTrackImage:scrubberMinimumImage forState:UIControlStateDisabled];
		[self.bottomSlider setMaximumTrackImage:scrubberMaximumImage forState:UIControlStateNormal];
		[self.bottomSlider setMaximumTrackImage:scrubberMaximumImage forState:UIControlStateDisabled];
		[self addSubview:self.bottomSlider];
*/
		
		//
		// Top Slider
		//
/*		
		self.topSlider = [[UISlider alloc] initWithFrame:sliderFrame];
		self.topSlider.continuous = YES;
		self.topSlider.backgroundColor = [UIColor clearColor];	
		[self.topSlider setThumbImage:self.scrubberThumbImage forState:UIControlStateNormal];
		[self.topSlider setThumbImage:self.scrubberThumbImage forState:UIControlStateHighlighted];
		[self.topSlider setThumbImage:self.scrubberThumbImage forState:UIControlStateSelected];
		[self.topSlider setMinimumTrackImage:transparentTrackImage forState:UIControlStateNormal];
		[self.topSlider setMaximumTrackImage:transparentTrackImage forState:UIControlStateNormal];
		[self.topSlider addTarget:self
						   action:@selector(sliderAction:)
				 forControlEvents:UIControlEventValueChanged];
		[self addSubview:self.topSlider];	
*/
    }
	
    return self;
}

-(void)setTickArray:(NSArray *)tickArray
{
	_tickArray = tickArray;
	
	// First remove all old ticks
	NSMutableArray* viewsToRemove = [NSMutableArray array];
	for (UIView* subview in self.subviews) {
		if (subview.tag == 72) {
			[viewsToRemove addObject:subview];
		}
	}
	for (UIView* view in viewsToRemove) {
		[view removeFromSuperview];
	}

	//
	// Add Ticks
	//
	
	for (NSNumber* tickNumber in self.tickArray) {
		float tickPercent = ([tickNumber floatValue] - 0) / (self.maximumValue - 0);
//		float tickPercent = ([tickNumber floatValue] - self.minimumValue) / (self.maximumValue - self.minimumValue);
//		CGRect rect = CGRectMake(INNER_MARGIN + tickPercent * self.bounds.size.width, VERT_MARGIN, 3, self.bounds.size.height - 2 * VERT_MARGIN);
		CGRect rect = CGRectMake(tickPercent * self.bounds.size.width, VERT_MARGIN, 3, self.bounds.size.height - 2 * VERT_MARGIN);
		UIView* tickView = [[UIView alloc] initWithFrame:rect];
		tickView.backgroundColor = [UIColor whiteColor];
		tickView.opaque = YES;
		tickView.tag = 72;
		[self insertSubview:tickView belowSubview:self.scrubberThumbImageView];
	}
}

-(NSArray*)tickArray
{
	return _tickArray;
}
	
-(void)updateTrackImagesToThumbHead
{
	CGRect newFrame = self.scrubberMinimumImageView.frame;
	newFrame.size.width = self.scrubberThumbImageView.center.x;
	self.scrubberMinimumImageView.frame = newFrame;	
}

-(void)setValue:(float)value
{	
//	self.topSlider.value = value;
	self.scrubberThumbImageView.center = CGPointMake(self.frame.size.width * value / self.maximumValue, self.scrubberThumbImageView.center.y);

	[self updateTrackImagesToThumbHead];
	
//	self.bottomSlider.value = value;
}

-(float)value
{
//	return self.topSlider.value;
	return self.scrubberThumbImageView.center.x / self.frame.size.width * self.maximumValue;
}
/*
-(void)setMinimumValue:(float)value
{
	self.topSlider.minimumValue = value;
	self.bottomSlider.minimumValue = value;
}

-(float)minimumValue
{
	return self.topSlider.minimumValue;
}
*/
/*
-(void)setMaximumValue:(float)value
{
	self.topSlider.maximumValue = value;
//	self.bottomSlider.maximumValue = value;
}

-(float)maximumValue
{
	return self.topSlider.maximumValue;
}
*/
-(BOOL)isTracking
{
//	return self.topSlider.tracking;
	// TODO
	return self.isScrubbing;
}

- (void)sliderAction:(id)sender
{
//	[self setNeedsDisplay];
//	self.bottomSlider.value = self.topSlider.value;
	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

-(CGPoint)locationOfScrubHead
{
	float tickPercent = self.value / self.maximumValue;
//	float tickPercent = (self.topSlider.value - self.topSlider.minimumValue) / (self.topSlider.maximumValue - self.topSlider.minimumValue);
	float locationOnMiddleOfTrack = tickPercent * self.bounds.size.width;
	float thumbMiddle = self.scrubberThumbImage.size.width / self.scrubberThumbImage.scale / 2.0;
	float location = self.frame.origin.x + locationOnMiddleOfTrack;
	NSLog(@"%f, %f, %f", locationOnMiddleOfTrack, thumbMiddle, location);
	return CGPointMake(location, CGRectGetMaxY(self.frame));
}

-(CGFloat)locationOfLastTickMark
{
	TickRange curTickRange = [self curTickRange];
	float tickPercent = curTickRange.start / self.maximumValue;
	float locationOnMiddleOfTrack = tickPercent * self.bounds.size.width;
	float location = self.frame.origin.x + locationOnMiddleOfTrack;
	
	return location;
}

- (TickRange)curTickRange
{
	TickRange tickRange = {0.0, 0.0};
	
	float position = self.value;
	
	// End condintion
	float lastTick = [[self.tickArray lastObject] floatValue];
	if (position > lastTick) {
		return (TickRange) {lastTick, self.maximumValue};
	}
	
	for (NSNumber* tick in self.tickArray) {
		tickRange.start = tickRange.end;
		tickRange.end = [tick floatValue];
		
		if (tickRange.end > position)
			break;
	}
	
	return tickRange;
}

// shift the piece's center by the pan amount
// reset the gesture recognizer's translation to {0, 0} after applying so the next callback is a delta from the current position
- (void)panScrubberThumb:(UIPanGestureRecognizer *)gestureRecognizer
{
    UIView *scrubberThumb = [gestureRecognizer view];
	
//    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
	
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) 
	{
		self.isScrubbing = YES;
		
        CGPoint translation = [gestureRecognizer translationInView:[scrubberThumb superview]];
		
//        [scrubberThumb setCenter:CGPointMake((scrubberThumb.center.x + translation.x), scrubberThumb.center.y)];
		float centerX = MAX(0, MIN(scrubberThumb.center.x + translation.x, self.bounds.size.width));
        [scrubberThumb setCenter:CGPointMake(centerX, scrubberThumb.center.y)];
        [gestureRecognizer setTranslation:CGPointZero inView:[scrubberThumb superview]];
		
		[self updateTrackImagesToThumbHead];
		[self sendActionsForControlEvents:UIControlEventValueChanged];
    }
	else 
	{
		self.isScrubbing = NO;
	}
}

@end
