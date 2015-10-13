// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GameEvent.m instead.

#import "_GameEvent.h"

const struct GameEventAttributes GameEventAttributes = {
	.isExtraManGoal = @"isExtraManGoal",
	.penaltyDuration = @"penaltyDuration",
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

	if ([key isEqualToString:@"isExtraManGoalValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isExtraManGoal"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"penaltyDurationValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"penaltyDuration"];
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

@dynamic isExtraManGoal;

- (BOOL)isExtraManGoalValue {
	NSNumber *result = [self isExtraManGoal];
	return [result boolValue];
}

- (void)setIsExtraManGoalValue:(BOOL)value_ {
	[self setIsExtraManGoal:@(value_)];
}

- (BOOL)primitiveIsExtraManGoalValue {
	NSNumber *result = [self primitiveIsExtraManGoal];
	return [result boolValue];
}

- (void)setPrimitiveIsExtraManGoalValue:(BOOL)value_ {
	[self setPrimitiveIsExtraManGoal:@(value_)];
}

@dynamic penaltyDuration;

- (int16_t)penaltyDurationValue {
	NSNumber *result = [self penaltyDuration];
	return [result shortValue];
}

- (void)setPenaltyDurationValue:(int16_t)value_ {
	[self setPenaltyDuration:@(value_)];
}

- (int16_t)primitivePenaltyDurationValue {
	NSNumber *result = [self primitivePenaltyDuration];
	return [result shortValue];
}

- (void)setPrimitivePenaltyDurationValue:(int16_t)value_ {
	[self setPrimitivePenaltyDuration:@(value_)];
}

@dynamic penaltyTime;

- (int16_t)penaltyTimeValue {
	NSNumber *result = [self penaltyTime];
	return [result shortValue];
}

- (void)setPenaltyTimeValue:(int16_t)value_ {
	[self setPenaltyTime:@(value_)];
}

- (int16_t)primitivePenaltyTimeValue {
	NSNumber *result = [self primitivePenaltyTime];
	return [result shortValue];
}

- (void)setPrimitivePenaltyTimeValue:(int16_t)value_ {
	[self setPrimitivePenaltyTime:@(value_)];
}

@dynamic timestamp;

@dynamic event;

@dynamic game;

@dynamic player;

@end

