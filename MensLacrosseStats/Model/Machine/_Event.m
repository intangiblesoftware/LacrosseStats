// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.m instead.

#import "_Event.h"

@implementation EventID
@end

@implementation _Event

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Event";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Event" inManagedObjectContext:moc_];
}

- (EventID*)objectID {
	return (EventID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"categoryCodeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"categoryCode"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"eventCodeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"eventCode"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"isDefalutValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isDefalut"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"statCategoryValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"statCategory"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic categoryCode;

- (int16_t)categoryCodeValue {
	NSNumber *result = [self categoryCode];
	return [result shortValue];
}

- (void)setCategoryCodeValue:(int16_t)value_ {
	[self setCategoryCode:@(value_)];
}

- (int16_t)primitiveCategoryCodeValue {
	NSNumber *result = [self primitiveCategoryCode];
	return [result shortValue];
}

- (void)setPrimitiveCategoryCodeValue:(int16_t)value_ {
	[self setPrimitiveCategoryCode:@(value_)];
}

@dynamic eventCode;

- (int16_t)eventCodeValue {
	NSNumber *result = [self eventCode];
	return [result shortValue];
}

- (void)setEventCodeValue:(int16_t)value_ {
	[self setEventCode:@(value_)];
}

- (int16_t)primitiveEventCodeValue {
	NSNumber *result = [self primitiveEventCode];
	return [result shortValue];
}

- (void)setPrimitiveEventCodeValue:(int16_t)value_ {
	[self setPrimitiveEventCode:@(value_)];
}

@dynamic isDefalut;

- (BOOL)isDefalutValue {
	NSNumber *result = [self isDefalut];
	return [result boolValue];
}

- (void)setIsDefalutValue:(BOOL)value_ {
	[self setIsDefalut:@(value_)];
}

- (BOOL)primitiveIsDefalutValue {
	NSNumber *result = [self primitiveIsDefalut];
	return [result boolValue];
}

- (void)setPrimitiveIsDefalutValue:(BOOL)value_ {
	[self setPrimitiveIsDefalut:@(value_)];
}

@dynamic statCategory;

- (int16_t)statCategoryValue {
	NSNumber *result = [self statCategory];
	return [result shortValue];
}

- (void)setStatCategoryValue:(int16_t)value_ {
	[self setStatCategory:@(value_)];
}

- (int16_t)primitiveStatCategoryValue {
	NSNumber *result = [self primitiveStatCategory];
	return [result shortValue];
}

- (void)setPrimitiveStatCategoryValue:(int16_t)value_ {
	[self setPrimitiveStatCategory:@(value_)];
}

@dynamic title;

@dynamic category;

@dynamic gameEvents;

- (NSMutableSet<GameEvent*>*)gameEventsSet {
	[self willAccessValueForKey:@"gameEvents"];

	NSMutableSet<GameEvent*> *result = (NSMutableSet<GameEvent*>*)[self mutableSetValueForKey:@"gameEvents"];

	[self didAccessValueForKey:@"gameEvents"];
	return result;
}

@dynamic games;

- (NSMutableSet<Game*>*)gamesSet {
	[self willAccessValueForKey:@"games"];

	NSMutableSet<Game*> *result = (NSMutableSet<Game*>*)[self mutableSetValueForKey:@"games"];

	[self didAccessValueForKey:@"games"];
	return result;
}

+ (NSArray*)fetchDefaultEvents:(NSManagedObjectContext*)moc_ {
	NSError *error = nil;
	NSArray *result = [self fetchDefaultEvents:moc_ error:&error];
	if (error) {
#ifdef NSAppKitVersionNumber10_0
		[NSApp presentError:error];
#else
		NSLog(@"error: %@", error);
#endif
	}
	return result;
}
+ (NSArray*)fetchDefaultEvents:(NSManagedObjectContext*)moc_ error:(NSError**)error_ {
	NSParameterAssert(moc_);
	NSError *error = nil;

	NSManagedObjectModel *model = [[moc_ persistentStoreCoordinator] managedObjectModel];

	NSDictionary *substitutionVariables = @{};

	NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"DefaultEvents"
													 substitutionVariables:substitutionVariables];
	NSAssert(fetchRequest, @"Can't find fetch request named \"DefaultEvents\".");

	NSArray *result = [moc_ executeFetchRequest:fetchRequest error:&error];
	if (error_) *error_ = error;
	return result;
}

@end

@implementation EventAttributes 
+ (NSString *)categoryCode {
	return @"categoryCode";
}
+ (NSString *)eventCode {
	return @"eventCode";
}
+ (NSString *)isDefalut {
	return @"isDefalut";
}
+ (NSString *)statCategory {
	return @"statCategory";
}
+ (NSString *)title {
	return @"title";
}
@end

@implementation EventRelationships 
+ (NSString *)category {
	return @"category";
}
+ (NSString *)gameEvents {
	return @"gameEvents";
}
+ (NSString *)games {
	return @"games";
}
@end

