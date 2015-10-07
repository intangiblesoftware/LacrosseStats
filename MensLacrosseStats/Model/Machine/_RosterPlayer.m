// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RosterPlayer.m instead.

#import "_RosterPlayer.h"

const struct RosterPlayerAttributes RosterPlayerAttributes = {
	.number = @"number",
};

const struct RosterPlayerRelationships RosterPlayerRelationships = {
	.events = @"events",
	.game = @"game",
};

@implementation RosterPlayerID
@end

@implementation _RosterPlayer

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"RosterPlayer" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"RosterPlayer";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"RosterPlayer" inManagedObjectContext:moc_];
}

- (RosterPlayerID*)objectID {
	return (RosterPlayerID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"numberValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"number"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic number;

- (int16_t)numberValue {
	NSNumber *result = [self number];
	return [result shortValue];
}

- (void)setNumberValue:(int16_t)value_ {
	[self setNumber:@(value_)];
}

- (int16_t)primitiveNumberValue {
	NSNumber *result = [self primitiveNumber];
	return [result shortValue];
}

- (void)setPrimitiveNumberValue:(int16_t)value_ {
	[self setPrimitiveNumber:@(value_)];
}

@dynamic events;

- (NSMutableSet*)eventsSet {
	[self willAccessValueForKey:@"events"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"events"];

	[self didAccessValueForKey:@"events"];
	return result;
}

@dynamic game;

@end
