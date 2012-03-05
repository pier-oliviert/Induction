//
//  DBConnectionConfigurationViewController.m
//  Kirin
//
//  Created by Mattt Thompson on 12/01/26.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import "DBConnectionConfigurationViewController.h"

static NSString * DBURLStringFromComponents(NSString *scheme, NSString *host, NSString *user, NSString *password, NSNumber *port, NSString *database) {
    NSMutableString *mutableURLString = [NSMutableString stringWithFormat:@"%@://", scheme];
    if (user && [user length] > 0) {
        [mutableURLString appendFormat:@"%@", user];
        if (password && [password length] > 0) {
            [mutableURLString appendFormat:@":%@", password];
        }
        [mutableURLString appendString:@"@"];
    }
    
    if (host && [host length] > 0) {
        [mutableURLString appendString:host];
    }
    
    if (port && [port integerValue] > 0) {
        [mutableURLString appendFormat:@":%d", [port integerValue]];
    }
    
    if (database && [database length] > 0) {
        [mutableURLString appendFormat:@"%@", database];
    }
    
    return [NSString stringWithString:mutableURLString];
}

#pragma mark -

@interface DBDatabaseParameterFormatter : NSFormatter
@end

@implementation DBDatabaseParameterFormatter

- (NSString *)stringForObjectValue:(id)obj {
    if (![obj isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    return obj;
}

- (BOOL)getObjectValue:(__autoreleasing id *)obj forString:(NSString *)string errorDescription:(NSString *__autoreleasing *)error {
    if(obj) {
        *obj = string;
    }
    
    return YES;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString *__autoreleasing *)newString errorDescription:(NSString *__autoreleasing *)error {
    static NSCharacterSet *_illegalDatabaseParameterCharacterSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _illegalDatabaseParameterCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" ,:;@!#$%&'()[]{}\"\\/|"];
    });
    
    return [partialString rangeOfCharacterFromSet:_illegalDatabaseParameterCharacterSet].location == NSNotFound;
}

@end

#pragma mark -

@interface DBRemovePasswordURLValueTransformer : NSValueTransformer
@end

@implementation DBRemovePasswordURLValueTransformer

+ (Class)transformedValueClass {
    return [NSURL class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if (!value) {
        return nil;
    }
    
    NSURL *url = (NSURL *)value;
    
    return [NSURL URLWithString:DBURLStringFromComponents([url scheme], [url host], [url user], nil, [url port], [url path])];
}

@end

#pragma mark -

@interface DBConnectionConfigurationViewController ()
- (void)bindURLParameterTextField:(NSTextField *)textField;
@end

@implementation DBConnectionConfigurationViewController
@synthesize delegate = _delegate;
@synthesize connectionURL = _connectionURL;
@synthesize URLField = _URLField;
@synthesize schemePopupButton = _schemePopupButton;
@synthesize hostnameField = _hostnameField;
@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;
@synthesize portField = _portField;
@synthesize databaseField = _databaseField;

- (void)awakeFromNib {
    for (NSTextField *field in [NSArray arrayWithObjects:self.URLField, self.hostnameField, self.usernameField, self.passwordField, self.portField, self.databaseField, nil]) {
        [self bindURLParameterTextField:field];
    }
    
    for (NSString *path in [[NSBundle mainBundle] pathsForResourcesOfType:@"bundle" inDirectory:@"../PlugIns/Adapters"]) {
        NSBundle *bundle = [NSBundle bundleWithPath:path];
        [bundle loadAndReturnError:nil];
        
        if ([[bundle principalClass] conformsToProtocol:@protocol(DBAdapter)]) {
            [self.schemePopupButton addItemWithTitle:[[bundle principalClass] primaryURLScheme]];
        }
    }
    
    self.hostnameField.formatter = [[DBDatabaseParameterFormatter alloc] init];
    self.usernameField.formatter = [[DBDatabaseParameterFormatter alloc] init];
}

- (void)bindURLParameterTextField:(NSTextField *)textField {
    if ([textField isEqual:self.URLField]) {
        [textField bind:@"objectValue" toObject:self withKeyPath:@"connectionURL" options:[NSDictionary dictionaryWithObject:NSStringFromClass([DBRemovePasswordURLValueTransformer class]) forKey:NSValueTransformerNameBindingOption]];
    } else if ([textField isEqual:self.hostnameField]) {
        [textField bind:@"objectValue" toObject:self withKeyPath:@"connectionURL.host" options:nil];
    } else if ([textField isEqual:self.usernameField]) {
        [textField bind:@"objectValue" toObject:self withKeyPath:@"connectionURL.user" options:nil];
    } else if ([textField isEqual:self.passwordField]) {
        [textField bind:@"objectValue" toObject:self withKeyPath:@"connectionURL.password" options:nil];
    } else if ([textField isEqual:self.portField]) {
        [textField bind:@"objectValue" toObject:self withKeyPath:@"connectionURL.port" options:nil];
    } else if ([textField isEqual:self.databaseField]) {
        [textField bind:@"objectValue" toObject:self withKeyPath:@"connectionURL.path" options:nil];
    }
}

#pragma mark - IBAction

- (void)connect:(id)sender {
    id <DBConnection> connection = nil;
    NSLog(@"URL: %@", self.connectionURL);
    
    if ([[self.connectionURL host] length] == 0) {
        self.connectionURL = [NSURL URLWithString:@"postgres://localhost"];
    }
    
    for (NSString *path in [[NSBundle mainBundle] pathsForResourcesOfType:@"bundle" inDirectory:@"../PlugIns/Adapters"]) {
        NSBundle *bundle = [NSBundle bundleWithPath:path];
        [bundle loadAndReturnError:nil];
        
        if ([[bundle principalClass] conformsToProtocol:@protocol(DBAdapter)]) {
            if ([[bundle principalClass] canConnectWithURL:self.connectionURL]) {
                connection = [[bundle principalClass] connectionWithURL:self.connectionURL error:nil];
            }
        }
    }
    
    if (connection) {
        [connection open];
        [self.delegate connectionConfigurationControllerDidConnectWithConnection:connection];
    }
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidBeginEditing:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    [textField unbind:@"objectValue"];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    
    if ([textField isEqual:self.URLField]) {
        NSURL *url = [NSURL URLWithString:[self.URLField stringValue]];
        
        NSString *scheme = [url scheme];
        if (!scheme) {
            scheme = [[self.schemePopupButton selectedCell] title];
        }
        
        NSString *password = [url password];
        if (!password) {
            password = [self.passwordField objectValue];
        }
        
        self.connectionURL = [NSURL URLWithString:DBURLStringFromComponents(scheme, [url host], [url user], password, [url port], [url path])];
    } else {
        self.connectionURL = [NSURL URLWithString:DBURLStringFromComponents([[self.schemePopupButton selectedCell] title], [self.hostnameField stringValue], [self.usernameField stringValue], [self.passwordField stringValue], [NSNumber numberWithInteger:[self.portField integerValue]], [self.databaseField stringValue])];
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    
    if ([textField isEqual:self.URLField]) {
        NSURL *url = [NSURL URLWithString:[self.URLField stringValue]];
        self.connectionURL = [NSURL URLWithString:DBURLStringFromComponents([[self.schemePopupButton selectedCell] title], [self.hostnameField stringValue], [self.usernameField stringValue], [self.passwordField stringValue], [NSNumber numberWithInteger:[self.portField integerValue]], [self.databaseField stringValue])];
        
        if ([[url scheme] isEqualToString:@"postgres"]) {
            [[self.portField cell] setPlaceholderString:@"5432"];
        } else if ([[url scheme] isEqualToString:@"mysql"]) {
            [[self.portField cell] setPlaceholderString:@"3306"];
        }
    }
    
    [self bindURLParameterTextField:textField];
}


@end
