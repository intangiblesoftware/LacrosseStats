#import "EventCategory.h"

@interface EventCategory ()

// Private interface goes here.

@end

@implementation EventCategory

+ (EventCategory*)categoryForCode:(INSOCategoryCode)code inManagedObjectContext:(NSManagedObjectContext *)moc
{
    EventCategory* matchingCategory = nil;
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:[EventCategory entityName]];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"categoryCode == %@", @(code)];
    request.predicate = predicate;
    
    NSError* error = nil;
    NSArray* categoriesMatching = [moc executeFetchRequest:request error:&error];
    
    if ([categoriesMatching count] > 0) {
        // We had some categories that matched the code, so grab one and return it
        matchingCategory = [categoriesMatching firstObject];
    }
    
    // Returns nil if we could not find any categories
    return  matchingCategory;
}

@end
