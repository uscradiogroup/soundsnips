//
//  PlaylistViewController.h
//  SoundSnips
//
//  Created by Sherwin Zadeh on 2/28/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "PlaylistModel.h"
#import "BaseViewController.h"

@interface PlaylistViewController : BaseViewController

- (id)initWithPlaylistModel:(PlaylistModel*)playlistModel;
- (id)initWithComposer:(NSString*)composer;

@end
