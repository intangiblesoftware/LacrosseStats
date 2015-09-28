// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Game.m instead.

#import "_Game.h"

const struct GameAttributes GameAttributes = {
	.gameDateTime = @"gameDateTime",
	.homeScore = @"homeScore",
	.homeTeam = @"homeTeam",
	.location = @"location",
	.playersInGame = @"playersInGame",
	.statsToCollect = @"statsToCollect",
	.teamWatching = @"teamWatching",
	.visitingTeam = @"visitingTeam",
	.visitorScore = @"visitorScore",
};

const struct GameRelationships GameRelationships = {
	.events = @"events",
};

@implementation GameID
@end

@implementation _Game

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Game" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Game";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Game" inManagedObjectContext:moc_];
}

- (GameID*)objectID {
	return (GameID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"homeScoreValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"homeScore"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"visitorScoreValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"visitorScore"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic gameDateTime;

@dynamic homeScore;

- (int16_t)homeScoreValue {
	NSNumber *result = [self homeScore];
	return [result shortValue];
}

- (void)setHomeScoreValue:(int16_t)value_ {
	[self setHomeScore:@(value_)];
}

- (int16_t)primitiveHomeScoreValue {
	NSNumber *result = [self primitiveHomeScore];
	return [result shortValue];
}

- (void)setPrimitiveHomeScoreValue:(int16_t)value_ {
	[self setPrimitiveHomeScore:@(value_)];
}

@dynamic homeTeam;

@dynamic location;

@dynamic playersInGame;

@dynamic statsToCollect;

@dynamic teamWatching;

@dynamic visitingTeam;

@dynamic visitorScore;

- (int16_t)visitorScoreValue {
	NSNumber *result = [self visitorScore];
	return [result shortValue];
}

- (void)setVisitorScoreValue:(int16_t)value_ {
	[self setVisitorScore:@(value_)];
}

- (int16_t)primitiveVisitorScoreValue {
	NSNumber *result = [self primitiveVisitorScore];
	return [result shortValue];
}

- (void)setPrimitiveVisitorScoreValue:(int16_t)value_ {
	[self setPrimitiveVisitorScore:@(value_)];
}

@dynamic events;

- (NSMutableSet*)eventsSet {
	[self willAccessValueForKey:@"events"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"events"];

	[self didAccessValueForKey:@"events"];
	return result;
}

@end

