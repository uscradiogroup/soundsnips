//
//  MusicPlayerViewController.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 3/13/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import "MusicPlayerViewController.h"
#import "TitleControl.h"
#import <MediaPlayer/MediaPlayer.h>
#import "AudioStreamer.h"
#import "ModelManager.h"
#include <stdlib.h>
#import "ScrubberControl.h"
#import "SnipModel.h"
#import "SnipCell.h"
#import "SnipArrowUpView.h"
#import "WebService.h"
#import "SoftPopup.h"
#import "GANTracker.h"

#define INITIAL_ARROW_LOCATION 22


typedef enum {RepeatModeNone, RepeatModeAll, RepeatModeOne} RepeatMode;

@interface MusicPlayerViewController () <UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, AVAudioSessionDelegate, AudioStreamerErrorHandler, UIAlertViewDelegate>

@property (strong) TitleControl*	titleControl;
@property (strong) UIButton*		addFavoriteButton;
@property (strong) UIScrollView*	albumArtScrollView;
@property (assign) int				previousPageIndex;
@property (strong) UIImageView*		controlBarView;
@property (strong) UIButton*		playPauseBtn;
@property (strong) UIButton*		rewBtn;
@property (strong) UIButton*		ffBtn;
@property (strong) UIImage*			playImg;
@property (strong) UIImage*			pauseImg;
@property (strong) UIButton*		repeatButton;
@property (strong) UIButton*		shuffleButton;
@property (strong) MPVolumeView*	volumeView;
@property (strong) ScrubberControl*	scrubber;
@property (strong) UILabel*			playbackPlayTimeLabel;
@property (strong) UILabel*			playbackDurationLabel;
@property (strong) UIView*			overlayContainer;
@property (strong) UITableView*		snipsTableView;
@property (strong) SnipArrowUpView* snipArrowUpView;

@property (strong) NSTimer*			progressUpdateTimer;	

@property (strong) NSArray*			songs;
@property (assign) int				songIndex;

@property (assign) Boolean			seeking;
@property (strong) NSTimer*			longHoldTimer;
@property (assign) RepeatMode		repeatMode;

@property (strong) NSMutableArray*	shuffleSongHistory;
@property (assign) Boolean			shuffle;

@property (strong) NSFetchedResultsController*	fetchedResultsController;

@property (assign) int				lastCuePoint;

-(void)initAudioStreamer;
-(void)prepareAlbumArt;

-(SongModel*)nowPlayingSongModel;
-(void)updateUI;
-(void)updateProgress:(NSTimer*)timer;
-(void)updateSnips;

-(int)shuffleNextIndex;
-(int)shufflePrevIndex;

- (NSString*) stringFromTimeInterval:(NSTimeInterval)timeInterval;

@end

@implementation MusicPlayerViewController

@synthesize audioStreamer = _audioStreamer;
@synthesize titleControl = _titleControl;
@synthesize addFavoriteButton = _addFavoriteButton;
@synthesize albumArtScrollView = _albumArtScrollView;
@synthesize previousPageIndex = _previousPageIndex;
@synthesize controlBarView = _controlBarView;
@synthesize playPauseBtn = _playPauseBtn;
@synthesize rewBtn = _rewBtn;
@synthesize ffBtn = _ffBtn;
@synthesize playImg = _playImg;
@synthesize pauseImg = _pauseImg;
@synthesize repeatButton = _repeatButton;
@synthesize shuffleButton = _shuffleButton;
@synthesize volumeView = _volumeView;
@synthesize progressUpdateTimer = _progressUpdateTimer;
@synthesize songs = _songs;
@synthesize songIndex = _songIndex;
@synthesize seeking = _seeking;
@synthesize longHoldTimer = _longHoldTimer;
@synthesize repeatMode = _repeatMode;
@synthesize shuffleSongHistory = _shuffleSongHistory;
@synthesize shuffle = _shuffle;
@synthesize playbackPlayTimeLabel = _playbackPlayTimeLabel;
@synthesize playbackDurationLabel = _playbackDurationLabel;
@synthesize scrubber = _scrubber;
@synthesize overlayContainer = _snipsContainer;
@synthesize snipsTableView = _snipsTableView;
@synthesize snipArrowUpView = _snipArrowUpView;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize lastCuePoint = _lastCuePoint;

static MusicPlayerViewController* s_sharedMusicPlayerViewController = nil;

+(MusicPlayerViewController*)sharedMusicPlayerViewController
{
	if (s_sharedMusicPlayerViewController == nil) {
		s_sharedMusicPlayerViewController = [[MusicPlayerViewController alloc] init];
	}
	
	return s_sharedMusicPlayerViewController;
}



-(id)init
{
    self = [super init];
    if (self) {
		self.hidesBottomBarWhenPushed = YES;
		
		self.songIndex = -1;
		
		//
		// Setup Session
		//
		
		[[AVAudioSession sharedInstance] setDelegate: self];
		[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
		UInt32 doSetProperty = 0;
		AudioSessionSetProperty (
								 kAudioSessionProperty_OverrideCategoryMixWithOthers,
								 sizeof (doSetProperty),
								 &doSetProperty
								 );
		NSError *activationError = nil;
		[[AVAudioSession sharedInstance] setActive: YES error: &activationError];		
		
		[self initAudioStreamer];
		
    }
    return self;
}

-(void)initAudioStreamer
{
	//
	// Setup Audio Streamer
	//
	
	self.audioStreamer = [[AudioStreamer alloc] init];
	self.audioStreamer.errorHandler = self;
	
	// Notification to handle end-of-song routine, e.g. repeat, next track
	[[NSNotificationCenter defaultCenter] addObserverForName:ASStatusChangedNotification
													  object:nil 
													   queue:nil
												  usingBlock:^(NSNotification *note) 
	 {
		 if ([self.audioStreamer state] == AS_STOPPED && self.audioStreamer.stopReason == AS_STOPPING_EOF) {
			 self.lastCuePoint = 0;
			 self.scrubber.tickArray = nil;
			 self.scrubber.value = 0;
			 
			 int nextIndex = self.songIndex;
			 
			 if (self.shuffle) {
				 if (self.repeatMode != RepeatModeOne)
					 nextIndex = [self shuffleNextIndex];
				 
			 }
			 else {
				 if (self.repeatMode == RepeatModeNone) {
					 nextIndex = self.songIndex + 1;
				 }
				 else if (self.repeatMode == RepeatModeAll) {
					 if (self.songIndex == [self.songs count] - 1) {
						 nextIndex = 0;
					 }
					 else {
						 nextIndex = self.songIndex + 1;
					 }
				 }					
			 }
			 
			 [self playTrack:nextIndex];																  
		 }
		 else if ([self.audioStreamer state] == AS_PLAYING) {
			 self.scrubber.maximumValue = self.audioStreamer.duration;			 
			 
			 if (self.scrubber.tickArray == nil) {
				 SongModel* song = [self nowPlayingSongModel];
				 NSSet* filteredSet = [song.snips filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"cuePoint >= 0"]];
				 NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"cuePoint" ascending:YES];
				 NSArray* sortedSnips = [filteredSet sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
				 NSArray* tickArray = [sortedSnips valueForKeyPath:@"cuePoint"];
				 self.scrubber.tickArray = tickArray;
				 
				 self.lastCuePoint = 0;
				 [self updateSnips];
			 }				 
		 }
		 
		 [self updateUI];
	 }];
	
}

-(void)prepareWithPlaylistEntries:(NSArray*)playlistEntries selectedIndex:(int)selectedIndex
{
	NSArray* songs = [playlistEntries valueForKeyPath:@"song"];
	[self prepareWithSongs:songs selectedIndex:selectedIndex];
}

-(void)prepareWithSongs:(NSArray*)songs selectedIndex:(int)selectedIndex
{	

	// Make sure it's not the same list
	if (self.songs != nil && [self.songs count] == [songs count]) {
		BOOL same = YES;
		int i = 0;
		for (SongModel* song in self.songs) {
			if ([song isEqual:[songs objectAtIndex:i]] == NO) {
				same = NO;
				break;
			}
			i++;
		}

		if (same) {
			[self playTrack:selectedIndex];
			[self prepareAlbumArt];
			return;
		}
	}		

	self.songs = songs;
	self.songIndex = selectedIndex;		
	
	self.shuffleSongHistory = [NSMutableArray arrayWithCapacity:[self.songs count]];
	
	[self.audioStreamer stop];

	[self prepareAlbumArt];

	[self updateUI];
}

-(void)prepareAlbumArt
{
	if (self.albumArtScrollView != nil) {
		[self.albumArtScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
		
		float scrollViewWidth = self.albumArtScrollView.frame.size.width;
		int imageIndex = 0;
		for (SongModel* song in self.songs) {
			float offset = imageIndex * scrollViewWidth;
			UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(offset, 0, scrollViewWidth, scrollViewWidth)];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:song.albumArtFileName]) {
				imageView.image = [UIImage imageWithContentsOfFile:song.albumArtFileName];
			}
			else {
				imageView.image = [UIImage imageNamed:@"NoArtwork"];

				if (imageIndex == self.songIndex) {
					WebService* webService = [[WebService alloc] init];
					[webService beginRequestWithURL:[NSURL URLWithString:song.albumArtURL]
										   finished:^(NSData* responseData) 
					 {
						 if (responseData != nil) {
							 if ([responseData writeToFile:song.albumArtFileName atomically:YES] == NO) {
								 NSLog(@"Could not write to %@", song.albumArtFileName);
							 }
							 else {
								 imageView.image = [UIImage imageWithContentsOfFile:song.albumArtFileName]; 
							 }
						 }			
					 }];
				}

			}
			
			imageView.tag = imageIndex++;
			
			[self.albumArtScrollView addSubview:imageView];
		}
	}
	
}

-(void)inspectViewAndSubViews:(UIView*) v level:(int)level {
	
	NSMutableString* str = [NSMutableString string];
	
	for (int i = 0; i < level; i++) {
		[str appendString:@"   "];
	}
	
	[str appendFormat:@"%@", [v class]];
	
	if ([v isKindOfClass:[UITableView class]]) {
		[str appendString:@" : UITableView "];
	}
	
	if ([v isKindOfClass:[UIScrollView class]]) {
		[str appendString:@" : UIScrollView "];
		
		UIScrollView* scrollView = (UIScrollView*)v;
		if (scrollView.scrollsToTop) {
			[str appendString:@" >>>scrollsToTop<<<<"];
		}
	}
	
	NSLog(@"%@", str);
	
	for (UIView* sv in [v subviews]) {
		[self inspectViewAndSubViews:sv level:level+1];
	}
}

-(void)loadView
{
	[super loadView];
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"PlaylistBackground"]];

	// Back Button
	UIImage* backImage = [UIImage imageNamed:@"BackButton"];
	UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
	backButton.frame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
	[backButton setImage:backImage forState:UIControlStateNormal];
	[backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
	
	UIBarButtonItem* backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton]; 
	self.navigationItem.leftBarButtonItem = backBarButtonItem; 	
	
	// Title
	self.titleControl = [[TitleControl alloc] initWithFrame:CGRectMake(0, 4, 200, 40)];
	self.navigationItem.titleView = self.titleControl;

	
	// Add Favorite Button
	UIImage* addFavoriteImage = [UIImage imageNamed:@"AddFavoriteButton"];
	UIImage* removeFavoriteImage = [UIImage imageNamed:@"RemoveFavoriteButton"];
	self.addFavoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
	self.addFavoriteButton.frame = CGRectMake(0, 0, addFavoriteImage.size.width, addFavoriteImage.size.height);
	[self.addFavoriteButton setImage:addFavoriteImage forState:UIControlStateNormal];
	[self.addFavoriteButton setImage:removeFavoriteImage forState:UIControlStateDisabled];
	[self.addFavoriteButton addTarget:self action:@selector(addFavoriteButtonAction) forControlEvents:UIControlEventTouchUpInside];
	
	UIBarButtonItem* addFavoriteBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.addFavoriteButton]; 
	self.navigationItem.rightBarButtonItem = addFavoriteBarButtonItem; 	

	// Album Art
	self.albumArtScrollView	= [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
	self.albumArtScrollView.pagingEnabled = YES;
	self.albumArtScrollView.contentSize = CGSizeMake(320 * [self.songs count], 320);
	self.albumArtScrollView.backgroundColor = [UIColor clearColor];
	self.albumArtScrollView.opaque = NO;
	self.albumArtScrollView.userInteractionEnabled = YES;
	self.albumArtScrollView.clipsToBounds = NO;
	self.albumArtScrollView.delegate = self;
	[self.albumArtScrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showSnipsUI:)]];
	[self.view addSubview:self.albumArtScrollView];

	[self prepareAlbumArt];

	//
	// Overlay Container
	//
	
	self.overlayContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
	self.overlayContainer.backgroundColor = [UIColor colorWithWhite:0 alpha:.5];
	self.overlayContainer.opaque = NO;

	[self.view addSubview:self.overlayContainer];
	
	
	//
	// Playtime label
	//
	
	UIFont* playbackFont = [UIFont boldSystemFontOfSize:11.0];
	UIColor* labelShadowColor = [UIColor blackColor];
	CGSize labelShadowOffset = CGSizeMake(0, -1.0f);
	
	CGRect playbackPlaytimeRect = CGRectMake(14, 2, 45, 16);
	self.playbackPlayTimeLabel = [[UILabel alloc] initWithFrame:playbackPlaytimeRect];
	self.playbackPlayTimeLabel.font = playbackFont;
	self.playbackPlayTimeLabel.textAlignment = UITextAlignmentCenter;
	self.playbackPlayTimeLabel.textColor = [UIColor whiteColor];
	self.playbackPlayTimeLabel.shadowColor = labelShadowColor;
	self.playbackPlayTimeLabel.shadowOffset = labelShadowOffset;
	self.playbackPlayTimeLabel.backgroundColor = [UIColor clearColor];
	[self.playbackPlayTimeLabel setText:@"0:00"];
	[self.overlayContainer addSubview:self.playbackPlayTimeLabel];
	
	CGRect playbackDurationRect = CGRectMake(256, 2, 45, 16);
	self.playbackDurationLabel = [[UILabel alloc] initWithFrame:playbackDurationRect];
	self.playbackDurationLabel.font = playbackFont;
	self.playbackDurationLabel.textAlignment = UITextAlignmentCenter;
	self.playbackDurationLabel.textColor = [UIColor whiteColor];
	self.playbackDurationLabel.shadowColor = labelShadowColor;
	self.playbackDurationLabel.shadowOffset = labelShadowOffset;
	self.playbackDurationLabel.backgroundColor = [UIColor clearColor];
	[self.playbackDurationLabel setText:@"0:00"];		
	[self.overlayContainer addSubview:self.playbackDurationLabel];
	
	//
	// Scrubber Slider
	//
	
	self.scrubber = [[ScrubberControl alloc] initWithFrame:CGRectMake(20, 15, 280, 42)];
	self.scrubber.value = 0.0f;
//	self.scrubber.minimumValue = 0.0f;
	self.scrubber.maximumValue = 0.0f;
	[self.scrubber addTarget:self
					  action:@selector(scrubberAction:)
			forControlEvents:UIControlEventValueChanged];
	[self.overlayContainer addSubview:self.scrubber];

	//
	// Snips Table
	//
	
	// Arrow up
	float arrowHeight = 10;
	self.snipArrowUpView = [[SnipArrowUpView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.scrubber.frame) + 2, 320, arrowHeight)];
	self.snipArrowUpView.arrowLocation = INITIAL_ARROW_LOCATION;
	[self.overlayContainer addSubview:self.snipArrowUpView];
	
	// Snips background
	UIImage* snipsBackgroundTile = [UIImage imageNamed:@"SnipsBackgroundTile"];
	UIImage* snipsBackgroundImage = [snipsBackgroundTile stretchableImageWithLeftCapWidth:21 topCapHeight:0];
	UIImageView* snipsBackgroundView = [[UIImageView alloc] initWithImage:snipsBackgroundImage];
	snipsBackgroundView.frame = CGRectMake(0, CGRectGetMaxY(self.snipArrowUpView.frame) - 1, 320, snipsBackgroundImage.size.height);
	[self.overlayContainer addSubview:snipsBackgroundView];
	
	CGRect snipsTableFrame = snipsBackgroundView.frame;
	snipsTableFrame.size.height = 479/2.0;//193;
	self.snipsTableView = [[UITableView alloc] initWithFrame:snipsTableFrame style:UITableViewStylePlain];
	self.snipsTableView.delegate = self;
	self.snipsTableView.dataSource = self;
	self.snipsTableView.backgroundColor = [UIColor clearColor];
	self.snipsTableView.opaque = NO;
	self.snipsTableView.separatorStyle = UITableViewCellSeparatorStyleNone; // separaters are built into the cells
	self.snipsTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 10);
	self.snipsTableView.contentInset = UIEdgeInsetsMake(-18, 0, 0, 0);
	self.snipsTableView.showsHorizontalScrollIndicator = YES;
	[self.snipsTableView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideSnipsUI:)]];		
	[self.overlayContainer addSubview:self.snipsTableView];
	

	//
	// Control Bar
	//
	CGRect rootRect = CGRectMake(0, 0, 320, 480 - 20 - 44);
	
	UIImage* controlBarBkImage = [UIImage imageNamed:@"ControlBarBackground"];
	self.controlBarView = [[UIImageView alloc] initWithImage:controlBarBkImage];
	self.controlBarView.frame = CGRectMake(0, rootRect.size.height - controlBarBkImage.size.height, controlBarBkImage.size.width, controlBarBkImage.size.height);
	self.controlBarView.userInteractionEnabled = YES;
	[self.view addSubview:self.controlBarView];

	UIImage* rewImage	= [UIImage imageNamed:@"REW_Btn"];
	UIImage* ffImage	= [UIImage imageNamed:@"FF_Btn"];
	self.playImg		= [UIImage imageNamed:@"Play_Btn"];
	self.pauseImg		= [UIImage imageNamed:@"Pause_Btn"];
	
	const int REW_BTN_WIDTH = 50;
	const int REW_BTN_HEIGHT = 50;
	const int FF_BTN_WIDTH = 50;
	const int FF_BTN_HEIGHT = 50;
	const int PLAY_PAUSE_BTN_WIDTH = 50;
	const int PLAY_PAUSE_BTN_HEIGHT = 50;
	
	self.repeatButton = [UIButton buttonWithType:UIButtonTypeCustom];
	self.repeatButton.frame = CGRectMake(0, 0, 50, 50);
	self.repeatButton.center = CGPointMake(40, 25);
	self.repeatButton.userInteractionEnabled = YES;
	self.repeatButton.showsTouchWhenHighlighted = YES;
	[self.repeatButton setImage:[UIImage imageNamed:@"Repeat_off"] forState:UIControlStateNormal];
	[self.repeatButton setImage:[UIImage imageNamed:@"Repeat_on"] forState:UIControlStateSelected];	
	[self.controlBarView addSubview:self.repeatButton];
	[self.repeatButton addTarget:self
					action:@selector(repeatButtonAction)
		  forControlEvents:UIControlEventTouchDown];
	
	
	self.shuffleButton = [UIButton buttonWithType:UIButtonTypeCustom];
	self.shuffleButton.frame = CGRectMake(0, 0, 50, 50);
	self.shuffleButton.center = CGPointMake(284, 25);
	self.shuffleButton.userInteractionEnabled = YES;
	self.shuffleButton.showsTouchWhenHighlighted = YES;
	[self.shuffleButton setImage:[UIImage imageNamed:@"Shuffle_off"] forState:UIControlStateNormal];
	[self.shuffleButton setImage:[UIImage imageNamed:@"Shuffle_on"] forState:UIControlStateSelected];	
	[self.controlBarView addSubview:self.shuffleButton];
	[self.shuffleButton addTarget:self
						   action:@selector(shuffleButtonAction)
				 forControlEvents:UIControlEventTouchDown];
	
	
	
	
	
	self.rewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.rewBtn setImage:rewImage forState:UIControlStateNormal];
	self.rewBtn.frame = CGRectMake(0, 0, REW_BTN_WIDTH, REW_BTN_HEIGHT);
	self.rewBtn.center = CGPointMake(104, 25);
	self.rewBtn.userInteractionEnabled = YES;
	self.rewBtn.showsTouchWhenHighlighted = YES;
	[self.controlBarView addSubview:self.rewBtn];
	[self.rewBtn addTarget:self
					action:@selector(rewBtnDownAction:)
		  forControlEvents:UIControlEventTouchDown];
	[self.rewBtn addTarget:self 
					action:@selector(rewBtnUpAction:)
		  forControlEvents:UIControlEventTouchUpInside];	
	
	self.playPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	self.playPauseBtn.frame = CGRectMake(0, 0, PLAY_PAUSE_BTN_WIDTH, PLAY_PAUSE_BTN_HEIGHT);
	self.playPauseBtn.center = CGPointMake(160, 25);
	self.playPauseBtn.userInteractionEnabled = YES;
	self.playPauseBtn.showsTouchWhenHighlighted = YES;
	[self.controlBarView addSubview:self.playPauseBtn];
	[self.playPauseBtn addTarget:self 
						  action:@selector(pausePlayBtnAction:)
				forControlEvents:UIControlEventTouchUpInside];		
	
	
	self.ffBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.ffBtn setImage:ffImage forState:UIControlStateNormal];
	self.ffBtn.frame = CGRectMake(0, 0, FF_BTN_WIDTH, FF_BTN_HEIGHT);	
	self.ffBtn.center = CGPointMake(215, 25);
	self.ffBtn.userInteractionEnabled = YES;
	self.ffBtn.showsTouchWhenHighlighted = YES;
	[self.controlBarView addSubview:self.ffBtn];	
	[self.ffBtn addTarget:self
				   action:@selector(ffBtnDownAction:) 
		 forControlEvents:UIControlEventTouchDown];
	[self.ffBtn addTarget:self 
				   action:@selector(ffBtnUpAction:)
		 forControlEvents:UIControlEventTouchUpInside];
	
	// Volume slider
	UIImage* sliderThumbImg = [UIImage imageNamed:@"SliderThumb"];
	CGRect sliderFrame = CGRectMake(20, 60, 280, sliderThumbImg.size.height);
	
	self.volumeView = [[MPVolumeView alloc] initWithFrame:sliderFrame];
	self.volumeView.showsVolumeSlider = YES;
	self.volumeView.showsRouteButton = YES;
	[self.volumeView sizeToFit];
	[self.controlBarView addSubview:self.volumeView];
	
	
	[self.controlBarView addSubview:self.playPauseBtn];
		
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

-(void)viewWillAppear:(BOOL)animated
{
	if (self.audioStreamer == nil) {
		[self initAudioStreamer];
	}
	
	
	if (self.songIndex >= 0) {
		if (!self.audioStreamer.isPlaying) {		
			[self playTrack:self.songIndex];
		}
	}	
	[self updateUI];	
	
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
		
	[[UIApplication sharedApplication] setIdleTimerDisabled:(self.overlayContainer.alpha == 1)];
	
	NSError* error = nil;
	if (![[GANTracker sharedTracker] trackPageview:@"/music_player"
										 withError:&error]) {
		NSLog(@"error in trackPageview");
	}
	
}


-(void)viewWillDisappear:(BOOL)animated
{
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];		
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
	
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];		
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

-(void)backButtonAction
{
	[self.navigationController popViewControllerAnimated:YES];
}

-(void)addFavoriteButtonAction
{
	if ([self nowPlayingSongModel] != nil) {
		ModelManager* modelManager = [ModelManager sharedModelManager];
		[modelManager addSongToFavorites:[self nowPlayingSongModel]];
		[self updateUI];
		[[SoftPopup sharedSoftPopup] show:[UIImage imageNamed:@"WhiteHeart"]
									 text:@"Favorite"];
	}
}

-(void)showSnipsUI:(UITapGestureRecognizer*)gestureRecognizer
{
	[UIView animateWithDuration:0.25 animations:^{
		self.overlayContainer.alpha = 1.0;
		self.albumArtScrollView.alpha = 0.15;
	}];
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];	
}

-(void)hideSnipsUI:(UITapGestureRecognizer*)gestureRecognizer
{
	[UIView animateWithDuration:0.25 animations:^{
		self.overlayContainer.alpha = 0;
		self.albumArtScrollView.alpha = 1;
	}];
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

-(void)ffBtnDownAction
{
}

- (void) updateUI
{
	SongModel* song = [self nowPlayingSongModel];
	
	self.titleControl.artistLabel.text = song.composerFullName;
	self.titleControl.titleLabel.text = song.title;
	self.titleControl.albumTitleLabel.text = song.performer; // should be album?	

	int pageNum = self.songIndex;
	CGRect rect = CGRectMake(self.albumArtScrollView.bounds.size.width * pageNum, 0, self.albumArtScrollView.bounds.size.width, self.albumArtScrollView.bounds.size.height);
	[self.albumArtScrollView scrollRectToVisible:rect animated:NO];
	
	[self.playPauseBtn setImage:((self.audioStreamer.isPlaying || [self.audioStreamer isWaiting]) ? self.pauseImg : self.playImg) forState:UIControlStateNormal];
	
	ModelManager* modelManager = [ModelManager sharedModelManager];
	NSSet* favoriteItem = [modelManager.favoritesPlaylist.playlistEntries filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"self.song.title == %@", song.title]];
	self.addFavoriteButton.enabled = !(favoriteItem != nil && [favoriteItem count] > 0);
//	self.addFavoriteButton.enabled = !self.addFavoriteButton.selected;
}

- (void)updateProgress:(NSTimer *)timer
{
	double progress = self.audioStreamer.progress;
	
	TickRange tickRange = [self.scrubber curTickRange];
	float curCuePointWePassed = tickRange.start;
	
	if (curCuePointWePassed != self.lastCuePoint) {

		self.lastCuePoint = curCuePointWePassed;
		[self updateSnips];
		

		self.snipArrowUpView.arrowLocation = [self.scrubber locationOfLastTickMark];
	}

	
	if (self.scrubber.tracking || [self.audioStreamer isWaiting])
		return;
	
	if (self.audioStreamer.bitRate != 0.0)
	{
		double duration = self.audioStreamer.duration;
				
		if (duration > 0)
		{
			[self.scrubber setEnabled:YES];
			[self.scrubber setValue:progress];
			
			self.playbackPlayTimeLabel.text = [self stringFromTimeInterval:progress];
			self.playbackDurationLabel.text = [@"-" stringByAppendingString:[self stringFromTimeInterval:(duration - progress)]];			
		}
		else
		{
			[self.scrubber setEnabled:NO];
		}
	}

}

-(void) updateSnips
{
	SongModel* songModel = [self nowPlayingSongModel];
	
	TickRange curTickRange = [self.scrubber curTickRange];
	
	ModelManager* modelManager = [ModelManager sharedModelManager];
	
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	fetchRequest.entity = [NSEntityDescription entityForName:@"SnipModel"
									  inManagedObjectContext:modelManager.managedObjectContext];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"self in %@ && cuePoint >= %f && cuePoint < %f", songModel.snips, curTickRange.start, curTickRange.end];
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"cuePoint" 
																						   ascending:YES], nil];		
		
	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																		managedObjectContext:modelManager.managedObjectContext
																		  sectionNameKeyPath:nil//cuePoint"
																				   cacheName:nil];
	
	NSError* error = nil;
	[self.fetchedResultsController performFetch:&error];
	[self.snipsTableView reloadData];
}

- (void) playTrack:(int)track
{	
	// Safer to make sure it's stopped
	[self.audioStreamer stop];
	
	if (track == -1 || track >= [self.songs count]) {
		[self.navigationController popViewControllerAnimated:YES];
		return;
	}
	
	self.songIndex = track;
	
	SongModel* songModel = [self nowPlayingSongModel];
		
	if (self.shuffle && ![[self.shuffleSongHistory lastObject] isEqual:songModel]) {
		[self.shuffleSongHistory addObject:songModel];
	}
	
	self.audioStreamer = [[AudioStreamer alloc] init];
	self.audioStreamer.errorHandler = self;
	[self.audioStreamer prepareWithURL:[NSURL URLWithString:songModel.audioSource]];
	[self.audioStreamer start];
	
	if (self.progressUpdateTimer == nil) {
		self.progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
																	target:self
																  selector:@selector(updateProgress:)
																  userInfo:nil
																   repeats:YES];
		
	}
	
	self.scrubber.tickArray = nil;
	self.snipArrowUpView.arrowLocation = INITIAL_ARROW_LOCATION;	
	[self.snipsTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
	
	// Download Album Art if necessary
	for (UIImageView* imageView in self.albumArtScrollView.subviews) {
		if (imageView.tag == self.songIndex) {
			SongModel* song = [self nowPlayingSongModel];
			if ([[NSFileManager defaultManager] fileExistsAtPath:song.albumArtFileName] == NO) {
				__block UIImageView* imageViewToUpdate = imageView;
				WebService* webService = [[WebService alloc] init];
				[webService beginRequestWithURL:[NSURL URLWithString:song.albumArtURL]
									   finished:^(NSData* responseData) 
				 {
					 if (responseData != nil) {
						 if ([responseData writeToFile:song.albumArtFileName atomically:YES] == NO) {
							 NSLog(@"Could not write to %@", song.albumArtFileName);
						 }
						 else {
							 UIImage* image = [UIImage imageWithContentsOfFile:song.albumArtFileName];
							 imageViewToUpdate.image = image;
						 }
					 }			
				 }];				
			}
			
			break;
		}
	}	
}

- (void) pausePlayBtnAction: (id) sender
{
	if ([self.audioStreamer isPlaying]) {
		[self.audioStreamer pause];
	}
	else {
		[self.audioStreamer start];
	}

	[self updateUI];	
}

- (void) rewBtnDownAction: (id) sender
{	
//	self.seeking = NO;
//	self.longHoldTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
//														  target:self
//														selector:@selector(rewBtnLongHoldAction:)
//														userInfo:nil
//														 repeats:NO];
}

- (void) rewBtnLongHoldAction: (id) sender
{
//	self.seeking = YES;
//	PlaylistModel* playlistModel = [PlaylistModel sharedPlaylistModel];
//	[playlistModel.musicPlayer beginSeekingBackward];
}

- (void) rewBtnUpAction: (id) sender
{
	if (self.audioStreamer.progress < 3) {
		if (self.shuffle) {
			[self playTrack:[self shufflePrevIndex]];
		}
		else {
			[self playTrack:self.songIndex - 1];
		}
	}
	else {
		[self.audioStreamer seekToTime:0]; // back to beginning of same track
	}
	
	[self updateUI];
	
	
//	[self.longHoldTimer invalidate];
//	self.longHoldTimer = nil;
//	
//	PlaylistModel* playlistModel = [PlaylistModel sharedPlaylistModel];
//	
//	// Seeking
//	if (self.seeking == YES)
//	{
//		[playlistModel.musicPlayer endSeeking];
//		self.seeking = NO;
//	}
//	// Skipping
//	else 
//	{		
//		if (playlistModel.musicPlayer.currentPlaybackTime > 3)
//		{
//			[playlistModel.musicPlayer skipToBeginning];
//		}
//		else 
//		{
//			MPMediaItem* firstItem = [playlistModel.collection.items objectAtIndex:0];
//			NSNumber* firstItemId = [firstItem valueForProperty:MPMediaItemPropertyPersistentID];
//			NSNumber* nowPlayingItemId = [playlistModel.musicPlayer.nowPlayingItem valueForProperty:MPMediaItemPropertyPersistentID];
//			
//			if ([nowPlayingItemId compare:firstItemId] == NSOrderedSame)		 
//				[playlistModel.musicPlayer skipToBeginning];
//			else
//			{
//				[playlistModel.musicPlayer skipToPreviousItem];
//				[self trackChanged];
//			}
//		}
//	}
}

- (void) ffBtnDownAction: (id) sender
{
//	self.seeking = NO;
//	self.longHoldTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
//														  target:self
//														selector:@selector(ffBtnLongHoldAction:)
//														userInfo:nil
//														 repeats:NO];
}

- (void) ffBtnLongHoldAction: (id) sender
{
//	self.seeking = YES;	
//	PlaylistModel* playlistModel = [PlaylistModel sharedPlaylistModel];
//	[playlistModel.musicPlayer beginSeekingForward];
}

- (void) ffBtnUpAction: (id) sender
{
	if (self.shuffle) {
		[self playTrack:[self shuffleNextIndex]];
	}
	else {
		[self playTrack:self.songIndex + 1];
	}
	[self updateUI];
	
//	[self.longHoldTimer invalidate];
//	self.longHoldTimer = nil;
//	
//	PlaylistModel* playlistModel = [PlaylistModel sharedPlaylistModel];
//	
//	if (self.seeking == YES)
//	{
//		[playlistModel.musicPlayer endSeeking];
//		self.seeking = NO;
//	}
//	else 
//	{
//		[playlistModel.musicPlayer skipToNextItem];
//		[self trackChanged];		
//	}	
}

-(void)repeatButtonAction
{
	if (self.repeatMode == RepeatModeNone)
	{
		self.repeatMode = RepeatModeAll;
		self.repeatButton.selected = YES;
		[self.repeatButton setImage:[UIImage imageNamed:@"Repeat_on"] forState:UIControlStateSelected];
	}
	else if (self.repeatMode == RepeatModeAll)
	{
		self.repeatMode = RepeatModeOne;
		self.repeatButton.selected = YES;
		[self.repeatButton setImage:[UIImage imageNamed:@"Repeat_on_1"] forState:UIControlStateSelected];
	}
	else if (self.repeatMode == RepeatModeOne)
	{
		self.repeatMode = RepeatModeNone;
		self.repeatButton.selected = NO;
	}
	
}

-(void)shuffleButtonAction
{
	if (self.shuffle) {
		self.shuffle = NO;
		self.shuffleButton.selected = NO;
		
		[self.shuffleSongHistory removeAllObjects];
	}
	else {
		self.shuffle = YES;
		self.shuffleButton.selected = YES;
		
		[self.shuffleSongHistory addObject:[self nowPlayingSongModel]];
	}	
	
	[self updateUI];
}

-(SongModel*)nowPlayingSongModel
{
	return [self.songs objectAtIndex:self.songIndex];
}

-(int)shuffleNextIndex
{
	if ([self.shuffleSongHistory count] == [self.songs count] || [self.songs count] == 1)	
		return -1;
	
	int nextIndex;// = self.songIndex;
	
	SongModel* nextSong = nil;
	do {
		nextIndex = abs(arc4random()) % ([self.songs count]);
		assert(nextIndex < [self.songs count]);
		nextSong = [self.songs objectAtIndex:nextIndex];
		
	} while ([self.shuffleSongHistory containsObject:nextSong]);
	
	return nextIndex;
	
}

-(int)shufflePrevIndex
{
	SongModel* s1 = [self.shuffleSongHistory lastObject];
	NSLog(@"Popping off %@", s1.title);
	
	[self.shuffleSongHistory removeLastObject];
	
	if ([self.shuffleSongHistory count] == 0)
		return -1;
	
	SongModel* lastSong = [self.shuffleSongHistory lastObject];
	
	NSLog(@"Last song is %@ and it's track is %@", lastSong.title, lastSong.track);
	
	int prevIndex = [self.songs indexOfObject:lastSong];
	
	NSLog(@"It's index, though, is: %d", prevIndex);
	
	return prevIndex;
}

- (void)scrubberAction:(id)sender
{
//	AudioStreamer* audioStreamer = [AudioStreamer sharedAudioStreamer];
	double duration = self.audioStreamer.duration;

	NSTimeInterval newTime = self.scrubber.value;

	if ([self.audioStreamer isPaused]) {
		[self.audioStreamer start];
	}
	
	[self.audioStreamer seekToTime:newTime];

	self.playbackPlayTimeLabel.text = [self stringFromTimeInterval:newTime];
	self.playbackDurationLabel.text = [@"-" stringByAppendingString:[self stringFromTimeInterval:(duration - newTime)]];
}

#pragma mark Helper functions

- (NSString*) stringFromTimeInterval:(NSTimeInterval)timeInterval
{
	//	NSNumber*		durationNum	= (NSNumber*) [item valueForProperty:MPMediaItemPropertyPlaybackDuration];
	//	NSTimeInterval	duration	= [durationNum doubleValue];
	
	int hours	= (int) ((int)timeInterval / 3600);
	int minutes	= (int) ((int)(timeInterval - hours * 3600) / 60);
	//	int minutes = (int) ((int)timeInterval / 60);
	int seconds = (int) (timeInterval - hours * 3600 - minutes * 60);
	
	NSString* timeString = @"";
	
	if (hours > 0)
		timeString = [timeString stringByAppendingFormat:@"%d:", hours];
	
	if (minutes >= 10)
		timeString = [timeString stringByAppendingFormat:@"%d:", minutes];
	else
		timeString = [timeString stringByAppendingFormat:@"0%d:", minutes];
	
	
	if (seconds >= 10) 
		timeString = [timeString stringByAppendingFormat:@"%2d", seconds];
	else
		timeString = [timeString stringByAppendingFormat:@"0%d", seconds];
	
	return timeString;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[self.fetchedResultsController sections] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	SnipModel* snipModel = [self.fetchedResultsController objectAtIndexPath:indexPath];	
	return [SnipCell heightForText:snipModel.text];
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{   
    SnipCell *cell = (SnipCell*) [tableView dequeueReusableCellWithIdentifier:[SnipCell reuseIdentifier]];
    if (cell == nil) {
		cell = [[SnipCell alloc] init];
    }
    
    // Configure the cell...
	
	SnipModel* snipModel = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.snipLabel.text = [NSString stringWithFormat:@"\r%@", snipModel.text];
	[cell setNeedsLayout];
	
	cell.shouldDrawBottomSeparator = (indexPath.row < [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1);
	
    return cell;
}

#pragma mark UIScrollViewDelegate

-(int)currentPageIndex {
	int pageIndex = (int)(self.albumArtScrollView.contentOffset.x / self.albumArtScrollView.bounds.size.width + 0.5);
	return pageIndex;
}
/*		
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (scrollView == self.albumArtScrollView) {

		int pageScrolledTo = self.currentPageIndex;
		NSLog(@"scrollViewDidScroll, pageScrolledTo=%i", pageScrolledTo);		

		if (self.lastScrollPosition > scrollView.contentOffset.x) {
			[self rewBtnUpAction:nil];
//			scrollDirection = RIGHT;
		}
		else if (self.lastScrollPosition < scrollView.contentOffset.x) {
			[self ffBtnUpAction:nil];
//			scrollDirection = LEFT;
		}
		
		self.lastScrollPosition = scrollView.contentOffset.x;

	}
}
*/
//-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
//	if (scrollView == self) {
//		[self.photoFeedDetailScrollViewDelegate photoFeedDetailScrollViewDidScroll:self];
//	}
//}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if (scrollView == self.albumArtScrollView) {
		self.previousPageIndex = self.currentPageIndex;
		NSLog(@"scrollViewWillBeginDragging, setting prevPageIdx=%i", self.previousPageIndex);
	}
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate) {
		[self handleScrollEnded:scrollView];
	}
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView 
{
	[self handleScrollEnded:scrollView];
}

-(void)handleScrollEnded:(UIScrollView*)scrollView
{
	if (scrollView == self.albumArtScrollView) {	
		int pageScrolledTo = self.currentPageIndex;
		NSLog(@"scrollViewDidEndDecelerating, pageScrolledTo=%i", pageScrolledTo);
		
		if (pageScrolledTo > self.previousPageIndex) {
			[self playTrack:self.songIndex + 1];
		}
		else if (pageScrolledTo < self.previousPageIndex) {
			[self playTrack:self.songIndex - 1];
		}
		else {
			return; // Same page
		}
	}		
}

- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent 
{	
    if (receivedEvent.type == UIEventTypeRemoteControl) {		
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self pausePlayBtnAction:nil];
                break;
				
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self rewBtnUpAction:nil];
                break;
				
            case UIEventSubtypeRemoteControlNextTrack:
                [self ffBtnUpAction:nil];
                break;
				
            default:
                break;
        }
    }
}

- (BOOL)canBecomeFirstResponder 
{
    return YES;
}

-(void)audioStreamerEncounteredError:(AudioStreamer *)audioStreamer
{
	[[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"No Connection", @"Errors", nil)
							   message:NSLocalizedStringFromTable(@"Unable to read stream. Please check your network connection.", @"Errors", nil)
							   delegate:self
					 cancelButtonTitle:@"Cancel"
					  otherButtonTitles:@"Retry", nil] show];

	
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Retry"]) {
		self.audioStreamer = [[AudioStreamer alloc] init];
		self.audioStreamer.errorHandler = self;
		
		SongModel* songModel = [self nowPlayingSongModel];
		[self.audioStreamer prepareWithURL:[NSURL URLWithString:songModel.audioSource]];

		[self playTrack:[self songIndex]];
	}
	else {
		self.audioStreamer = nil;
		[self.navigationController popViewControllerAnimated:YES];
	}
}

@end
