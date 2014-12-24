//
//  FirstViewController.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 2/20/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "HomeViewController.h"
#import "ModelManager.h"
#import "PlaylistModel.h"
#import "PlaylistViewController.h"
#import "HomeCell.h"

#import "GANTracker.h"

@interface HomeViewController() <UITableViewDelegate, UITableViewDataSource>

@property (strong) UITableView*					tableView;
@property (strong) NSFetchedResultsController*	fetchedResultsController;

@end




@implementation HomeViewController

@synthesize tableView = _tableView;
@synthesize fetchedResultsController = _fetchedResultsController;

- (id)init
{
    self = [super init];
    if (self) {
		self.title = NSLocalizedString(@"Home", @"Home");
		
		self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NavBarLogo"]];
		self.tabBarItem.image = [UIImage imageNamed:@"Home"];
		
		//
		// Fetch
		//
		
		ModelManager* modelManager = [ModelManager sharedModelManager];
		
		NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
		fetchRequest.entity = [NSEntityDescription entityForName:[PlaylistModel description]
										  inManagedObjectContext:modelManager.managedObjectContext];
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name != 'Favorites'"];
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
							
- (void)didReceiveMemoryWarning
{
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
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	NSError* error = nil;
	if (![[GANTracker sharedTracker] trackPageview:@"/home"
										 withError:&error]) {
		NSLog(@"error in trackPageview");
	}
	
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[self.fetchedResultsController sections] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 62;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[HomeCell reuseIdentifier]];
    if (cell == nil) {
		cell = [[HomeCell alloc] init];
    }
    	
	PlaylistModel* playlistModel = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@" %@", playlistModel.name]; // Adding space to accompodate for decorative font style
	
	UIImage* iconImage = [UIImage imageWithContentsOfFile:playlistModel.iconFileName];
	cell.imageView.image = iconImage;

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	PlaylistModel* playlistModel = [self.fetchedResultsController objectAtIndexPath:indexPath];
	PlaylistViewController* playlistViewController = [[PlaylistViewController alloc] initWithPlaylistModel:playlistModel];
	
	[self.navigationController pushViewController:playlistViewController animated:YES];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
