#import "RosterPlayer.h"

const NSInteger INSOTeamWatchingPlayerNumber = -1;
const NSInteger INSOOtherTeamPlayerNumber = -2; 

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
