//
//  VisualizeViewController.h
//  Kirin
//
//  Created by Mattt Thompson on 12/01/27.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class DBResultSetViewController;

@interface VisualizeViewController : NSViewController

@property (strong, nonatomic) IBOutlet NSTextView *textView;
@property (strong, nonatomic) IBOutlet NSPopUpButton *chartPopUpButton;
@property (strong, nonatomic) IBOutlet WebView *webView;

- (IBAction)visualize:(id)sender;

@end
