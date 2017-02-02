// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GameEvent.h instead.

#import <CoreData/CoreData.h>

extern const struct GameEventAttributes {
	__unsafe_unretained NSString *is8m;
	__unsafe_unretained NSString *isExtraManGoal;
	__unsafe_unretained NSString *penaltyTime;
	__unsafe_unretained NSString *timestamp;
} GameEventAttributes;

extern const struct GameEventRelationships {
	__unsafe_unretained NSString *event;
	__unsafe_unretained NSString *game;
	__unsafe_unretained NSString *player;
} GameEventRelationships;

@class Event;
@class Game;
@class RosterPlayer;

@interface GameEventID : NSManagedObjectID {}
@end

@interface _GameEvent : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) GameEventID* objectID;

@property (nonatomic, strong) NSNumber* is8m;

@property (atomic) BOOL is8mValue;
- (BOOL)is8mValue;
- (void)setIs8mValue:(BOOL)value_;

//- (BOOL)validateIs8m:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* isExtraManGoal;

@property (atomic) BOOL isExtraManGoalValue;
- (BOOL)isExtraManGoalValue;
- (void)setIsExtraManGoalValue:(BOOL)value_;

//- (BOOL)validateIsExtraManGoal:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* penaltyTime;

@property (atomic) int16_t penaltyTimeValue;
- (int16_t)penaltyTimeValue;
- (void)setPenaltyTimeValue:(int16_t)value_;

//- (BOOL)validatePenaltyTime:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* timestamp;

//- (BOOL)validateTimestamp:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Event *event;

//- (BOOL)validateEvent:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Game *game;

//- (BOOL)validateGame:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) RosterPlayer *player;

//- (BOOL)validatePlayer:(id*)value_ error:(NSError**)error_;

@end

@interface _GameEvent (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveIs8m;
- (void)setPrimitiveIs8m:(NSNumber*)value;

- (BOOL)primitiveIs8mValue;
- (void)setPrimitiveIs8mValue:(BOOL)value_;

- (NSNumber*)primitiveIsExtraManGoal;
- (void)setPrimitiveIsExtraManGoal:(NSNumber*)value;

- (BOOL)primitiveIsExtraManGoalValue;
- (void)setPrimitiveIsExtraManGoalValue:(BOOL)value_;

- (NSNumber*)primitivePenaltyTime;
- (void)setPrimitivePenaltyTime:(NSNumber*)value;

- (int16_t)primitivePenaltyTimeValue;
- (void)setPrimitivePenaltyTimeValue:(int16_t)value_;

- (NSDate*)primitiveTimestamp;
- (void)setPrimitiveTimestamp:(NSDate*)value;

- (Event*)primitiveEvent;
- (void)setPrimitiveEvent:(Event*)value;

- (Game*)primitiveGame;
- (void)setPrimitiveGame:(Game*)value;

- (RosterPlayer*)primitivePlayer;
- (void)setPrimitivePlayer:(RosterPlayer*)value;

@end
