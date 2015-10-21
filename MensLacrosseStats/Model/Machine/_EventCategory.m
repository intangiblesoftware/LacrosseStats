// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EventCategory.m instead.

#import "_EventCategory.h"

const struct EventCategoryAttributes EventCategoryAttributes = {
	.categoryCode = @"categoryCode",
	.title = @"title",
};

const struct EventCategoryRelationships EventCategoryRelationships = {
	.events = @"events",
};

@implementation EventCategoryID
@end

@implementation _EventCategory

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
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

- (NSMutableSet*)eventsSet {
	[self willAccessValueForKey:@"events"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"events"];

	[self didAccessValueForKey:@"events"];
	return result;
}

@end

