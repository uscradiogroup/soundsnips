//
//  MusicPlayerViewController.h
//  SoundSnips
//
//  Created by Sherwin Zadeh on 3/13/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SongModel.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioStreamer.h"

@interface MusicPlayerViewController : UIViewController

@property (strong) AudioStreamer* audioStreamer;

+(MusicPlayerViewController*)sharedMusicPlayerViewController;

-(void)prepareWithPlaylistEntries:(NSArray*)playlistEntries selectedIndex:(int)selectedIndex;
-(void)prepareWithSongs:(NSArray*)songs selectedIndex:(int)selectedIndex;

@end
