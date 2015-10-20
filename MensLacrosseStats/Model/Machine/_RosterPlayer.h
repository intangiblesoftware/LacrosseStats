// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RosterPlayer.h instead.

@import CoreData;

extern const struct RosterPlayerAttributes {
	__unsafe_unretained NSString *isTeam;
	__unsafe_unretained NSString *number;
} RosterPlayerAttributes;

extern const struct RosterPlayerRelationships {
	__unsafe_unretained NSString *events;
	__unsafe_unretained NSString *game;
} RosterPlayerRelationships;

@class GameEvent;
@class Game;

@interface RosterPlayerID : NSManagedObjectID {}
@end

@interface _RosterPlayer : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) RosterPlayerID* objectID;

@property (nonatomic, strong) NSNumber* isTeam;

@property (atomic) BOOL isTeamValue;
- (BOOL)isTeamValue;
- (void)setIsTeamValue:(BOOL)value_;

//- (BOOL)validateIsTeam:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* number;

@property (atomic) int16_t numberValue;
- (int16_t)numberValue;
- (void)setNumberValue:(int16_t)value_;

//- (BOOL)validateNumber:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *events;

- (NSMutableSet*)eventsSet;

@property (nonatomic, strong) Game *game;

//- (BOOL)validateGame:(id*)value_ error:(NSError**)error_;

@end

@interface _RosterPlayer (EventsCoreDataGeneratedAccessors)
- (void)addEvents:(NSSet*)value_;
- (void)removeEvents:(NSSet*)value_;
- (void)addEventsObject:(GameEvent*)value_;
- (void)removeEventsObject:(GameEvent*)value_;

@end

@interface _RosterPlayer (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveIsTeam;
- (void)setPrimitiveIsTeam:(NSNumber*)value;

- (BOOL)primitiveIsTeamValue;
- (void)setPrimitiveIsTeamValue:(BOOL)value_;

- (NSNumber*)primitiveNumber;
- (void)setPrimitiveNumber:(NSNumber*)value;

- (int16_t)primitiveNumberValue;
- (void)setPrimitiveNumberValue:(int16_t)value_;

- (NSMutableSet*)primitiveEvents;
- (void)setPrimitiveEvents:(NSMutableSet*)value;

- (Game*)primitiveGame;
- (void)setPrimitiveGame:(Game*)value;

@end
