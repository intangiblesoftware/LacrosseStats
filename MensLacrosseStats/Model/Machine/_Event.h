// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.h instead.

@import CoreData;

extern const struct EventAttributes {
	__unsafe_unretained NSString *categoryCode;
	__unsafe_unretained NSString *eventCode;
	__unsafe_unretained NSString *isDefalut;
	__unsafe_unretained NSString *statCategory;
	__unsafe_unretained NSString *title;
} EventAttributes;

extern const struct EventRelationships {
	__unsafe_unretained NSString *category;
	__unsafe_unretained NSString *gameEvents;
	__unsafe_unretained NSString *games;
} EventRelationships;

@class EventCategory;
@class GameEvent;
@class Game;

@interface EventID : NSManagedObjectID {}
@end

@interface _Event : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EventID* objectID;

@property (nonatomic, strong) NSNumber* categoryCode;

@property (atomic) int16_t categoryCodeValue;
- (int16_t)categoryCodeValue;
- (void)setCategoryCodeValue:(int16_t)value_;

//- (BOOL)validateCategoryCode:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* eventCode;

@property (atomic) int16_t eventCodeValue;
- (int16_t)eventCodeValue;
- (void)setEventCodeValue:(int16_t)value_;

//- (BOOL)validateEventCode:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* isDefalut;

@property (atomic) BOOL isDefalutValue;
- (BOOL)isDefalutValue;
- (void)setIsDefalutValue:(BOOL)value_;

//- (BOOL)validateIsDefalut:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* statCategory;

@property (atomic) int16_t statCategoryValue;
- (int16_t)statCategoryValue;
- (void)setStatCategoryValue:(int16_t)value_;

//- (BOOL)validateStatCategory:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* title;

//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) EventCategory *category;

//- (BOOL)validateCategory:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *gameEvents;

- (NSMutableSet*)gameEventsSet;

@property (nonatomic, strong) NSSet *games;

- (NSMutableSet*)gamesSet;

+ (NSArray*)fetchDefaultEvents:(NSManagedObjectContext*)moc_ ;
+ (NSArray*)fetchDefaultEvents:(NSManagedObjectContext*)moc_ error:(NSError**)error_;

@end

@interface _Event (GameEventsCoreDataGeneratedAccessors)
- (void)addGameEvents:(NSSet*)value_;
- (void)removeGameEvents:(NSSet*)value_;
- (void)addGameEventsObject:(GameEvent*)value_;
- (void)removeGameEventsObject:(GameEvent*)value_;

@end

@interface _Event (GamesCoreDataGeneratedAccessors)
- (void)addGames:(NSSet*)value_;
- (void)removeGames:(NSSet*)value_;
- (void)addGamesObject:(Game*)value_;
- (void)removeGamesObject:(Game*)value_;

@end

@interface _Event (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveCategoryCode;
- (void)setPrimitiveCategoryCode:(NSNumber*)value;

- (int16_t)primitiveCategoryCodeValue;
- (void)setPrimitiveCategoryCodeValue:(int16_t)value_;

- (NSNumber*)primitiveEventCode;
- (void)setPrimitiveEventCode:(NSNumber*)value;

- (int16_t)primitiveEventCodeValue;
- (void)setPrimitiveEventCodeValue:(int16_t)value_;

- (NSNumber*)primitiveIsDefalut;
- (void)setPrimitiveIsDefalut:(NSNumber*)value;

- (BOOL)primitiveIsDefalutValue;
- (void)setPrimitiveIsDefalutValue:(BOOL)value_;

- (NSNumber*)primitiveStatCategory;
- (void)setPrimitiveStatCategory:(NSNumber*)value;

- (int16_t)primitiveStatCategoryValue;
- (void)setPrimitiveStatCategoryValue:(int16_t)value_;

- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;

- (EventCategory*)primitiveCategory;
- (void)setPrimitiveCategory:(EventCategory*)value;

- (NSMutableSet*)primitiveGameEvents;
- (void)setPrimitiveGameEvents:(NSMutableSet*)value;

- (NSMutableSet*)primitiveGames;
- (void)setPrimitiveGames:(NSMutableSet*)value;

@end
