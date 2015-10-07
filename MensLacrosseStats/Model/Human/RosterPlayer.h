#import "_RosterPlayer.h"

@interface RosterPlayer : _RosterPlayer {}
// Custom logic goes here.
+ (RosterPlayer*)rosterPlayerWithNumber:(NSNumber*)number inManagedObjectContext:(NSManagedObjectContext*)moc; 

@end
