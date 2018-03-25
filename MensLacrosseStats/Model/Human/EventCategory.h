#import "_EventCategory.h"

#import "INSOMensLacrosseStatsEnum.h"

@interface EventCategory : _EventCategory {}

+ (EventCategory*)categoryForCode:(INSOCategoryCode)code inManagedObjectContext:(NSManagedObjectContext *)moc;

@end
