//
//  ArtistsViewController.m
//  SoundSnips
//
//  Created by Sherwin Zadeh on 2/28/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import "ArtistsViewController.h"
#import "ModelManager.h"
#import "SongModel.h"
#import "PlaylistViewController.h"
#import "ArtistsHeaderView.h"
#import "ArtistsCell.h"
#import "AudioStreamer.h"
#import "GANTracker.h"

@implementation ArtistsViewController

@synthesize tableView = _tableView;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize sectionNames = _sectionNames;
@synthesize sectionRows = _sectionRows;

- (id)init
{
    self = [super init];
    if (self) {
		
		self.title = NSLocalizedString(@"Artists", @"Artists");
		self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NavBarLogo"]];		
		self.tabBarItem.image = [UIImage imageNamed:@"Authors"];
		
		//
		// Fetch
		//
		
		ModelManager* modelManager = [ModelManager sharedModelManager];
		
		NSFetchRequest* fetchInitialsRequest = [[NSFetchRequest alloc] init];
		fetchInitialsRequest.entity = [NSEntityDescription entityForName:@"SongModel" inManagedObjectContext:modelManager.managedObjectContext];
		fetchInitialsRequest.returnsDistinctResults = YES;
		fetchInitialsRequest.resultType = NSDictionaryResultType;
		fetchInitialsRequest.includesPendingChanges = YES;
		NSAttributeDescription* composerInitialAttribute = [fetchInitialsRequest.entity.attributesByName objectForKey:@"composerLastNameInitial"];
		fetchInitialsRequest.propertiesToFetch = [NSArray arrayWithObjects:composerInitialAttribute, nil];
		fetchInitialsRequest.sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"composerLastNameInitial" 
																									ascending:YES
																									 selector:@selector(caseInsensitiveCompare:)]];
		fetchInitialsRequest.predicate = [NSPredicate predicateWithValue:YES];
				
		NSError* error = nil;
		self.sectionNames = [[modelManager.managedObjectContext executeFetchRequest:fetchInitialsRequest error:&error] mutableCopy];
		self.sectionNames = [self.sectionNames valueForKeyPath:@"composerLastNameInitial"];
		
		NSFetchRequest* fetchArtistsRequest = [[NSFetchRequest alloc] init];
		fetchArtistsRequest.entity = [NSEntityDescription entityForName:@"SongModel" inManagedObjectContext:modelManager.managedObjectContext];
		fetchArtistsRequest.returnsDistinctResults = YES;
		fetchArtistsRequest.resultType = NSDictionaryResultType;
		fetchArtistsRequest.includesPendingChanges = YES;
		NSAttributeDescription* composerFullNameAttribute = [fetchArtistsRequest.entity.attributesByName objectForKey:@"composerFullName"];
		NSAttributeDescription* composerLastNameAttribute = [fetchArtistsRequest.entity.attributesByName objectForKey:@"composerLastName"];
		NSAttributeDescription* composerLastNameInitialAttribute = [fetchArtistsRequest.entity.attributesByName objectForKey:@"composerLastNameInitial"];
		fetchArtistsRequest.propertiesToFetch = @[composerFullNameAttribute, composerLastNameAttribute, composerLastNameInitialAttribute];
		fetchArtistsRequest.sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"composerFullName" 
																								   ascending:YES
																									selector:@selector(caseInsensitiveCompare:)]];
		fetchArtistsRequest.predicate = [NSPredicate predicateWithValue:YES];
		NSArray* allComposers = [modelManager.managedObjectContext executeFetchRequest:fetchArtistsRequest error:&error];
		
		self.sectionRows = [NSMutableArray arrayWithCapacity:[allComposers count]];
		for (int sectionIndex = 0; sectionIndex < [allComposers count]; sectionIndex++) {
			[self.sectionRows addObject:[NSMutableArray array]];
		}
		
		for (NSDictionary* composerDictionary in allComposers) {
			NSString* composerFullName			= [composerDictionary objectForKey:@"composerFullName"];
			NSString* composerLastName			= [composerDictionary objectForKey:@"composerLastName"];
			NSString* composerLastNameInitial	= [composerDictionary objectForKey:@"composerLastNameInitial"];
			
			// Find right section
			for (int sectionIndex = 0; sectionIndex < [self.sectionNames count]; sectionIndex++) {
				NSString* sectionName = [self.sectionNames objectAtIndex:sectionIndex];
				if ([sectionName isEqualToString:composerLastNameInitial]) {
					NSMutableArray* rows = [self.sectionRows objectAtIndex:sectionIndex];
					[rows addObject:@{@"composerFullName":composerFullName, @"composerLastName":composerLastName}];
					break;
				}
			}
		}
		
		for (NSMutableArray* rowArray in self.sectionRows)
		{
			[rowArray sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"composerLastName"
																		 ascending:YES
																		  selector:@selector(caseInsensitiveCompare:)]]];
		}
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
	self.tableView.backgroundView =  nil;//[[UIView alloc] initWithFrame:self.tableView.bounds];
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.backgroundView.opaque = NO;
	self.tableView.opaque = NO;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	[self.view addSubview:self.tableView];
	
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavBarBackground"] 
												  forBarMetrics:UIBarMetricsDefault];
	
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	for(UIView *view in [self.tableView subviews])
	{
		if([[[view class] description] isEqualToString:@"UITableViewIndex"])
		{
			[view performSelector:@selector(setIndexColor:) withObject:[UIColor colorWithWhite:0.0 alpha:0.5]];
		}
	}	

	NSError* error = nil;
	if (![[GANTracker sharedTracker] trackPageview:@"/artists"
										 withError:&error]) {
		NSLog(@"error in trackPageview");
	}
	
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [self.sectionNames count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self.sectionRows objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    ArtistsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [[ArtistsCell alloc] init];
    }
    
    // Configure the cell...
	NSArray* rowsInSection = [self.sectionRows objectAtIndex:indexPath.section];
	cell.textLabel.text = [[rowsInSection objectAtIndex:indexPath.row] objectForKey:@"composerFullName"];

	
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return ArtistsHeaderViewHeight;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	ArtistsHeaderView* headerView = [[ArtistsHeaderView alloc] init];
	headerView.textLabel.text = [self.sectionNames objectAtIndex:section];
	
	return headerView;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return self.sectionNames;
}

- (NSInteger) tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	return index;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 46;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary* composerDictionary = [[self.sectionRows objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	NSString* composer = composerDictionary[@"composerFullName"];
	PlaylistViewController* playlistViewController = [[PlaylistViewController alloc] initWithComposer:composer];
	
	[self.navigationController pushViewController:playlistViewController animated:YES];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
