#import "_RosterPlayer.h"

extern const NSInteger INSOTeamPlayerNumber;

@interface RosterPlayer : _RosterPlayer {}

// Custom logic goes here.
+ (RosterPlayer*)rosterPlayerWithNumber:(NSNumber*)number inManagedObjectContext:(NSManagedObjectContext*)moc; 

@end
