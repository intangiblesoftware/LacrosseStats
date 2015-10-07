// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GameEvent.m instead.

#import "_GameEvent.h"

const struct GameEventAttributes GameEventAttributes = {
	.categoryCode = @"categoryCode",
	.categoryTitle = @"categoryTitle",
	.eventCode = @"eventCode",
	.eventTitle = @"eventTitle",
	.isExtraManGoal = @"isExtraManGoal",
	.penaltyDuration = @"penaltyDuration",
	.penaltyTime = @"penaltyTime",
	.playerNumber = @"playerNumber",
	.timestamp = @"timestamp",
};

const struct GameEventRelationships GameEventRelationships = {
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
	if ([key isEqualToString:@"playerNumberValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"playerNumber"];
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

@dynamic categoryTitle;

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

@dynamic eventTitle;

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

@dynamic playerNumber;

- (int16_t)playerNumberValue {
	NSNumber *result = [self playerNumber];
	return [result shortValue];
}

- (void)setPlayerNumberValue:(int16_t)value_ {
	[self setPlayerNumber:@(value_)];
}

- (int16_t)primitivePlayerNumberValue {
	NSNumber *result = [self primitivePlayerNumber];
	return [result shortValue];
}

- (void)setPrimitivePlayerNumberValue:(int16_t)value_ {
	[self setPrimitivePlayerNumber:@(value_)];
}

@dynamic timestamp;

@dynamic game;

@dynamic player;

@end

