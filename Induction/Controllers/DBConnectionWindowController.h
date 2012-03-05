//
//  DBConnectionWindowController.h
//  Kirin
//
//  Created by Mattt Thompson on 12/01/26.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DBConnectionConfigurationViewController.h"
#import "DBDatabaseViewController.h"

#import "DBAdapter.h"

@interface DBConnectionWindowController : NSWindowController  <DBConnectionConfigurationViewControllerProtocol>

@property (strong, nonatomic) id <DBConnection> connection;

@property (strong, nonatomic) DBConnectionConfigurationViewController *configurationViewController;
@property (strong, nonatomic) IBOutlet DBDatabaseViewController *databaseViewController;

@end
