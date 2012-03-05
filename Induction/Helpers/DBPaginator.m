//
//  DBRangeEnumerator.m
//  Kirin
//
//  Created by Mattt Thompson on 12/02/22.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "DBPaginator.h"

@interface DBPaginator () {
@private
    NSRange _maximumRange;
    NSUInteger _pageSize;
    NSUInteger _currentPage;
}
@end

@implementation DBPaginator
@synthesize currentPage = _currentPage;

- (id)initWithNumberOfIndexes:(NSUInteger)numberOfIndexes
                     pageSize:(NSUInteger)pageSize
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _maximumRange = NSMakeRange(0, numberOfIndexes);
    _pageSize = pageSize;
    _currentPage = 0;
    
    return self;
}

- (NSString *)localizedDescriptionOfCurrentRange {
    if (_maximumRange.length == 0) {
        return @"";
    }
    
    return [NSString stringWithFormat:NSLocalizedString(@"%lu — %lu", @"Pagination Range Format"), [self currentRange].location, NSMaxRange([self currentRange])];
}

- (NSUInteger)numberOfIndexes {
    return NSMaxRange(_maximumRange);
}

- (NSRange)currentRange {
    return NSIntersectionRange(NSMakeRange(_currentPage * _pageSize, _pageSize), _maximumRange);
}

- (BOOL)hasPreviousPage {
    return _currentPage > 0;
}

- (NSRange)previousPage {
    [self willChangeValueForKey:@"currentPage"];
    _currentPage = MAX(_currentPage - 1, 0); 
    [self didChangeValueForKey:@"currentPage"];
    
    return [self currentRange];
}

- (BOOL)hasNextPage {
    return NSMaxRange([self currentRange]) < NSMaxRange(_maximumRange);
}

- (NSRange)nextPage {
    [self willChangeValueForKey:@"currentPage"];
    _currentPage = MIN(_currentPage + 1, ceil([self numberOfIndexes] / _pageSize)); 
    [self didChangeValueForKey:@"currentPage"];
    
    return [self currentRange];
}

@end
