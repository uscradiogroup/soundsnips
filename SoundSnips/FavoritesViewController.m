//
//  FavoritesViewController.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 4/19/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "FavoritesViewController.h"
#import "ModelManager.h"
#import "PlaylistCell.h"
#import "SongModel.h"
#import "MusicPlayerViewController.h"
#import "PlaylistEntryModel.h"
#import "GANTracker.h"

@interface FavoritesViewController ()

@property (strong) NSFetchedResultsController*	fetchedResultsController;
@property (strong) UILabel*						noFavoritesLabel;

@end

@implementation FavoritesViewController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize tableView = _tableView;
@synthesize noFavoritesLabel = _noFavoritesLabel;

- (id)init
{
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Favorites", @"Favorites Title");
		self.tabBarItem.image = [UIImage imageNamed:@"Favorites"];
		
		//
		// Fetch
		//

		ModelManager* modelManager = [ModelManager sharedModelManager];

		NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
		fetchRequest.entity = [NSEntityDescription entityForName:[PlaylistEntryModel description]
										  inManagedObjectContext:modelManager.managedObjectContext];

		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"self in %@", modelManager.favoritesPlaylist.playlistEntries];
		fetchRequest.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"order"
																							   ascending:YES], nil];

		fetchRequest.fetchBatchSize = 100;

		self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																			managedObjectContext:modelManager.managedObjectContext
																			  sectionNameKeyPath:nil
																					   cacheName:nil];
		self.fetchedResultsController.delegate = self;
		
    }
    return self;
}

- (void)loadView
{
	[super loadView];
	self.view.frame = CGRectMake(0, 0, 320, 368);
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"PlaylistBackground"]];
	
	self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.backgroundView = nil;
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.backgroundView.opaque = NO;
	self.tableView.opaque = NO;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

	[self.view addSubview:self.tableView];
	
	self.noFavoritesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 120)];
	self.noFavoritesLabel.center = self.tableView.center;
	self.noFavoritesLabel.text = @"Select songs and add them to your favorites.";
	self.noFavoritesLabel.hidden = YES;
	self.noFavoritesLabel.backgroundColor = [UIColor clearColor];
	self.noFavoritesLabel.opaque = NO;
	self.noFavoritesLabel.numberOfLines = 2;
	self.noFavoritesLabel.textAlignment = UITextAlignmentCenter;
	self.noFavoritesLabel.font = [UIFont fontWithName:@"Wendy LP Std" size:36];
	self.noFavoritesLabel.textColor = [UIColor whiteColor];
	self.noFavoritesLabel.shadowOffset = CGSizeMake(0, 0.5f);
	self.noFavoritesLabel.shadowColor = [UIColor blackColor];
	[self.view addSubview:self.noFavoritesLabel];

	self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavBarBackground"]
												  forBarMetrics:UIBarMetricsDefault];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	UIImage* editButtonImage = [UIImage imageNamed:@"EditButton"];
	UIImage* doneButtonImage = [UIImage imageNamed:@"DoneButton"];
	UIButton* editButton = [UIButton buttonWithType:UIButtonTypeCustom];
	editButton.frame = CGRectMake(0, 0, editButtonImage.size.width, editButtonImage.size.height);
	[editButton setBackgroundImage:editButtonImage forState:UIControlStateNormal];
	[editButton setBackgroundImage:editButtonImage forState:UIControlStateHighlighted];
	[editButton setBackgroundImage:doneButtonImage forState:UIControlStateSelected];
	[editButton addTarget:self action:@selector(editButtonAction:) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem* editButtonItem = [[UIBarButtonItem alloc] initWithCustomView:editButton];
    self.navigationItem.leftBarButtonItem = editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	NSError* error;
	[self.fetchedResultsController performFetch:&error];
	[self.tableView reloadData];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	NSError* error = nil;
	if (![[GANTracker sharedTracker] trackPageview:@"/favorites"
										 withError:&error]) {
		NSLog(@"error in trackPageview");
	}
	
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	
	self.noFavoritesLabel.hidden = ([sectionInfo numberOfObjects] > 0);
	
	return [sectionInfo numberOfObjects];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 46;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[PlaylistCell reuseIdentifier]];
    if (cell == nil) {
		cell = [[PlaylistCell alloc] init];
    }
    
	PlaylistEntryModel* entry = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = entry.song.title;
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", entry.song.composerFirstName, entry.song.composerLastName];
		
    return cell;
}

-(void)setEditing:(BOOL)editing
{
	[super setEditing:editing];
	[self.tableView setEditing:editing];
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	[self.tableView setEditing:editing animated:animated];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray* fetchedResults = self.fetchedResultsController.fetchedObjects;
		
	MusicPlayerViewController* musicPlayerViewController = [MusicPlayerViewController sharedMusicPlayerViewController];
	[musicPlayerViewController prepareWithPlaylistEntries:fetchedResults selectedIndex:indexPath.row];
	
	[self.navigationController pushViewController:musicPlayerViewController animated:YES];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];	
}

#pragma mark - Table view Editing

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		PlaylistEntryModel* entry = [self.fetchedResultsController objectAtIndexPath:indexPath];
		[[ModelManager sharedModelManager].managedObjectContext deleteObject:entry];
		[[ModelManager sharedModelManager].managedObjectContext processPendingChanges];
		[[ModelManager sharedModelManager] saveContext];
	}
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	PlaylistEntryModel* sourceEntry = [self.fetchedResultsController objectAtIndexPath:sourceIndexPath];
	
	NSMutableArray* playlistEntries = [[self.fetchedResultsController fetchedObjects] mutableCopy];
	[playlistEntries removeObjectAtIndex:sourceIndexPath.row];
	[playlistEntries insertObject:sourceEntry atIndex:destinationIndexPath.row];

	int order = 0;
	for (PlaylistEntryModel* entry in playlistEntries) {
		entry.order = [NSNumber numberWithInt:order];
		order++;
	}
	
	ModelManager* modelManager = [ModelManager sharedModelManager];
	PlaylistModel* favoritesPlaylist = [modelManager favoritesPlaylist];
	favoritesPlaylist.playlistEntries = [NSSet setWithArray:playlistEntries];
}

-(void)controller:(NSFetchedResultsController *)controller 
  didChangeObject:(id)anObject 
      atIndexPath:(NSIndexPath *)indexPath 
    forChangeType:(NSFetchedResultsChangeType)type 
     newIndexPath:(NSIndexPath *)newIndexPath;
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationTop];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationBottom];
            break;
		case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

-(void)editButtonAction:(id)sender
{
	[self setEditing:!self.editing animated:YES];
	UIButton* but = (UIButton*)sender;
	but.selected = self.editing;
}


@end
