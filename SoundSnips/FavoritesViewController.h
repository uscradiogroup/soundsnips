//
//  FavoritesViewController.h
//  SoundSnips
//
//  Created by Sherwin Zadeh on 4/19/12.
//  Copyright (c) 2012 KUSC Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface FavoritesViewController : BaseViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>

@property (strong) UITableView*					tableView;

@end
