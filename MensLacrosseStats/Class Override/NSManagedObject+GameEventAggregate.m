//
//  NSManagedObject+GameEventAggregate.m
//  LAXStats
//
//  Created by Jim Dabrowski on 2/17/12.
//  Copyright (c) 2012 Intangible Software. All rights reserved.
//

#import "NSManagedObject+GameEventAggregate.h"

@implementation NSManagedObject (GameEventAggregate)

+ (NSNumber *)aggregateOperation:(NSString *)function 
                    onAttribute:(NSString *)attributeName 
                  withPredicate:(NSPredicate *)predicate 
         inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSExpression *ex = [NSExpression expressionForFunction:function 
                                                 arguments:[NSArray arrayWithObject:[NSExpression expressionForKeyPath:attributeName]]];
    
    NSExpressionDescription *ed = [[NSExpressionDescription alloc] init];
    [ed setName:@"result"];
    [ed setExpression:ex];
    [ed setExpressionResultType:NSInteger64AttributeType];
    
    NSArray *properties = [NSArray arrayWithObject:ed];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setPropertiesToFetch:properties];
    [request setResultType:NSDictionaryResultType];
    [request setIncludesPendingChanges:YES];
    
    if (predicate != nil)
        [request setPredicate:predicate];
    
    if (context) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([self class])
                                                  inManagedObjectContext:context];
        [request setEntity:entity];
        
        NSArray *results = [context executeFetchRequest:request error:nil];
        NSDictionary *resultsDictionary = [results firstObject];
        NSNumber *resultValue = [resultsDictionary objectForKey:@"result"];
        return resultValue;
    }
    return nil;
}

@end
