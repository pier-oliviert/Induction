//
//  QueryViewController.h
//  Kirin
//
//  Created by Mattt Thompson on 12/01/27.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DBDatabaseViewController;
@class DBResultSetViewController;

@interface QueryViewController : NSViewController

@property (strong, nonatomic) IBOutlet DBDatabaseViewController *databaseViewController;
@property (strong, nonatomic) IBOutlet DBResultSetViewController *resultsTableViewController;
@property (strong, nonatomic) IBOutlet NSBox *contentBox;
@property (strong, nonatomic) IBOutlet NSTextView *textView;

- (IBAction)execute:(id)sender;

@end
