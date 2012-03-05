//
//  ExploreViewController.h
//  Kirin
//
//  Created by Mattt Thompson on 12/01/26.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SQLAdapter.h"

@class DBResultSetViewController;

@interface ExploreTableViewController : NSViewController <NSTableViewDelegate>

@property (strong, nonatomic) IBOutlet DBResultSetViewController *resultSetViewController;
@property (strong, nonatomic) IBOutlet NSBox *contentBox;

@property (strong, nonatomic) IBOutlet NSButton *leftArrowPageButton;
@property (strong, nonatomic) IBOutlet NSButton *rightArrowPageButton;
@property (strong, nonatomic) IBOutlet NSTextField *pageTextField;

- (IBAction)changePage:(id)sender;

@end
