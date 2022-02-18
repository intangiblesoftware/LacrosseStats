// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class EventCategory;
@class GameEvent;
@class Game;

@interface EventID : NSManagedObjectID {}
@end

@interface _Event : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (nullable NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EventID *objectID;

@property (nonatomic, strong, nullable) NSNumber* categoryCode;

@property (atomic) int16_t categoryCodeValue;
- (int16_t)categoryCodeValue;
- (void)setCategoryCodeValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSNumber* eventCode;

@property (atomic) int16_t eventCodeValue;
- (int16_t)eventCodeValue;
- (void)setEventCodeValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSNumber* isDefalut;

@property (atomic) BOOL isDefalutValue;
- (BOOL)isDefalutValue;
- (void)setIsDefalutValue:(BOOL)value_;

@property (nonatomic, strong, nullable) NSNumber* statCategory;

@property (atomic) int16_t statCategoryValue;
- (int16_t)statCategoryValue;
- (void)setStatCategoryValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSString* title;

@property (nonatomic, strong, nullable) EventCategory *category;

@property (nonatomic, strong, nullable) NSSet<GameEvent*> *gameEvents;
- (nullable NSMutableSet<GameEvent*>*)gameEventsSet;

@property (nonatomic, strong, nullable) NSSet<Game*> *games;
- (nullable NSMutableSet<Game*>*)gamesSet;

+ (NSArray*)fetchDefaultEvents:(NSManagedObjectContext*)moc_ ;
+ (NSArray*)fetchDefaultEvents:(NSManagedObjectContext*)moc_ error:(NSError**)error_;

@end

@interface _Event (GameEventsCoreDataGeneratedAccessors)
- (void)addGameEvents:(NSSet<GameEvent*>*)value_;
- (void)removeGameEvents:(NSSet<GameEvent*>*)value_;
- (void)addGameEventsObject:(GameEvent*)value_;
- (void)removeGameEventsObject:(GameEvent*)value_;

@end

@interface _Event (GamesCoreDataGeneratedAccessors)
- (void)addGames:(NSSet<Game*>*)value_;
- (void)removeGames:(NSSet<Game*>*)value_;
- (void)addGamesObject:(Game*)value_;
- (void)removeGamesObject:(Game*)value_;

@end

@interface _Event (CoreDataGeneratedPrimitiveAccessors)

- (nullable NSNumber*)primitiveCategoryCode;
- (void)setPrimitiveCategoryCode:(nullable NSNumber*)value;

- (int16_t)primitiveCategoryCodeValue;
- (void)setPrimitiveCategoryCodeValue:(int16_t)value_;

- (nullable NSNumber*)primitiveEventCode;
- (void)setPrimitiveEventCode:(nullable NSNumber*)value;

- (int16_t)primitiveEventCodeValue;
- (void)setPrimitiveEventCodeValue:(int16_t)value_;

- (nullable NSNumber*)primitiveIsDefalut;
- (void)setPrimitiveIsDefalut:(nullable NSNumber*)value;

- (BOOL)primitiveIsDefalutValue;
- (void)setPrimitiveIsDefalutValue:(BOOL)value_;

- (nullable NSNumber*)primitiveStatCategory;
- (void)setPrimitiveStatCategory:(nullable NSNumber*)value;

- (int16_t)primitiveStatCategoryValue;
- (void)setPrimitiveStatCategoryValue:(int16_t)value_;

- (nullable NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(nullable NSString*)value;

- (nullable EventCategory*)primitiveCategory;
- (void)setPrimitiveCategory:(nullable EventCategory*)value;

- (NSMutableSet<GameEvent*>*)primitiveGameEvents;
- (void)setPrimitiveGameEvents:(NSMutableSet<GameEvent*>*)value;

- (NSMutableSet<Game*>*)primitiveGames;
- (void)setPrimitiveGames:(NSMutableSet<Game*>*)value;

@end

@interface EventAttributes: NSObject 
+ (NSString *)categoryCode;
+ (NSString *)eventCode;
+ (NSString *)isDefalut;
+ (NSString *)statCategory;
+ (NSString *)title;
@end

@interface EventRelationships: NSObject
+ (NSString *)category;
+ (NSString *)gameEvents;
+ (NSString *)games;
@end

NS_ASSUME_NONNULL_END
