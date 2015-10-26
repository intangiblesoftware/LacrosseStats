#import "_Event.h"

#import "INSOMensLacrosseStatsEnum.h"

@interface Event : _Event {}

+ (Event*)eventForCode:(INSOEventCode)code inManagedObjectContext:(NSManagedObjectContext *)moc;

@end
