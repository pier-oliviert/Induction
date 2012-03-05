#import <Foundation/Foundation.h>
#import "DBAdapter.h"

@protocol SQLResultSet;
@protocol SQLConnection <DBConnection>

- (id <SQLResultSet>)executeSQL:(NSString *)SQL error:(NSError **)error;

@end

#pragma mark -

@protocol SQLDatabase <DBDatabase>

@property (readonly, nonatomic) id <SQLConnection> connection;

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSStringEncoding stringEncoding;

@property (readonly, nonatomic) NSArray *tables;

@end

#pragma mark -

@protocol SQLTable <DBDataSource, DBExplorableDataSource, DBQueryableDataSource, DBVisualizableDataSource>

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSStringEncoding stringEncoding;

@end

#pragma mark -

@protocol SQLField <NSObject>

@property (readonly, nonatomic) NSUInteger index;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) DBValueType type;
@property (readonly, nonatomic) NSUInteger size;

@end

#pragma mark -

@protocol SQLTuple <DBRecord>

@property (readonly, nonatomic) NSUInteger index;

@end

#pragma mark -

@protocol SQLResultSet <DBResultSet>

@property (readonly, nonatomic) NSArray *fields;
@property (readonly, nonatomic) NSArray *tuples;

@end
