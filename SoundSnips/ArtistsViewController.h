//
//  ArtistsViewController.h
//  SoundSnips
//
//  Created by Sherwin Zadeh on 2/28/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "BaseViewController.h"

@interface ArtistsViewController : BaseViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong) UITableView*					tableView;

@property (strong) NSFetchedResultsController*	fetchedResultsController;
@property (strong) NSArray*			sectionNames;
@property (strong) NSMutableArray*	sectionRows; // 2D

@end
