//
//  SQLSyntaxHighlighter.h
//  Kirin
//
//  Created by Mattt Thompson on 12/02/02.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SQLSyntaxHighlighter : NSObject <NSTextViewDelegate, NSTextStorageDelegate>

@property (weak, nonatomic) IBOutlet NSTextView *textView;

@end
