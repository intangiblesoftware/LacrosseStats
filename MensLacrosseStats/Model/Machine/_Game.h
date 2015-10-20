// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Game.h instead.

@import CoreData;

extern const struct GameAttributes {
	__unsafe_unretained NSString *gameDateTime;
	__unsafe_unretained NSString *homeScore;
	__unsafe_unretained NSString *homeTeam;
	__unsafe_unretained NSString *location;
	__unsafe_unretained NSString *teamWatching;
	__unsafe_unretained NSString *visitingTeam;
	__unsafe_unretained NSString *visitorScore;
} GameAttributes;

extern const struct GameRelationships {
	__unsafe_unretained NSString *events;
	__unsafe_unretained NSString *eventsToRecord;
	__unsafe_unretained NSString *players;
} GameRelationships;

@class GameEvent;
@class Event;
@class RosterPlayer;

@interface GameID : NSManagedObjectID {}
@end

@interface _Game : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) GameID* objectID;

@property (nonatomic, strong) NSDate* gameDateTime;

//- (BOOL)validateGameDateTime:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* homeScore;

@property (atomic) int16_t homeScoreValue;
- (int16_t)homeScoreValue;
- (void)setHomeScoreValue:(int16_t)value_;

//- (BOOL)validateHomeScore:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* homeTeam;

//- (BOOL)validateHomeTeam:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* location;

//- (BOOL)validateLocation:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* teamWatching;

//- (BOOL)validateTeamWatching:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* visitingTeam;

//- (BOOL)validateVisitingTeam:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* visitorScore;

@property (atomic) int16_t visitorScoreValue;
- (int16_t)visitorScoreValue;
- (void)setVisitorScoreValue:(int16_t)value_;

//- (BOOL)validateVisitorScore:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *events;

- (NSMutableSet*)eventsSet;

@property (nonatomic, strong) NSSet *eventsToRecord;

- (NSMutableSet*)eventsToRecordSet;

@property (nonatomic, strong) NSSet *players;

- (NSMutableSet*)playersSet;

@end

@interface _Game (EventsCoreDataGeneratedAccessors)
- (void)addEvents:(NSSet*)value_;
- (void)removeEvents:(NSSet*)value_;
- (void)addEventsObject:(GameEvent*)value_;
- (void)removeEventsObject:(GameEvent*)value_;

@end

@interface _Game (EventsToRecordCoreDataGeneratedAccessors)
- (void)addEventsToRecord:(NSSet*)value_;
- (void)removeEventsToRecord:(NSSet*)value_;
- (void)addEventsToRecordObject:(Event*)value_;
- (void)removeEventsToRecordObject:(Event*)value_;

@end

@interface _Game (PlayersCoreDataGeneratedAccessors)
- (void)addPlayers:(NSSet*)value_;
- (void)removePlayers:(NSSet*)value_;
- (void)addPlayersObject:(RosterPlayer*)value_;
- (void)removePlayersObject:(RosterPlayer*)value_;

@end

@interface _Game (CoreDataGeneratedPrimitiveAccessors)

- (NSDate*)primitiveGameDateTime;
- (void)setPrimitiveGameDateTime:(NSDate*)value;

- (NSNumber*)primitiveHomeScore;
- (void)setPrimitiveHomeScore:(NSNumber*)value;

- (int16_t)primitiveHomeScoreValue;
- (void)setPrimitiveHomeScoreValue:(int16_t)value_;

- (NSString*)primitiveHomeTeam;
- (void)setPrimitiveHomeTeam:(NSString*)value;

- (NSString*)primitiveLocation;
- (void)setPrimitiveLocation:(NSString*)value;

- (NSString*)primitiveTeamWatching;
- (void)setPrimitiveTeamWatching:(NSString*)value;

- (NSString*)primitiveVisitingTeam;
- (void)setPrimitiveVisitingTeam:(NSString*)value;

- (NSNumber*)primitiveVisitorScore;
- (void)setPrimitiveVisitorScore:(NSNumber*)value;

- (int16_t)primitiveVisitorScoreValue;
- (void)setPrimitiveVisitorScoreValue:(int16_t)value_;

- (NSMutableSet*)primitiveEvents;
- (void)setPrimitiveEvents:(NSMutableSet*)value;

- (NSMutableSet*)primitiveEventsToRecord;
- (void)setPrimitiveEventsToRecord:(NSMutableSet*)value;

- (NSMutableSet*)primitivePlayers;
- (void)setPrimitivePlayers:(NSMutableSet*)value;

@end
