// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GameEvent.h instead.

@import CoreData;

extern const struct GameEventAttributes {
	__unsafe_unretained NSString *categoryCode;
	__unsafe_unretained NSString *categoryTitle;
	__unsafe_unretained NSString *eventCode;
	__unsafe_unretained NSString *eventTitle;
	__unsafe_unretained NSString *isExtraManGoal;
	__unsafe_unretained NSString *penaltyDuration;
	__unsafe_unretained NSString *penaltyTime;
	__unsafe_unretained NSString *playerNumber;
	__unsafe_unretained NSString *timestamp;
} GameEventAttributes;

extern const struct GameEventRelationships {
	__unsafe_unretained NSString *game;
} GameEventRelationships;

@class Game;

@interface GameEventID : NSManagedObjectID {}
@end

@interface _GameEvent : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) GameEventID* objectID;

@property (nonatomic, strong) NSNumber* categoryCode;

@property (atomic) int16_t categoryCodeValue;
- (int16_t)categoryCodeValue;
- (void)setCategoryCodeValue:(int16_t)value_;

//- (BOOL)validateCategoryCode:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* categoryTitle;

//- (BOOL)validateCategoryTitle:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* eventCode;

@property (atomic) int16_t eventCodeValue;
- (int16_t)eventCodeValue;
- (void)setEventCodeValue:(int16_t)value_;

//- (BOOL)validateEventCode:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* eventTitle;

//- (BOOL)validateEventTitle:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* isExtraManGoal;

@property (atomic) BOOL isExtraManGoalValue;
- (BOOL)isExtraManGoalValue;
- (void)setIsExtraManGoalValue:(BOOL)value_;

//- (BOOL)validateIsExtraManGoal:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* penaltyDuration;

@property (atomic) int16_t penaltyDurationValue;
- (int16_t)penaltyDurationValue;
- (void)setPenaltyDurationValue:(int16_t)value_;

//- (BOOL)validatePenaltyDuration:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* penaltyTime;

@property (atomic) int16_t penaltyTimeValue;
- (int16_t)penaltyTimeValue;
- (void)setPenaltyTimeValue:(int16_t)value_;

//- (BOOL)validatePenaltyTime:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* playerNumber;

@property (atomic) int16_t playerNumberValue;
- (int16_t)playerNumberValue;
- (void)setPlayerNumberValue:(int16_t)value_;

//- (BOOL)validatePlayerNumber:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* timestamp;

//- (BOOL)validateTimestamp:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Game *game;

//- (BOOL)validateGame:(id*)value_ error:(NSError**)error_;

@end

@interface _GameEvent (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveCategoryCode;
- (void)setPrimitiveCategoryCode:(NSNumber*)value;

- (int16_t)primitiveCategoryCodeValue;
- (void)setPrimitiveCategoryCodeValue:(int16_t)value_;

- (NSString*)primitiveCategoryTitle;
- (void)setPrimitiveCategoryTitle:(NSString*)value;

- (NSNumber*)primitiveEventCode;
- (void)setPrimitiveEventCode:(NSNumber*)value;

- (int16_t)primitiveEventCodeValue;
- (void)setPrimitiveEventCodeValue:(int16_t)value_;

- (NSString*)primitiveEventTitle;
- (void)setPrimitiveEventTitle:(NSString*)value;

- (NSNumber*)primitiveIsExtraManGoal;
- (void)setPrimitiveIsExtraManGoal:(NSNumber*)value;

- (BOOL)primitiveIsExtraManGoalValue;
- (void)setPrimitiveIsExtraManGoalValue:(BOOL)value_;

- (NSNumber*)primitivePenaltyDuration;
- (void)setPrimitivePenaltyDuration:(NSNumber*)value;

- (int16_t)primitivePenaltyDurationValue;
- (void)setPrimitivePenaltyDurationValue:(int16_t)value_;

- (NSNumber*)primitivePenaltyTime;
- (void)setPrimitivePenaltyTime:(NSNumber*)value;

- (int16_t)primitivePenaltyTimeValue;
- (void)setPrimitivePenaltyTimeValue:(int16_t)value_;

- (NSNumber*)primitivePlayerNumber;
- (void)setPrimitivePlayerNumber:(NSNumber*)value;

- (int16_t)primitivePlayerNumberValue;
- (void)setPrimitivePlayerNumberValue:(int16_t)value_;

- (NSDate*)primitiveTimestamp;
- (void)setPrimitiveTimestamp:(NSDate*)value;

- (Game*)primitiveGame;
- (void)setPrimitiveGame:(Game*)value;

@end
