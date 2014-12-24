//
//  PlaylistViewController.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 2/28/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import "PlaylistViewController.h"
#import "MusicPlayerViewController.h"
#import "PlaylistCell.h"

#import "ModelManager.h"
#import "PlaylistEntryModel.h"
#import "SongModel.h"
#import "SnipLabel.h"

#import "GANTracker.h"

@interface PlaylistViewController() <UITableViewDelegate, UITableViewDataSource>

@property (strong) UITableView*					tableView;
@property (strong) PlaylistModel*				playlistModel;
@property (strong) NSFetchedResultsController*	fetchedResultsController;

@end



@implementation PlaylistViewController

@synthesize tableView = _tableView;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize playlistModel = _playlistModel;

- (id)initWithPlaylistModel:(PlaylistModel*)playlistModel
{
    self = [super init];
    if (self) {
        self.playlistModel = playlistModel;
		
		self.title = playlistModel.name;

		SnipLabel* titleView = [[SnipLabel alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
		titleView.text = self.title;
		titleView.font = [UIFont fontWithName:@"Wendy LP Std" size:36];
		titleView.textColor = [UIColor whiteColor];
		titleView.textAlignment = UITextAlignmentCenter;
		titleView.layer.shadowColor = [UIColor blackColor].CGColor;
		titleView.layer.shadowOffset = CGSizeMake(0, -0.5);
		titleView.layer.shadowOpacity = 1.0;
		titleView.layer.shadowRadius = 0.5;

		self.navigationItem.titleView = titleView;
		
		//
		// Fetch
		//
		
		ModelManager* modelManager = [ModelManager sharedModelManager];
		
		NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
		fetchRequest.entity = [NSEntityDescription entityForName:[PlaylistEntryModel description]
										  inManagedObjectContext:modelManager.managedObjectContext];
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"self in %@", playlistModel.playlistEntries];
		fetchRequest.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"order" 
																							   ascending:YES], nil];		
		
		fetchRequest.fetchBatchSize = 100;
		
		self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																			managedObjectContext:modelManager.managedObjectContext
																			  sectionNameKeyPath:nil
																					   cacheName:nil];
		
		NSError* error = nil;
		[self.fetchedResultsController performFetch:&error];
    }
    return self;
}

- (id)initWithComposer:(NSString*)composer
{
    self = [super init];
    if (self) {
		self.title = composer;
		

		//
		// Fetch
		//
		
		ModelManager* modelManager = [ModelManager sharedModelManager];
		
		NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
		fetchRequest.entity = [NSEntityDescription entityForName:[PlaylistEntryModel description]
										  inManagedObjectContext:modelManager.managedObjectContext];
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"self.song.composerFullName == %@", composer];
		fetchRequest.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"song.title" 
																							   ascending:YES], nil];		
		
		fetchRequest.fetchBatchSize = 100;
		
		self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																			managedObjectContext:modelManager.managedObjectContext
																			  sectionNameKeyPath:nil
																					   cacheName:nil];
		
		NSError* error = nil;
		[self.fetchedResultsController performFetch:&error];				
	}	
	return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView
{
	[super loadView];
	self.view.frame = CGRectMake(0, 0, 320, 368);
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"PlaylistBackground"]];
	
	self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.backgroundView =  nil;
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.backgroundView.opaque = NO;
	self.tableView.opaque = NO;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	[self.view addSubview:self.tableView];	
	
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavBarBackground"] 
												  forBarMetrics:UIBarMetricsDefault];	
	
	UIImage* backImage = [UIImage imageNamed:@"BackButton"];
	UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
	backButton.frame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
	[backButton setImage:backImage forState:UIControlStateNormal];
	[backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];

	UIBarButtonItem* backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton]; 
	self.navigationItem.leftBarButtonItem = backBarButtonItem; 		
	
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	NSError* error = nil;
	if (![[GANTracker sharedTracker] trackPageview:[NSString stringWithFormat:@"/playlist/%@", self.playlistModel.name]
										 withError:&error]) {
		NSLog(@"error in trackPageview");
	}
	
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 46;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{   
    PlaylistCell* cell = [tableView dequeueReusableCellWithIdentifier:[PlaylistCell reuseIdentifier]];
    if (cell == nil) {
		cell = [[PlaylistCell alloc] init];
    }
    
    // Configure the cell...
	PlaylistEntryModel* playlistEntryModel = (PlaylistEntryModel*) [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = playlistEntryModel.song.title;
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", playlistEntryModel.song.composerFirstName, playlistEntryModel.song.composerLastName];
	
    return cell;
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

#pragma mark - Actions

-(void)backButtonAction
{
	[self.navigationController popViewControllerAnimated:YES];
}

@end
