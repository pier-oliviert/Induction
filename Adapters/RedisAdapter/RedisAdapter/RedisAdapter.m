//
//  RedisAdapter.m
//  Kirin
//
//  Created by Mattt Thompson on 12/02/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RedisAdapter.h"

#import "ObjCHiredis.h"

@implementation RedisAdapter

+ (NSString *)primaryURLScheme {
    return @"redis";
}

+ (BOOL)canConnectWithURL:(NSURL *)url {
    return [[url scheme] isEqualToString:@"redis"];
}

+ (id <DBConnection>)connectionWithURL:(NSURL *)url 
                                 error:(NSError **)error
{
    return [[RedisConnection alloc] initWithURL:url];
}

@end


@interface RedisConnection () {
@private
    __strong ObjCHiredis *_redis;
    __strong NSURL *_url;
    __strong NSArray *_keys;
}

@property (readonly) ObjCHiredis *client;

@end

@implementation RedisConnection
@synthesize client = _redis;
@synthesize url = _url;

#pragma mark - DBConnection

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _redis = [ObjCHiredis redis];
    _url = url;
    
    _keys = [_redis command:@"KEYS *"];
    
    return self;
}

- (BOOL)open {
    return YES;
}

- (BOOL)close {
    return YES;
}

- (BOOL)reset {
    return YES;
}

- (NSArray *)databases {
    return [NSArray arrayWithObject:self];
}

- (id <DBConnection>)connection {
    return self;
}

#pragma mark - DBDatabase

- (NSString *)name {
    return @"Redis";
}

- (NSOrderedSet *)dataSourceGroupNames {
    return [NSOrderedSet orderedSetWithObjects:NSLocalizedString(@"Keys", nil), nil];
}

- (NSArray *)dataSourcesForGroupNamed:(NSString *)groupName {
    return [NSArray arrayWithObject:[[RedisDataSource alloc] initWithName:NSLocalizedString(@"All Keys", nil) keys:_keys connection:self]];
}

@end

#pragma mark -

@interface RedisDataSource () {
@private
    __strong NSString *_name;
    __strong NSArray *_keys;
    __strong RedisConnection *_connection;
}
@end

@implementation RedisDataSource

- (id)initWithName:(NSString *)name
              keys:(NSArray *)keys
        connection:(RedisConnection *)connection 
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _name = name;
    _keys = keys;
    _connection = connection;
    
    return self;
}

- (NSUInteger)numberOfRecords {
    return [_keys count];
}

#pragma mark - 

- (id <DBResultSet>)resultSetForRecordsAtIndexes:(NSIndexSet *)indexes 
                                           error:(NSError *__autoreleasing *)error
{
    NSMutableArray *mutableRecords = [NSMutableArray arrayWithCapacity:[indexes count]];
    [[_connection client] command:@"MULTI"];
    for (NSString *key in [_keys objectsAtIndexes:indexes]) {
        [[_connection client] commandArgv:[NSArray arrayWithObjects:@"TYPE", key, nil]];
    }
    
    id types = [[_connection client] command:@"EXEC"];    
    [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_keys count])] enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        NSString *key = [_keys objectAtIndex:index];
        NSString *type = [types objectAtIndex:index];
        
        id record = nil;
        if ([type isEqualToString:@"string"]) {
            record = [[RedisString alloc] initWithKey:key connection:_connection];
        } else if ([type isEqualToString:@"hash"]) {
            record = [[RedisHash alloc] initWithKey:key connection:_connection];
        } else if ([type isEqualToString:@"list"]) {
            record = [[RedisList alloc] initWithKey:key connection:_connection];
        } else if ([type isEqualToString:@"set"]) {
            record = [[RedisSet alloc] initWithKey:key connection:_connection];
        } else if ([type isEqualToString:@"zset"]) {
            record = [[RedisSortedSet alloc] initWithKey:key connection:_connection];
        }
        
        if (record) {
            [mutableRecords addObject:record];
        }
    }];
        
    return [[RedisResultSet alloc] initWithRecords:mutableRecords];
}

#pragma mark -

- (id <DBResultSet>)resultSetForQuery:(NSString *)query 
                                error:(NSError *__autoreleasing *)error 
{
    return nil;
}

@end

#pragma mark -

static NSUInteger const kRedisNumberOfFields = 2;
enum {
    RedisKeyField   = 0,
    RedisValueField = 1,
} RedisFields;

@interface RedisResultSet () {
@private
    __strong NSArray *_records;
}
@end

@implementation RedisResultSet

- (id)initWithRecords:(NSArray *)records {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _records = records;
    
    return self;
}

- (NSUInteger)numberOfFields {
    return kRedisNumberOfFields;
}

- (NSString *)identifierForTableColumnAtIndex:(NSUInteger)index {
    switch (index) {
        case RedisKeyField:
            return @"key";
        case RedisValueField:
            return @"value";
        default:
            return nil;
    }
}

- (DBValueType)valueTypeForTableColumnAtIndex:(NSUInteger)index {
    return DBStringValue;
}

- (NSSortDescriptor *)sortDescriptorPrototypeForTableColumnAtIndex:(NSUInteger)index {
    return [NSSortDescriptor sortDescriptorWithKey:[self identifierForTableColumnAtIndex:index] ascending:YES selector:@selector(localizedStandardCompare:)];
}

- (NSUInteger)numberOfRecords {
    return [_records count];
}

- (NSArray *)recordsAtIndexes:(NSIndexSet *)indexes {
    return [_records objectsAtIndexes:indexes];
}

@end

#pragma mark -

@interface RedisKeyValuePair : NSObject <DBRecord> {
@private
    __strong NSString *_key;
    __strong NSString *_value;
}

@property (readonly) NSString *key;
@property (readonly) NSString *value;

- (id)initWithKey:(NSString *)key
            value:(NSString *)value;

@end

@implementation RedisKeyValuePair
@synthesize key = _key;
@synthesize value = _value;

- (id)initWithKey:(NSString *)key 
            value:(NSString *)value 
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _key = key;
    _value = value;
    
    return self;
}

@end

#pragma mark -

@interface RedisRecord () {
@protected
    __strong NSString *_key;
    __strong NSString *_value;
}

@property (readonly) NSString *key;
@property (readonly) NSString *value;
@end

@implementation RedisRecord
@synthesize key = _key;
@synthesize value = _value;

- (id)initWithKey:(NSString *)key
       connection:(RedisConnection *)connection
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _key = key;
    
    return self;
}

@end

#pragma mark -

@interface RedisHash () {
@private
    __strong NSArray *_keyValuePairs;
}
@end

@implementation RedisHash
@synthesize children = _keyValuePairs;

- (id)initWithKey:(NSString *)key
       connection:(RedisConnection *)connection
{
    self = [super initWithKey:key connection:connection];
    if (!self) {
        return nil;
    }
    
    NSArray *keysAndValues = [[ObjCHiredis redis] commandArgv:[NSArray arrayWithObjects:@"HGETALL", key, nil]];
    NSMutableArray *mutableKeyValuePairs = [NSMutableArray arrayWithCapacity:ceil([keysAndValues count] / 2)];
    NSEnumerator *enumerator = [keysAndValues objectEnumerator];
    id k = nil, v = nil;
    while ((k = [enumerator nextObject]) && (v = [enumerator nextObject])) {
        [mutableKeyValuePairs addObject:[[RedisKeyValuePair alloc] initWithKey:k value:v]];
    }
    _keyValuePairs = [NSArray arrayWithArray:mutableKeyValuePairs];
    
    return self;
}

@end

#pragma mark -

@interface RedisList () {
@private
    __strong NSArray *_keyValuePairs;
}
@end

@implementation RedisList
@synthesize children = _keyValuePairs;

- (id)initWithKey:(NSString *)key
       connection:(RedisConnection *)connection
{
    self = [super initWithKey:key connection:connection];
    if (!self) {
        return nil;
    }
    
    NSArray *values = [[ObjCHiredis redis] commandArgv:[NSArray arrayWithObjects:@"LRANGE", key, @"0", @"-1", nil]];
    
    NSMutableArray *mutableKeyValuePairs = [NSMutableArray arrayWithCapacity:[values count]];
    for (id value in values) {
        [mutableKeyValuePairs addObject:[[RedisKeyValuePair alloc] initWithKey:nil value:value]];
    }
    _keyValuePairs = [NSArray arrayWithArray:mutableKeyValuePairs];
    
    return self;
}

@end

#pragma mark -

@interface RedisSet () {
@private
    __strong NSArray *_keyValuePairs;
}
@end

@implementation RedisSet
@synthesize children = _keyValuePairs;

- (id)initWithKey:(NSString *)key
       connection:(RedisConnection *)connection
{
    self = [super initWithKey:key connection:connection];
    if (!self) {
        return nil;
    }
    
    NSArray *values = [[ObjCHiredis redis] commandArgv:[NSArray arrayWithObjects:@"SMEMBERS", key, nil]];
    
    NSMutableArray *mutableKeyValuePairs = [NSMutableArray arrayWithCapacity:[values count]];
    for (id value in values) {
        [mutableKeyValuePairs addObject:[[RedisKeyValuePair alloc] initWithKey:nil value:value]];
    }
    _keyValuePairs = [NSArray arrayWithArray:mutableKeyValuePairs];
    
    
    return self;
}

@end

#pragma mark -

@interface RedisSortedSet () {
@private
    __strong NSArray *_keyValuePairs;
}
@end

@implementation RedisSortedSet
@synthesize children = _keyValuePairs;

- (id)initWithKey:(NSString *)key
       connection:(RedisConnection *)connection
{
    self = [super initWithKey:key connection:connection];
    if (!self) {
        return nil;
    }
    
    NSArray *valuesAndCounts = [[ObjCHiredis redis] commandArgv:[NSArray arrayWithObjects:@"ZREVRANGE", key, @"0", @"-1", @"WITHSCORES", nil]];
    NSMutableArray *mutableKeyValuePairs = [NSMutableArray arrayWithCapacity:ceil([valuesAndCounts count] / 2)];
    NSEnumerator *enumerator = [valuesAndCounts objectEnumerator];
    id value = nil, count = nil;
    while ((value = [enumerator nextObject])) {
        count = [NSNumber numberWithInteger:[[enumerator nextObject] integerValue]];
        [mutableKeyValuePairs addObject:[[RedisKeyValuePair alloc] initWithKey:count value:value]];
    }
    
    _keyValuePairs = [NSArray arrayWithArray:mutableKeyValuePairs];
    
    return self;
}

@end


#pragma mark -

@implementation RedisString

- (id)initWithKey:(NSString *)key
       connection:(RedisConnection *)connection
{
    self = [super initWithKey:key connection:connection];
    if (!self) {
        return nil;
    }
    
    _value = [connection.client commandArgv:[NSArray arrayWithObjects:@"GET", _key, nil]];
    
    return self;
}

@end
