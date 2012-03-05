#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

typedef enum {
    DBBooleanValue,
    DBIntegerValue,
    DBDecimalValue,
    DBStringValue,
    DBDateValue,
    DBBlobValue,
} DBValueType;

@protocol DBConnection;
@protocol DBAdapter <NSObject>

+ (NSString *)primaryURLScheme;
+ (BOOL)canConnectWithURL:(NSURL *)url;
+ (id <DBConnection>)connectionWithURL:(NSURL *)url 
                                 error:(NSError **)error;

@end

@protocol DBConnection <NSObject>

@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) NSArray *databases;

- (id)initWithURL:(NSURL *)url;

- (BOOL)open;
- (BOOL)close;
- (BOOL)reset;
@end

#pragma mark -

@protocol DBDatabase <NSObject>

@property (nonatomic, readonly) id <DBConnection> connection;
@property (nonatomic, readonly) NSOrderedSet *dataSourceGroupNames;

- (NSArray *)dataSourcesForGroupNamed:(NSString *)groupName;

@end

#pragma mark -

@protocol DBResultSet;
@protocol DBDataSource <NSObject>

- (NSUInteger)numberOfRecords;

@end

@protocol DBExplorableDataSource <NSObject>

- (id <DBResultSet>)resultSetForRecordsAtIndexes:(NSIndexSet *)indexes                                                          
                                           error:(NSError **)error;

@end

@protocol DBQueryableDataSource <NSObject>

- (id <DBResultSet>)resultSetForQuery:(NSString *)query 
                                error:(NSError **)error;

@end

@protocol DBVisualizableDataSource <NSObject>

- (id <DBResultSet>)resultSetForDimension:(NSExpression *)dimension
                                 measures:(NSArray *)measures
                                    error:(NSError **)error;

@end

#pragma mark -

@protocol DBResultSet <NSObject>

- (NSUInteger)numberOfRecords;
- (NSArray *)recordsAtIndexes:(NSIndexSet *)indexes;

- (NSUInteger)numberOfFields;
- (NSString *)identifierForTableColumnAtIndex:(NSUInteger)index;
@optional
- (DBValueType)valueTypeForTableColumnAtIndex:(NSUInteger)index;
- (NSCell *)dataCellForTableColumnAtIndex:(NSUInteger)index;
- (NSSortDescriptor *)sortDescriptorPrototypeForTableColumnAtIndex:(NSUInteger)index;
@end

@protocol DBRecord <NSObject>

- (id)valueForKey:(NSString *)key;

@optional

@property (nonatomic, readonly) NSArray *children;

@end
