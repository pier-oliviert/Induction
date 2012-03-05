//
//  QueryViewController.m
//  Kirin
//
//  Created by Mattt Thompson on 12/01/27.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import "QueryViewController.h"

#import "DBDatabaseViewController.h"
#import "DBResultSetViewController.h"
#import "DBAdapter.h"

@implementation QueryViewController
@synthesize databaseViewController = _databaseViewController;
@synthesize resultsTableViewController = _resultsTableViewController;
@synthesize contentBox = _contentBox;
@synthesize textView = _textView;

- (void)awakeFromNib {
    self.textView.font = [NSFont userFixedPitchFontOfSize:18.0f];
    
    self.contentBox.contentView = self.resultsTableViewController.view;
}

#pragma mark - IBAction

- (IBAction)execute:(id)sender {
    self.resultsTableViewController.representedObject = (id <DBResultSet>)[(id <DBQueryableDataSource>)self.representedObject resultSetForQuery:[self.textView string] error:nil];
}

@end
