//
//  DBRangeEnumerator.h
//  Kirin
//
//  Created by Mattt Thompson on 12/02/22.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBPaginator : NSObject
@property (readonly) NSUInteger numberOfIndexes;
@property (readonly) NSUInteger currentPage;
@property (readonly) NSRange currentRange;

- (id)initWithNumberOfIndexes:(NSUInteger)numberOfIndexes
                     pageSize:(NSUInteger)pageSize;

- (NSString *)localizedDescriptionOfCurrentRange;

- (BOOL)hasPreviousPage;
- (NSRange)previousPage;

- (BOOL)hasNextPage;
- (NSRange)nextPage;

@end
