//
//  VisualizeViewController.m
//  Kirin
//
//  Created by Mattt Thompson on 12/01/27.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import "VisualizeViewController.h"

#import "DBAdapter.h"
#import "DBResultSetViewController.h"

@implementation VisualizeViewController
@synthesize textView = _textView;
@synthesize chartPopUpButton = _chartPopUpButton;
@synthesize webView = _webView;

- (void)awakeFromNib {
    self.textView.font = [NSFont userFixedPitchFontOfSize:18.0f];
    
    [self.webView setUIDelegate:self];
    [self.webView setResourceLoadDelegate:self];
    [self.webView setFrameLoadDelegate:self];
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"visualization" ofType:@"html" inDirectory:@"HTML"]];
    [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark - IBAction

- (void)visualize:(id)sender {
    id <DBResultSet> resultSet = (id <DBResultSet>)[(id <DBQueryableDataSource>)self.representedObject resultSetForQuery:[self.textView string] error:nil];
    
    NSMutableArray *mutableKeys = [NSMutableArray array];
    [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [resultSet numberOfFields])] enumerateIndexesUsingBlock:^(NSUInteger fieldIndex, BOOL *stop) {
        [mutableKeys addObject:[resultSet identifierForTableColumnAtIndex:fieldIndex]];
    }];
    
    NSMutableArray *mutableValues = [NSMutableArray arrayWithCapacity:[resultSet numberOfRecords]];
    NSArray *records = [resultSet recordsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [resultSet numberOfRecords])]];
    [records enumerateObjectsUsingBlock:^(id <DBRecord> record, NSUInteger recordIndex, BOOL *stop) {
        NSMutableDictionary *keyedValues = [NSMutableDictionary dictionary];
        for (NSString *key in mutableKeys) {
            id value = [record valueForKey:key];
            if (value) {
                [keyedValues setObject:value forKey:key];
            } else {
                NSLog(@"!! %lu %@", recordIndex, key);
            }
        }
        [mutableValues addObject:keyedValues];
    }];
    
    NSMutableDictionary *mutableData = [NSMutableDictionary dictionary];
    [mutableData setObject:mutableValues forKey:@"values"];
    
    NSString *dimensionKey = @"x";
    [mutableKeys removeObject:@"x"];
    [mutableData setObject:dimensionKey forKey:@"dimension"];
    
    [mutableData setObject:mutableKeys forKey:@"measures"];

    [mutableData setObject:[[[self.chartPopUpButton selectedCell] title] lowercaseString] forKey:@"chart"];
        
    NSString *JSON = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:mutableData options:0 error:nil] encoding:NSUTF8StringEncoding];
    NSLog(@"JSON: %@", JSON);
    
    [[self.webView windowScriptObject] callWebScriptMethod:@"Visualize" withArguments:[NSArray arrayWithObject:JSON]];
}

#pragma mark - WebKit

/* this message is sent to the WebView's frame load delegate 
 when the page is ready for JavaScript.  It will be called just after 
 the page has loaded, but just before any JavaScripts start running on the
 page.  This is the perfect time to install any of your own JavaScript
 objects on the page.
 */
- (void)webView:(WebView *)webView windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    [windowScriptObject setValue:self forKey:@"console"];
}



/* sent to the WebView's ui delegate when alert() is called in JavaScript.
 If you call alert() in your JavaScript methods, it will call this
 method and display the alert message in the log.  In Safari, this method
 displays an alert that presents the message to the user.
 */
- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message {
	NSLog(@"%@ received %@ with '%@'", self, NSStringFromSelector(_cmd), message);
}



/* the following three methods are used to determine 
 what methods on our object are exposed to JavaScript */


/* This method is called by the WebView when it is deciding what
 methods on this object can be called by JavaScript.  The method
 should return NO the methods we would like to be able to call from
 JavaScript, and YES for all of the methods that cannot be called
 from JavaScript.
 */
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
	NSLog(@"%@ received %@ for '%@'", self, NSStringFromSelector(_cmd), NSStringFromSelector(selector));
    if (selector == @selector(doOutputToLog:)
        || selector == @selector(changeJavaScriptText:)
        || selector == @selector(reportSharedValue)) {
        return NO;
    }
    return YES;
}



/* This method is called by the WebView to decide what instance
 variables should be shared with JavaScript.  The method should
 return NO for all of the instance variables that should be shared
 between JavaScript and Objective-C, and YES for all others.
 */
+ (BOOL)isKeyExcludedFromWebScript:(const char *)property {
	NSLog(@"%@ received %@ for '%s'", self, NSStringFromSelector(_cmd), property);
//	if (strcmp(property, "sharedValue") == 0) {
//        return NO;
//    }
    return NO;
}



/* This method converts a selector value into the name we'll be using
 to refer to it in JavaScript.  here, we are providing the following
 Objective-C to JavaScript name mappings:
 'doOutputToLog:' => 'log'
 'changeJavaScriptText:' => 'setscript'
 With these mappings in place, a JavaScript call to 'console.log' will
 call through to the doOutputToLog: Objective-C method, and a JavaScript call
 to console.setscript will call through to the changeJavaScriptText:
 Objective-C method.  
 
 Comments for the webScriptNameForSelector: method in WebScriptObject.h talk more
 about the default name conversions performed from Objective-C to JavaScript names.
 You can overrride those defaults by providing your own translations in your
 webScriptNameForSelector: method.
 */
+ (NSString *) webScriptNameForSelector:(SEL)sel {
	NSLog(@"%@ received %@ with sel='%@'", self, NSStringFromSelector(_cmd), NSStringFromSelector(sel));
    if (sel == @selector(doOutputToLog:)) {
		return @"log";
    } else if (sel == @selector(changeJavaScriptText:)) {
		return @"setscript";
        /*
         NOTE:  for the console.report method, we do not need to perform a name translation
         because the Objective-C method name is already the same as the method name
         we will be using in JavaScript.  We have left this part commented out to show
         that the name translation here would be redundant.
         
         } else if (sel == @selector(report)) {
         return @"report";
         
         */
	} else {
		return nil;
	}

    return nil;
}



/* Here is our Objective-C implementation for the JavaScript console.log() method.
 */
- (void) doOutputToLog: (NSString*) theMessage {
	NSLog(@"%@ received %@ with message=%@", self, NSStringFromSelector(_cmd), theMessage);
    
    /* write the message to the log */
    NSLog(@"LOG: %@", theMessage);
    
}

@end
