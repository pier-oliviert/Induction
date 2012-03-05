//
//  PostgreSQL.h
//  NoSQL
//
//  Created by Mattt Thompson on 12/01/24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLAdapter.h"

#import "libpq-fe.h"

extern NSString * const PostgreSQLErrorDomain;

#pragma mark -

@interface PostgreSQLAdapter : NSObject <DBAdapter>

@end

@interface PostgreSQLConnection : NSObject <SQLConnection>

@end

#pragma mark -

@interface PostgreSQLDatabase : NSObject <SQLDatabase>

- (id)initWithConnection:(PostgreSQLConnection *)connection 
                    name:(NSString *)name
          stringEncoding:(NSStringEncoding)stringEncoding;

@end

#pragma mark -

// TODO Make NSProxy to sql result set
@interface PostgreSQLTable : NSObject <SQLTable>

- (id)initWithDatabase:(id <SQLDatabase>)database
                  name:(NSString *)name
        stringEncoding:(NSStringEncoding)stringEncoding;

@end

#pragma mark -

@interface PostgreSQLResultSet : NSObject <SQLResultSet>

- (id)initWithPGResult:(PGresult *)pgresult;

@end

#pragma mark -

@interface PostgreSQLField : NSObject <SQLField>

+ (PostgreSQLField *)fieldInPGResult:(PGresult *)pgresult atIndex:(NSUInteger)fieldIndex;

- (id)objectForBytes:(const char *)bytes 
              length:(NSUInteger)length 
            encoding:(NSStringEncoding)encoding;

@end

#pragma mark -

@interface PostgreSQLTuple : NSObject <SQLTuple>

- (id)initWithValuesKeyedByFieldName:(NSDictionary *)keyedValues;

@end
