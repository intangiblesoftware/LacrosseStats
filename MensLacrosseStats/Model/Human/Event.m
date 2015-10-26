#import "Event.h"

@interface Event ()

// Private interface goes here.

@end

@implementation Event

// Custom logic goes here.
+ (Event*)eventForCode:(INSOEventCode)code inManagedObjectContext:(NSManagedObjectContext *)moc
{
    Event* matchingEvent = nil;
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:[Event entityName]];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"eventCode == %@", @(code)];
    request.predicate = predicate;
    
    NSError* error = nil;
    NSArray* eventsMatching = [moc executeFetchRequest:request error:&error];
    
    if ([eventsMatching count] > 0) {
        // We had some events that matched the code, so grab one and return it
        matchingEvent = [eventsMatching firstObject];
    }
    
    return  matchingEvent;
}


@end
