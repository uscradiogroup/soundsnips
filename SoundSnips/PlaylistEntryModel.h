//
//  PlaylistEntryModel.h
//  SoundSnips
//
//  Created by Sherwin Zadeh on 4/19/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PlaylistModel, SongModel;

@interface PlaylistEntryModel : NSManagedObject

@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) SongModel *song;
@property (nonatomic, retain) PlaylistModel *playlist;

@end
