//
//  NSManagedObject+GameEventAggregate.h
//  LAXStats
//
//  Created by Jim Dabrowski on 2/17/12.
//  Copyright (c) 2012 Intangible Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (GameEventAggregate)
+ (NSNumber *)aggregateOperation:(NSString *)function 
                    onAttribute:(NSString *)attributeName 
                  withPredicate:(NSPredicate *)predicate 
         inManagedObjectContext:(NSManagedObjectContext *)context;
@end
