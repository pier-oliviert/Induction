//
//  DBDatabaseViewController.h
//  Kirin
//
//  Created by Mattt Thompson on 12/01/26.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DBAdapter.h"

@class ExploreTableViewController;
@class QueryViewController;
@class VisualizeViewController;
@class SQLResultsTableViewController;

enum _DBDatabaseViewTabs {
    ExploreTab,
    QueryTab,
    VisualizeTab,
} DBDatabaseViewTabs;

@interface DBDatabaseViewController : NSViewController <NSOutlineViewDelegate>

@property (strong, nonatomic) id <DBDatabase> database;
@property (strong, nonatomic, readonly) NSArray *sourceListNodes;

@property (weak, nonatomic) IBOutlet NSToolbar *toolbar;
@property (weak, nonatomic) IBOutlet NSOutlineView *outlineView;
@property (weak, nonatomic) IBOutlet NSTabView *tabView;

@property (strong, nonatomic) IBOutlet ExploreTableViewController *exploreViewController;
@property (strong, nonatomic) IBOutlet QueryViewController *queryViewController;
@property (strong, nonatomic) IBOutlet VisualizeViewController *visualizeViewController;

- (IBAction)explore:(id)sender;
- (IBAction)query:(id)sender;
- (IBAction)visualize:(id)sender;

@end
