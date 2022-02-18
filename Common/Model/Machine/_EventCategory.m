// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EventCategory.m instead.

#import "_EventCategory.h"

@implementation EventCategoryID
@end

@implementation _EventCategory

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EventCategory" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EventCategory";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EventCategory" inManagedObjectContext:moc_];
}

- (EventCategoryID*)objectID {
	return (EventCategoryID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"categoryCodeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"categoryCode"];
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

@dynamic title;

@dynamic events;

- (NSMutableSet<Event*>*)eventsSet {
	[self willAccessValueForKey:@"events"];

	NSMutableSet<Event*> *result = (NSMutableSet<Event*>*)[self mutableSetValueForKey:@"events"];

	[self didAccessValueForKey:@"events"];
	return result;
}

@end

@implementation EventCategoryAttributes 
+ (NSString *)categoryCode {
	return @"categoryCode";
}
+ (NSString *)title {
	return @"title";
}
@end

@implementation EventCategoryRelationships 
+ (NSString *)events {
	return @"events";
}
@end

