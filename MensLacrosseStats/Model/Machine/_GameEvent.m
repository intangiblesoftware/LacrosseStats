// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GameEvent.m instead.

#import "_GameEvent.h"

const struct GameEventAttributes GameEventAttributes = {
	.is8m = @"is8m",
	.isExtraManGoal = @"isExtraManGoal",
	.penaltyTime = @"penaltyTime",
	.timestamp = @"timestamp",
};

const struct GameEventRelationships GameEventRelationships = {
	.event = @"event",
	.game = @"game",
	.player = @"player",
};

@implementation GameEventID
@end

@implementation _GameEvent

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"GameEvent" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"GameEvent";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"GameEvent" inManagedObjectContext:moc_];
}

- (GameEventID*)objectID {
	return (GameEventID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"is8mValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"is8m"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"isExtraManGoalValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isExtraManGoal"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"penaltyTimeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"penaltyTime"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic is8m;

- (BOOL)is8mValue {
	NSNumber *result = [self is8m];
	return [result boolValue];
}

- (void)setIs8mValue:(BOOL)value_ {
	[self setIs8m:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIs8mValue {
	NSNumber *result = [self primitiveIs8m];
	return [result boolValue];
}

- (void)setPrimitiveIs8mValue:(BOOL)value_ {
	[self setPrimitiveIs8m:[NSNumber numberWithBool:value_]];
}

@dynamic isExtraManGoal;

- (BOOL)isExtraManGoalValue {
	NSNumber *result = [self isExtraManGoal];
	return [result boolValue];
}

- (void)setIsExtraManGoalValue:(BOOL)value_ {
	[self setIsExtraManGoal:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIsExtraManGoalValue {
	NSNumber *result = [self primitiveIsExtraManGoal];
	return [result boolValue];
}

- (void)setPrimitiveIsExtraManGoalValue:(BOOL)value_ {
	[self setPrimitiveIsExtraManGoal:[NSNumber numberWithBool:value_]];
}

@dynamic penaltyTime;

- (int16_t)penaltyTimeValue {
	NSNumber *result = [self penaltyTime];
	return [result shortValue];
}

- (void)setPenaltyTimeValue:(int16_t)value_ {
	[self setPenaltyTime:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitivePenaltyTimeValue {
	NSNumber *result = [self primitivePenaltyTime];
	return [result shortValue];
}

- (void)setPrimitivePenaltyTimeValue:(int16_t)value_ {
	[self setPrimitivePenaltyTime:[NSNumber numberWithShort:value_]];
}

@dynamic timestamp;

@dynamic event;

@dynamic game;

@dynamic player;

@end

