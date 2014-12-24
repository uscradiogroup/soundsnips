//
//  ModelManager.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 8/5/11.
//  Copyright 2011 Artamata, Inc. All rights reserved.
//

#import "ModelManager.h"
#import "WebService.h"
#import "Additions.h"
#import "Reachability.h"

#import "PlaylistModel.h"
#import "PlaylistEntryModel.h"
#import "SongModel.h"
#import "SnipModel.h"

#define GET_PLAYLISTS_URL (@"http://soundsnips.org/static/json/playlist.json")

#define ISNSNULL(X) ([X isKindOfClass:[NSNull class]])

#define ALERT_VIEW_NO_CONNECTION 100
#define ALERT_VIEW_LOGIN 200	

static ModelManager* g_sharedModelManager = nil;

// Private
@interface ModelManager() 
{
	PlaylistModel* _favoritesPlaylist;
}

@property (unsafe_unretained) id<ModelManagerDelegate> delegate;
@property (assign) int numberofRunningWebServices;

-(void)sync;
-(void)delegateCallbackHelper;
-(void)createModelObjectsFromJsonString:(NSString*)jsonString;
-(NSURL*)applicationDocumentsDirectory;

@end

@implementation ModelManager

@synthesize delegate = _delegate;
@synthesize numberofRunningWebServices = _numberofRunningWebServices;

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

@synthesize modelManagerDownloaded = _modelManagerDownloaded;
@dynamic favoritesPlaylist;


#pragma mark - Singleton

+ (ModelManager*) sharedModelManager 
{	
	if (g_sharedModelManager == nil) {
		g_sharedModelManager = [[ModelManager alloc] init];
	}
	
	return g_sharedModelManager;
}

#pragma mark - Life Cycle

- (id)init 
{
    self = [super init];
    if (self) {
    }

    return self;
}

- (void)beginDownloadWithDelegate:(id<ModelManagerDelegate>) delegate
{
	self.delegate = delegate;

	[self sync];
}

-(void)createModelObjectsFromJsonString:(NSString*)jsonString
{
//	NSString* playlistsResponseString = [[NSString alloc] initWithData:playlistsResponse encoding:NSASCIIStringEncoding];
	NSData* playlistsResponseData =[jsonString dataUsingEncoding:NSUTF8StringEncoding];
		
	NSError* error = nil;	
	NSArray* playlistsArray = (NSArray*) [NSJSONSerialization JSONObjectWithData:playlistsResponseData 
																		 options:NSJSONReadingAllowFragments 
																		   error:&error];
	
	int playListOrder = 0;
	for (NSDictionary* playlistDictionary in playlistsArray) {
		
		PlaylistModel* playlist = (PlaylistModel*) [NSEntityDescription insertNewObjectForEntityForName:[PlaylistModel description]
																					  inManagedObjectContext:self.managedObjectContext];
		playlist.name	= [playlistDictionary notNullObjectForKey:@"playlist_name"];
		playlist.order	= @(playListOrder++);
		
		int track = 1;
		NSArray* tracksArray = (NSArray*) [playlistDictionary notNullObjectForKey:@"tracks"];
		for (NSDictionary* trackDictionary in tracksArray) {
			
			// Playlist Entry
			PlaylistEntryModel* entry = (PlaylistEntryModel*) [NSEntityDescription insertNewObjectForEntityForName:[PlaylistEntryModel description]
																							inManagedObjectContext:self.managedObjectContext];
			entry.order = [NSNumber numberWithInt:track];

			[playlist addPlaylistEntriesObject:entry];

			// Song Model
			SongModel* song = (SongModel*) [NSEntityDescription insertNewObjectForEntityForName:[SongModel description]
																			  inManagedObjectContext:self.managedObjectContext];
			song.track				= [NSNumber numberWithInt:track];
			song.audioSource		= (NSString*) [trackDictionary notNullObjectForKey:@"src"];
			song.composerFirstName	= (NSString*) [trackDictionary notNullObjectForKey:@"composer_first"];
			song.composerLastName	= (NSString*) [trackDictionary notNullObjectForKey:@"composer_last"];
			song.title				= (NSString*) [trackDictionary notNullObjectForKey:@"title"];
			song.performer			= (NSString*) [trackDictionary notNullObjectForKey:@"performer"];
			song.albumArtURL		= (NSString*) [trackDictionary notNullObjectForKey:@"icon_large"];
			
			track++;

			// Following attributes are computed to assist in sorting and stuff later on
			song.composerFullName = [NSString stringWithFormat:@"%@ %@", song.composerFirstName, song.composerLastName];
			song.composerLastNameInitial = [[(NSString*)[trackDictionary notNullObjectForKey:@"composer_last"] substringToIndex:1] uppercaseString];

			NSURL* albumArtURL = [NSURL URLWithString:(NSString*) [trackDictionary notNullObjectForKey:@"icon_large"]];
			NSMutableString* fileName = [[albumArtURL lastPathComponent] mutableCopy];
			[fileName replaceOccurrencesOfString:@".png" 
									  withString:@"@2x.png" 
										 options:NSCaseInsensitiveSearch 
										   range:NSMakeRange(0, [fileName length])];
			song.albumArtFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];

			entry.song = song;			

			// Snips
			NSArray* snipsArray = (NSArray*) [trackDictionary notNullObjectForKey:@"soundsnips"];
			for (NSDictionary* snipDictionary in snipsArray) {

				SnipModel* snipModel = (SnipModel*) [NSEntityDescription insertNewObjectForEntityForName:[SnipModel description]
																				  inManagedObjectContext:self.managedObjectContext];
				snipModel.cuePoint	= (NSNumber*) [snipDictionary notNullObjectForKey:@"cue_point"];
				snipModel.text		= (NSString*) [snipDictionary notNullObjectForKey:@"text"];

				[song addSnipsObject:snipModel];
			}
		}
			
		//
		// Download the playlist icon
		//
		
		NSURL* playlistIconURL = [NSURL URLWithString:[playlistDictionary notNullObjectForKey:@"playlist_icon_ios"]];
		NSMutableString* fileName = [[playlistIconURL lastPathComponent] mutableCopy];
		[fileName replaceOccurrencesOfString:@".png" 
								  withString:@"@2x.png" 
									 options:NSCaseInsensitiveSearch 
									   range:NSMakeRange(0, [fileName length])];
		playlist.iconFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];

		if ([[NSFileManager defaultManager] fileExistsAtPath:playlist.iconFileName] == NO) {
			WebService* webService = [[WebService alloc] init];
			[webService beginRequestWithURL:playlistIconURL finished:^(NSData* responseData) 
			{
				if (responseData != nil) {

					
					if ([responseData writeToFile:playlist.iconFileName atomically:YES] == NO) {
						NSLog(@"Could not write to %@", playlist.iconFileName);
					}
				}			
			}];
		}
		
	}	
	
	[self saveContext];	
}

-(void)sync
{
	[self deleteAllPlaylistsExceptFavorites];
	
	__block id observer = nil;
	observer = [[NSNotificationCenter defaultCenter] addObserverForName:WEBSERVICES_ALL_FINISHED_NOTIFICATION
																 object:nil
																  queue:nil
															 usingBlock:^(NSNotification* notification)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:observer];
		[[ModelManager sharedModelManager] performSelectorOnMainThread:@selector(delegateCallbackHelper) 
															withObject:nil
														 waitUntilDone:NO];
	}];

	NSURL* url = [NSURL URLWithString:GET_PLAYLISTS_URL];
//	NSURL* url = [[NSBundle mainBundle] URLForResource:@"TestPlaylist" withExtension:@"json"];
//	 [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/TestPlaylist.jo
	WebService* webService = [[WebService alloc] init];
	[webService beginRequestWithURL:url finished:^(NSData* playlistsResponse) {
		
		if (playlistsResponse == nil)
			return;
		
		NSString* playlistsResponseString = [[NSString alloc] initWithData:playlistsResponse encoding:NSASCIIStringEncoding];
		NSLog(@"Playlists JSON Data:\r%@", playlistsResponseString); 		// For debugging
		
		
		[self createModelObjectsFromJsonString:playlistsResponseString];

		
	}];
	
	return;
}

-(void)delegateCallbackHelper
{
	[self.delegate modelManagerDownloadedSuccessfully:YES];
}


#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
	
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator* coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
	
    return _managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {

    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
	
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return _managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SoundSnipsModel.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}





#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
}

-(void)purge
{
	NSArray* stores = [self.persistentStoreCoordinator persistentStores];
	
	for (NSPersistentStore *store in stores) {
		[self.persistentStoreCoordinator removePersistentStore:store error:nil];
		[[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
	}
	
	_persistentStoreCoordinator = nil;	
	_managedObjectContext = nil;
	_managedObjectModel = nil;
}

-(void)deleteAllPlaylistsExceptFavorites
{
	NSFetchRequest* fetchRequest = nil;
	NSError* error = nil;
	
	//
	// Delete all songs that are NOT in favorites
	//
	
	fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[SongModel description]];
	fetchRequest.predicate = [NSPredicate predicateWithValue:YES];
	fetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]];
	
	NSArray* songs = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	
	for (SongModel* song in songs) {
		BOOL inFavorites = NO;
		for (PlaylistEntryModel* entry in song.playlistEntries) {
			if ([entry.playlist.name isEqualToString:@"Favorites"]) {
				inFavorites = YES;
				break;
			}
		}
		
		if (!inFavorites) {
			[self.managedObjectContext deleteObject:song];
		}
	}
	
	//
	// Delete all Playlists, except Favorites. Will also cascade to PlaylistEntries
	//
	
	fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[PlaylistModel description]];
	fetchRequest.predicate = [NSPredicate predicateWithValue:YES];
	fetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	
	NSArray* playlists = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	
	for (PlaylistModel* playlist in playlists) {
		if (![playlist.name isEqualToString:@"Favorites"]) {
			[self.managedObjectContext deleteObject:playlist];
		}
	}
	
	
	[self saveContext];
}

-(PlaylistModel*)favoritesPlaylist
{
	if (_favoritesPlaylist == nil) {
	
		NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[PlaylistModel description]];
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == 'Favorites'"]; // there should be only one
		
		NSError* error = nil;
		NSArray* fetchedResults = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		if (fetchedResults != nil && [fetchedResults count] > 0) {
			_favoritesPlaylist = [fetchedResults objectAtIndex:0];
		}
		else {
			_favoritesPlaylist = (PlaylistModel*) [NSEntityDescription insertNewObjectForEntityForName:[PlaylistModel description]
																				inManagedObjectContext:self.managedObjectContext];
			_favoritesPlaylist.name = @"Favorites";
		}
	}
	return _favoritesPlaylist;
}

-(void)addSongToFavorites:(SongModel*)songModel
{	
	NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[PlaylistEntryModel description]];
	fetchRequest.resultType = NSDictionaryResultType;
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"self in %@", _favoritesPlaylist.playlistEntries];
	NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"order"];
	NSExpression *maxOrderExpression = [NSExpression expressionForFunction:@"max:"
																  arguments:[NSArray arrayWithObject:keyPathExpression]];	
	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	[expressionDescription setName:@"maxOrder"];
	[expressionDescription setExpression:maxOrderExpression];
	[expressionDescription setExpressionResultType:NSInteger32AttributeType];
	[fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
	
	NSError* error;
	NSArray* maxResultArray = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	int max = (maxResultArray == nil || [maxResultArray count] == 0) ? -1 : [[[maxResultArray objectAtIndex:0] valueForKey:@"maxOrder"] intValue];
	
	PlaylistEntryModel* entry = [NSEntityDescription insertNewObjectForEntityForName:[PlaylistEntryModel description]
															  inManagedObjectContext:self.managedObjectContext];
	entry.song = songModel;
	entry.order = [NSNumber numberWithInt:max + 1];
	[self.favoritesPlaylist addPlaylistEntriesObject:entry];
	
	[self saveContext];
}

@end
