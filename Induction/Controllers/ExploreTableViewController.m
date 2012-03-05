//
//  ExploreViewController.m
//  Kirin
//
//  Created by Mattt Thompson on 12/01/26.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import "ExploreTableViewController.h"
#import "DBDatabaseViewController.h"
#import "DBResultSetViewController.h"
#import "DBPaginator.h"

static NSUInteger const kExploreDefaultPageSize = 256;

@interface ExploreTableViewController () {
@private
    NSUInteger _pageSize;
    NSUInteger _currentPage;
    __strong DBPaginator *_paginator;
}

@property (readonly) NSRange currentPageRange;

@end

@implementation ExploreTableViewController
@synthesize resultSetViewController = _resultSetViewController;
@synthesize contentBox = _contentBox;
@synthesize leftArrowPageButton = _leftArrowPageButton;
@synthesize rightArrowPageButton = _rightArrowPageButton;
@synthesize pageTextField = _pageTextField;

- (void)awakeFromNib {
    self.contentBox.contentView = self.resultSetViewController.view;
}

- (NSRange)currentPageRange {
    return NSMakeRange(_currentPage * _pageSize, _pageSize);
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    _paginator = [[DBPaginator alloc] initWithNumberOfIndexes:[(id <DBDataSource>)self.representedObject numberOfRecords] pageSize:kExploreDefaultPageSize];
    
    [self changePage:nil];
}

#pragma mark - IBAction

- (IBAction)changePage:(id)sender {
    if ([sender isEqual:self.leftArrowPageButton]) {
        [_paginator previousPage];
    } else if ([sender isEqual:self.rightArrowPageButton]) {
        [_paginator nextPage];
    }
    
    [self.leftArrowPageButton setEnabled:[_paginator hasPreviousPage]];
    [self.rightArrowPageButton setEnabled:[_paginator hasNextPage]];
    
    self.pageTextField.stringValue = [_paginator localizedDescriptionOfCurrentRange];
    
    self.resultSetViewController.representedObject = [(id <DBExplorableDataSource>)self.representedObject resultSetForRecordsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:[_paginator currentRange]] error:nil];
}



@end
