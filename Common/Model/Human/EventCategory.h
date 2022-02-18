#import "_EventCategory.h"

#import "LacrosseStatsEnum.h"

@interface EventCategory : _EventCategory {}

+ (EventCategory*)categoryForCode:(INSOCategoryCode)code inManagedObjectContext:(NSManagedObjectContext *)moc;

@end
