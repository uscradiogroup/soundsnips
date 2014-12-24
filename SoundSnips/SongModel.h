//
//  SongModel.h
//  SoundSnips
//
//  Created by Sherwin Zadeh on 5/4/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PlaylistEntryModel, SnipModel;

@interface SongModel : NSManagedObject

@property (nonatomic, retain) NSString * albumArtURL;
@property (nonatomic, retain) NSString * audioSource;
@property (nonatomic, retain) NSString * composerFirstName;
@property (nonatomic, retain) NSString * composerFullName;
@property (nonatomic, retain) NSString * composerLastName;
@property (nonatomic, retain) NSString * composerLastNameInitial;
@property (nonatomic, retain) NSString * performer;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * track;
@property (nonatomic, retain) NSString * albumArtFileName;
@property (nonatomic, retain) NSSet *playlistEntries;
@property (nonatomic, retain) NSSet *snips;
@end

@interface SongModel (CoreDataGeneratedAccessors)

- (void)addPlaylistEntriesObject:(PlaylistEntryModel *)value;
- (void)removePlaylistEntriesObject:(PlaylistEntryModel *)value;
- (void)addPlaylistEntries:(NSSet *)values;
- (void)removePlaylistEntries:(NSSet *)values;
- (void)addSnipsObject:(SnipModel *)value;
- (void)removeSnipsObject:(SnipModel *)value;
- (void)addSnips:(NSSet *)values;
- (void)removeSnips:(NSSet *)values;
@end
