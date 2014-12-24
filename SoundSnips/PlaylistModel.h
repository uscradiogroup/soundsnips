//
//  PlaylistModel.h
//  SoundSnips
//
//  Created by Sherwin Zadeh on 4/24/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PlaylistEntryModel;

@interface PlaylistModel : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * iconFileName;
@property (nonatomic, retain) NSNumber * order;

@property (nonatomic, retain) NSSet *playlistEntries;
@end

@interface PlaylistModel (CoreDataGeneratedAccessors)

- (void)addPlaylistEntriesObject:(PlaylistEntryModel *)value;
- (void)removePlaylistEntriesObject:(PlaylistEntryModel *)value;
- (void)addPlaylistEntries:(NSSet *)values;
- (void)removePlaylistEntries:(NSSet *)values;
@end
