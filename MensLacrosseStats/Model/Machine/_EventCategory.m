// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EventCategory.m instead.

#import "_EventCategory.h"

const struct EventCategoryAttributes EventCategoryAttributes = {
	.sortOrder = @"sortOrder",
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

	if ([key isEqualToString:@"sortOrderValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"sortOrder"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic sortOrder;

- (float)sortOrderValue {
	NSNumber *result = [self sortOrder];
	return [result floatValue];
}

- (void)setSortOrderValue:(float)value_ {
	[self setSortOrder:@(value_)];
}

- (float)primitiveSortOrderValue {
	NSNumber *result = [self primitiveSortOrder];
	return [result floatValue];
}

- (void)setPrimitiveSortOrderValue:(float)value_ {
	[self setPrimitiveSortOrder:@(value_)];
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

