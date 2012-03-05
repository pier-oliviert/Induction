//
//  PostgreSQL.m
//  NoSQL
//
//  Created by Mattt Thompson on 12/01/24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PostgreSQLAdapter.h"
#import "libpq-fe.h"

#ifndef INT8OID
    #define INVALID_OID     (-1)
    #define INT8OID         20
    #define INT2OID         21
    #define INT4OID         23
    #define	BOOLOID         16
    #define FLOAT4OID       700
    #define FLOAT8OID       701
    #define VARCHAROID      1043
    #define	TEXTOID         25
    #define DATEOID         1082
    #define TIMEOID         1083
    #define TIMESTAMPOID    1114
    #define TIMESTAMPTZOID  1184
#endif

NSString * const PostgreSQLErrorDomain = @"com.heroku.client.postgresql.error";

static NSString * PostgreSQLConnectionStringFromURL(NSURL *url) {
    NSMutableString *connectionString = [NSMutableString stringWithString:@""];
    if ([url host]) {
        [connectionString appendFormat:@"host='%@' ", [url host]];
    }
    
    if ([url port]) {
        [connectionString appendFormat:@"port='%@' ", [url port]];
    }
    
    if ([url user]) {
        [connectionString appendFormat:@"user='%@' ", [url user]];
    }
    
    if ([url password]) {
        [connectionString appendFormat:@"password='%@' ", [url password]];
    }
    
    if (![[url lastPathComponent] isEqual:@"/"]) {
        [connectionString appendFormat:@"dbname='%@' ", [[url lastPathComponent] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
    
    return connectionString;
}

static NSDate * NSDateFromPostgreSQLTimestamp(NSString *timestamp) {
    static NSDateFormatter *_postgresDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _postgresDateFormatter = [[NSDateFormatter alloc] init];
        [_postgresDateFormatter setDateFormat:@"yyyy'-'MM'-'dd HH':'mm':'ssZZ"];
    });
    
    if ([timestamp rangeOfString:@"."].location != NSNotFound) {
        timestamp = [NSString stringWithFormat:@"%@ +0000", [timestamp substringToIndex:[timestamp rangeOfString:@"."].location]];
    } else {
        timestamp = [NSString stringWithFormat:@"%@ +0000", timestamp];
    }
    
    return [_postgresDateFormatter dateFromString:timestamp];
}

#pragma mark -

@implementation PostgreSQLAdapter

+ (NSString *)primaryURLScheme {
    return @"postgres";
}

+ (BOOL)canConnectWithURL:(NSURL *)url {
    return [[url scheme] isEqualToString:@"postgres"];
}

+ (id <DBConnection>)connectionWithURL:(NSURL *)url 
                                 error:(NSError **)error
{
    return [[PostgreSQLConnection alloc] initWithURL:url];
}

@end

@interface PostgreSQLConnection () {
@private
    void *_pgconn;
    __strong NSURL *_url;
}

@end

@implementation PostgreSQLConnection
@synthesize url = _url;
@dynamic databases;

- (void)dealloc {
    if (_pgconn) {
        PQfinish(_pgconn);
        _pgconn = NULL;
    }    
}

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _url = url;
    
    return self;
}

- (BOOL)open {
	[self close];
    
	_pgconn = (PGconn *)PQconnectdb([PostgreSQLConnectionStringFromURL(_url) cStringUsingEncoding:NSUTF8StringEncoding]);
    
	if (PQstatus(_pgconn) == CONNECTION_BAD)  {
        NSLog(@"Connection bad: %s", PQerrorMessage(_pgconn));
        //		errorDescription = [NSString stringWithFormat:@"%s", PQerrorMessage(_pgconn)];
        //		[errorDescription retain];
        //        
        //		NSLog(@"Connection to database '%@' failed.", dbName);
        //		NSLog(@"\t%@", errorDescription);
        //		[self appendSQLLog:[NSString stringWithFormat:@"Connection to database %@ Failed.\n", dbName]]; 
        //		[self appendSQLLog:[NSString stringWithFormat:@"Connection string: %@\n\n", connectionString]]; 
        //		// append error too??
        //        
        //		PQfinish(_pgconn);
        //		_pgconn = nil;
        //		isConnected = NO;
        
		return NO;
    }
	
    //	// set up notification
    //	PQsetNoticeProcessor(_pgconn, handle_pq_notice, self);
	
    //	if (sqlLog != nil) {
    //		[sqlLog release];
    //	}
    //	sqlLog = [[NSMutableString alloc] init];
    //	[self appendSQLLog:[NSString stringWithFormat:@"Connected to database %@.\n", dbName]];
    //	isConnected = YES;
	return YES;
}

- (BOOL)close {
    //	if (_pgconn == nil) { return NO; }
    //	if (isConnected == NO) { return NO; }
    //	
    //	[self appendSQLLog:[NSString stringWithString:@"Disconnected from database.\n"]];
	PQfinish(_pgconn);
    //	_pgconn = nil;
    //	isConnected = NO;
	return YES;
}

- (BOOL)reset {
    PQreset(_pgconn);
    return PQstatus(_pgconn) == CONNECTION_OK;
}

- (id <SQLResultSet>)executeSQL:(NSString *)SQL 
                          error:(NSError *__autoreleasing *)error 
{
    PGresult *pgresult = PQexec(_pgconn, [SQL cStringUsingEncoding:NSUTF8StringEncoding]);
    
    return [[PostgreSQLResultSet alloc] initWithPGResult:pgresult];
}


- (NSArray *)databases {
    NSMutableArray *mutableDatabases = [[NSMutableArray alloc] init];
    [[[self executeSQL:@"SELECT * FROM pg_database ORDER BY datname ASC" error:nil] tuples] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PostgreSQLDatabase *database = [[PostgreSQLDatabase alloc] initWithConnection:self name:[(id <SQLTuple>)obj valueForKey:@"datname"] stringEncoding:NSUTF8StringEncoding];
        [mutableDatabases addObject:database];
    }];
    
    return mutableDatabases;
}

@end

#pragma mark -

@interface PostgreSQLDatabase () {
@private
    __strong PostgreSQLConnection *_connection;
    __strong NSString *_name;
    __strong NSArray *_tables;
    NSStringEncoding _stringEncoding;
}
@end

@implementation PostgreSQLDatabase
@synthesize connection = _connection;
@synthesize name = _name;
@synthesize stringEncoding = _stringEncoding;
@synthesize tables = _tables;

- (id)initWithConnection:(PostgreSQLConnection *)connection 
                    name:(NSString *)name
          stringEncoding:(NSStringEncoding)stringEncoding
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _connection = connection;
    _name = name;
    _stringEncoding = stringEncoding;
    
    NSString *SQL = [NSString stringWithFormat:@"SELECT * FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name ASC"];
    NSMutableArray *mutableTables = [NSMutableArray array];
    
    [[[_connection executeSQL:SQL error:nil] tuples] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PostgreSQLTable *table = [[PostgreSQLTable alloc] initWithDatabase:self name:[(id <SQLTuple>)obj valueForKey:@"table_name"] stringEncoding:NSUTF8StringEncoding];
        [mutableTables addObject:table];
    }];
    
    _tables = [NSArray arrayWithArray:mutableTables];

    return self;
}

- (NSString *)description {
    return _name;
}

- (NSOrderedSet *)dataSourceGroupNames {
    return [NSOrderedSet orderedSetWithObject:NSLocalizedString(@"Tables", nil)];
}

- (NSArray *)dataSourcesForGroupNamed:(NSString *)groupName {
    if ([groupName isEqualToString:NSLocalizedString(@"Tables", nil)]) {
        return self.tables;
    } else {
        return nil;
    }
}

@end

#pragma mark -

@interface PostgreSQLTable () {
@private
    __strong NSString *_name;
    NSStringEncoding _stringEncoding;
    __strong id <SQLDatabase> _database;
}
@end

// TODO formalize / add default implementation of data source proxy
@implementation PostgreSQLTable
@synthesize name = _name;
@synthesize stringEncoding = _stringEncoding;

- (id)initWithDatabase:(id <SQLDatabase>)database
                  name:(NSString *)name
        stringEncoding:(NSStringEncoding)stringEncoding
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _name = name;
    
    _database = database;
    
    return self;
}

- (NSString *)description {
    return _name;
}

- (NSUInteger)numberOfRecords {
    return [[[[[[_database connection] executeSQL:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", _name] error:nil] recordsAtIndexes:[NSIndexSet indexSetWithIndex:0]] lastObject] valueForKey:@"count"] integerValue]; 
}

#pragma mark - 

- (id <DBResultSet>)resultSetForRecordsAtIndexes:(NSIndexSet *)indexes 
                                           error:(NSError *__autoreleasing *)error
{
    return [[_database connection] executeSQL:[NSString stringWithFormat:@"SELECT * FROM %@ OFFSET %d LIMIT %d ", _name, [indexes firstIndex], [indexes count]] error:nil];
}

#pragma mark -

- (id <DBResultSet>)resultSetForQuery:(NSString *)query 
                                error:(NSError *__autoreleasing *)error 
{
    return [[_database connection] executeSQL:query error:error];
}

@end

#pragma mark -

@interface PostgreSQLField () {
@private
    NSUInteger _index;
    __strong NSString *_name;
    DBValueType _type;
    NSUInteger _size;
}
@end

@implementation PostgreSQLField
@synthesize index = _index;
@synthesize name = _name;
@synthesize size = _size;
@synthesize type = _type;

+ (PostgreSQLField *)fieldInPGResult:(PGresult *)pgresult 
                             atIndex:(NSUInteger)fieldIndex 
{
    PostgreSQLField *field = [[PostgreSQLField alloc] init];
    field->_index = fieldIndex;
    
    switch (PQftype(pgresult, (int)fieldIndex)) {
        case BOOLOID:
            field->_type = DBBooleanValue;
            break;              
        case INT2OID:
        case INT4OID:
        case INT8OID:
            field->_type = DBIntegerValue;
        case FLOAT4OID:
        case FLOAT8OID:
            field->_type = DBDecimalValue;
            break;
        case DATEOID:
        case TIMEOID:
        case TIMESTAMPOID:
        case TIMESTAMPTZOID:
            field->_type = DBDateValue;
            break;    
        case VARCHAROID:
        case TEXTOID:        
        default:
            field->_type = DBStringValue;
            break;
    }
    
    field->_name = [[NSString alloc] initWithCString:PQfname(pgresult, (int)fieldIndex) encoding:NSUTF8StringEncoding];
    
    return field;
}

- (id)objectForBytes:(const char *)bytes 
              length:(NSUInteger)length 
            encoding:(NSStringEncoding)encoding 
{
    id value = nil;
    switch (_type) {
        case DBBooleanValue:
            value = [NSNumber numberWithBool:((*(char *)bytes) == 't')];
            break;
        case DBIntegerValue:
            value = [NSNumber numberWithInteger:[[[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding] integerValue]];
            break;
        case DBDecimalValue:
            value = [NSNumber numberWithDouble:[[[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding] doubleValue]];
            break;
        case DBStringValue:
            value = [[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding];
            break;
        case DBDateValue:
            value = NSDateFromPostgreSQLTimestamp([[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding]);
            break;
        default:
            break;
    }
            
    return value;
}

@end

#pragma mark -

@interface PostgreSQLTuple () {
@private
    NSUInteger _index;
    __strong NSDictionary *_valuesKeyedByFieldName;
}
@end

@implementation PostgreSQLTuple
@synthesize index = _index;

- (id)initWithValuesKeyedByFieldName:(NSDictionary *)keyedValues {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _valuesKeyedByFieldName = keyedValues;
    
    return self;
}

- (id)valueForKey:(NSString *)key {
    return [_valuesKeyedByFieldName objectForKey:key];
}

@end


#pragma mark -

@interface PostgreSQLResultSet () {
@private
    void *_pgresult;
    NSUInteger _tuplesCount;
    NSUInteger _fieldsCount;
    __strong NSArray *_fields;
    __strong NSDictionary *_fieldsKeyedByName;
    __strong NSArray *_tuples;
}

- (id)tupleValueAtIndex:(NSUInteger)tupleIndex 
          forFieldNamed:(NSString *)fieldName;

@end

@implementation PostgreSQLResultSet
@synthesize fields = _fields;
@synthesize tuples = _tuples;

- (void)dealloc {
    if (_pgresult) {
        PQclear(_pgresult);
        _pgresult = NULL;
    }    
}

- (id)initWithPGResult:(PGresult *)pgresult {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _pgresult = pgresult;
    _tuplesCount = PQntuples(pgresult);
    _fieldsCount = PQnfields(pgresult);
    
    NSMutableArray *mutableFields = [[NSMutableArray alloc] initWithCapacity:_fieldsCount];
    NSIndexSet *fieldIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,_fieldsCount)];
    [fieldIndexSet enumerateIndexesWithOptions:NSEnumerationConcurrent usingBlock:^(NSUInteger fieldIndex, BOOL *stop) {
        PostgreSQLField *field = [PostgreSQLField fieldInPGResult:pgresult atIndex:fieldIndex];
        [mutableFields addObject:field];
    }];
    _fields = mutableFields;
    
    NSMutableDictionary *mutableKeyedFields = [[NSMutableDictionary alloc] initWithCapacity:_fieldsCount];
    for (PostgreSQLField *field in _fields) {
        [mutableKeyedFields setObject:field forKey:field.name];
    }
    _fieldsKeyedByName = mutableKeyedFields;
    
    NSMutableArray *mutableTuples = [[NSMutableArray alloc] initWithCapacity:_tuplesCount];
    NSIndexSet *tupleIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _tuplesCount)];
    NSArray *fieldNames = [_fieldsKeyedByName allKeys];
    
    [tupleIndexSet enumerateIndexesWithOptions:0 usingBlock:^(NSUInteger tupleIndex, BOOL *stop) {
        NSMutableDictionary *mutableKeyedTupleValues = [[NSMutableDictionary alloc] initWithCapacity:_fieldsCount];
        [fieldNames enumerateObjectsWithOptions:0 usingBlock:^(id fieldName, NSUInteger idx, BOOL *stop) {
            id value = [self tupleValueAtIndex:tupleIndex forFieldNamed:fieldName];
            [mutableKeyedTupleValues setObject:value forKey:fieldName];
        }];
        PostgreSQLTuple *tuple = [[PostgreSQLTuple alloc] initWithValuesKeyedByFieldName:mutableKeyedTupleValues];
        [mutableTuples addObject:tuple];
    }];
    
    _tuples = mutableTuples;
    
    return self;
}

- (id)tupleValueAtIndex:(NSUInteger)tupleIndex 
          forFieldNamed:(NSString *)fieldName
{
    PostgreSQLField *field = [_fieldsKeyedByName objectForKey:fieldName];
    if (PQgetisnull(_pgresult, (int)tupleIndex, (int)field.index)) {
        return [NSNull null];
    }
    
    const char *bytes = PQgetvalue(_pgresult, (int)tupleIndex, (int)field.index);
    NSUInteger length = PQgetlength(_pgresult, (int)tupleIndex, (int)field.index);
    
    return [field objectForBytes:bytes length:length encoding:NSUTF8StringEncoding];
}

- (NSUInteger)numberOfFields {
    return _fieldsCount;
}

- (NSUInteger)numberOfRecords {
    return _tuplesCount;
}

- (NSArray *)recordsAtIndexes:(NSIndexSet *)indexes {
    return [_tuples objectsAtIndexes:indexes];
}

- (NSString *)identifierForTableColumnAtIndex:(NSUInteger)index {
    PostgreSQLField *field = [_fields objectAtIndex:index];
    return [field name];
}

- (DBValueType)valueTypeForTableColumnAtIndex:(NSUInteger)index {
    PostgreSQLField *field = [_fields objectAtIndex:index];
    return [field type];
}

- (NSSortDescriptor *)sortDescriptorPrototypeForTableColumnAtIndex:(NSUInteger)index {
    PostgreSQLField *field = [_fields objectAtIndex:index];
    if ([field type] == DBStringValue) {
        return [NSSortDescriptor sortDescriptorWithKey:[field name] ascending:YES selector:@selector(localizedStandardCompare:)];
    } else {
        return [NSSortDescriptor sortDescriptorWithKey:[field name] ascending:YES];
    }
}

@end