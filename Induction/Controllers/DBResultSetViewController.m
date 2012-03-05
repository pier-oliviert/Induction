//
//  DBDataSourceTableViewController.m
//  Kirin
//
//  Created by Mattt Thompson on 12/02/15.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import "DBResultSetViewController.h"

#import "DateCell.h"

@interface NSOutlineView (Convenience)
- (void)replaceOutlineTableColumnWithTableColumn:(NSTableColumn *)tableColumn;
@end

@implementation NSOutlineView (Convenience)

- (void)replaceOutlineTableColumnWithTableColumn:(NSTableColumn *)tableColumn {
    NSTableColumn *outlineTableColumn = [self outlineTableColumn];
    [self setOutlineTableColumn:tableColumn];
    [self removeTableColumn:outlineTableColumn];
}

@end

@interface DBResultSetViewController () {
@private
    __strong NSArray *_records;
}
@end

@implementation DBResultSetViewController
@synthesize outlineView = _outlineView;

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    if (!representedObject) {
        _records = [NSArray array];
        [self.outlineView reloadData];
        
        return;
    }
    
    NSArray *tableColumns = [[self.outlineView tableColumns] mutableCopy];
    for (NSTableColumn *tableColumn in tableColumns) {
        if (![tableColumn isEqual:[self.outlineView outlineTableColumn]]) {
            [self.outlineView removeTableColumn:tableColumn];
        }
    }
    
    NSIndexSet *columnIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.representedObject numberOfFields])];
    [columnIndexSet enumerateIndexesUsingBlock:^(NSUInteger columnIndex, BOOL *stop) {
        NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:[(id <DBResultSet>)self.representedObject identifierForTableColumnAtIndex:columnIndex]];
        [[tableColumn headerCell] setTitle:[tableColumn identifier]];
        [tableColumn setEditable:NO];

        if ([(id <DBResultSet>)self.representedObject respondsToSelector:@selector(valueTypeForTableColumnAtIndex:)]) {
            DBValueType type = [(id <DBResultSet>)self.representedObject valueTypeForTableColumnAtIndex:columnIndex];
            if (type != DBStringValue) {
                switch (type) {
                    case DBBooleanValue: {
                        NSButtonCell *buttonCell = [[NSButtonCell alloc] init];
                        [buttonCell setButtonType:NSSwitchButton];
                        [buttonCell setAllowsMixedState:NO];
                        [buttonCell setTitle:nil];
                        [buttonCell setImagePosition:NSImageOnly];
                        [tableColumn setDataCell:buttonCell]; 
                        break;
                    }
                    case DBDecimalValue:
                    case DBIntegerValue:
                        [[[tableColumn dataCell] formatter] setNumberStyle:NSNumberFormatterDecimalStyle];
                        break;
                    case DBDateValue: {
                        DateCell *dateCell = [[DateCell alloc] init];
                        [tableColumn setDataCell:dateCell];
                        break;
                    }
                    default:
                        break;
                }
            }
        }
        
        if ([(id <DBResultSet>)self.representedObject respondsToSelector:@selector(sortDescriptorPrototypeForTableColumnAtIndex:)]) {
            [tableColumn setSortDescriptorPrototype:[(id <DBResultSet>)self.representedObject sortDescriptorPrototypeForTableColumnAtIndex:columnIndex]];
        }
        
        [self.outlineView addTableColumn:tableColumn];
        
        if (columnIndex == 0) {
            [self.outlineView replaceOutlineTableColumnWithTableColumn:tableColumn];
        }
    }];
    
    
    _records = [(id <DBResultSet>)self.representedObject recordsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [(id <DBResultSet>)self.representedObject numberOfRecords])]];
    [self.outlineView setSortDescriptors:[NSArray arrayWithObject:[[self.outlineView outlineTableColumn] sortDescriptorPrototype]]];
    [self.outlineView reloadData];
}

#pragma mark - NSOutlineViewDataSource

- (id)outlineView:(NSOutlineView *)outlineView 
            child:(NSInteger)index 
           ofItem:(id)item
{
    if (!item) {
        return [_records objectAtIndex:index];
    } else {
        return [[(id <DBRecord>)item children] objectAtIndex:index];
    }
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView 
  numberOfChildrenOfItem:(id)item 
{
    if (!item) {
        return [_records count];
    } else {
        if ([item respondsToSelector:@selector(children)]) {
            return [[(id <DBRecord>)item children] count];
        } else {
            return 0;
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView 
   isItemExpandable:(id)item 
{
    return [self outlineView:outlineView numberOfChildrenOfItem:item] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
           byItem:(id)item
{
    if (![tableColumn identifier]) {
        return nil;
    }
    
    return [(id <DBRecord>)item valueForKey:[tableColumn identifier]];
}

#pragma mark - NSOutlineViewController

- (void)outlineView:(NSOutlineView *)outlineView 
sortDescriptorsDidChange:(NSArray *)oldDescriptors 
{
    _records = [_records sortedArrayUsingDescriptors:outlineView.sortDescriptors];
    [self.outlineView reloadData];
}

@end
