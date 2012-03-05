//
//  DBConnectionConfigurationViewController.h
//  Kirin
//
//  Created by Mattt Thompson on 12/01/26.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DBAdapter.h"

@class DBConnectionConfigurationViewController;
@class DBDatabaseParameterFormatter;

@protocol DBConnectionConfigurationViewControllerProtocol <NSObject>
@required
- (void)connectionConfigurationControllerDidConnectWithConnection:(id <DBConnection>)connection;
@end

@interface DBConnectionConfigurationViewController : NSViewController <NSTextFieldDelegate>

@property (strong) id <DBConnectionConfigurationViewControllerProtocol> delegate;

@property (strong) NSURL *connectionURL;

@property (assign) IBOutlet NSTextField *URLField;
@property (assign) IBOutlet NSPopUpButton *schemePopupButton;
@property (assign) IBOutlet NSTextField *hostnameField;
@property (assign) IBOutlet NSTextField *usernameField;
@property (assign) IBOutlet NSTextField *passwordField;
@property (assign) IBOutlet NSTextField *portField;
@property (assign) IBOutlet NSTextField *databaseField;

- (IBAction)connect:(id)sender;

@end
