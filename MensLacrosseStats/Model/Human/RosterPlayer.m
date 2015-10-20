#import "RosterPlayer.h"

const NSInteger INSOTeamPlayerNumber = -1;

@interface RosterPlayer ()

// Private interface goes here.

@end

@implementation RosterPlayer

// Custom logic goes here.
+ (RosterPlayer*)rosterPlayerWithNumber:(NSNumber *)number inManagedObjectContext:(NSManagedObjectContext *)moc
{
    RosterPlayer* rosterPlayer = [RosterPlayer insertInManagedObjectContext:moc];
    rosterPlayer.number = number;
    
    return rosterPlayer; 
}

@end
