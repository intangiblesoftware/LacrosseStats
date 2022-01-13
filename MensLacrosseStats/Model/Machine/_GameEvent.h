// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to GameEvent.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class Event;
@class Game;
@class RosterPlayer;

@interface GameEventID : NSManagedObjectID {}
@end

@interface _GameEvent : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (nullable NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) GameEventID *objectID;

@property (nonatomic, strong, nullable) NSNumber* is8m;

@property (atomic) BOOL is8mValue;
- (BOOL)is8mValue;
- (void)setIs8mValue:(BOOL)value_;

@property (nonatomic, strong, nullable) NSNumber* isExtraManGoal;

@property (atomic) BOOL isExtraManGoalValue;
- (BOOL)isExtraManGoalValue;
- (void)setIsExtraManGoalValue:(BOOL)value_;

@property (nonatomic, strong, nullable) NSNumber* penaltyTime;

@property (atomic) int16_t penaltyTimeValue;
- (int16_t)penaltyTimeValue;
- (void)setPenaltyTimeValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSDate* timestamp;

@property (nonatomic, strong, nullable) Event *event;

@property (nonatomic, strong, nullable) Game *game;

@property (nonatomic, strong, nullable) RosterPlayer *player;

@end

@interface _GameEvent (CoreDataGeneratedPrimitiveAccessors)

- (nullable NSNumber*)primitiveIs8m;
- (void)setPrimitiveIs8m:(nullable NSNumber*)value;

- (BOOL)primitiveIs8mValue;
- (void)setPrimitiveIs8mValue:(BOOL)value_;

- (nullable NSNumber*)primitiveIsExtraManGoal;
- (void)setPrimitiveIsExtraManGoal:(nullable NSNumber*)value;

- (BOOL)primitiveIsExtraManGoalValue;
- (void)setPrimitiveIsExtraManGoalValue:(BOOL)value_;

- (nullable NSNumber*)primitivePenaltyTime;
- (void)setPrimitivePenaltyTime:(nullable NSNumber*)value;

- (int16_t)primitivePenaltyTimeValue;
- (void)setPrimitivePenaltyTimeValue:(int16_t)value_;

- (nullable NSDate*)primitiveTimestamp;
- (void)setPrimitiveTimestamp:(nullable NSDate*)value;

- (nullable Event*)primitiveEvent;
- (void)setPrimitiveEvent:(nullable Event*)value;

- (nullable Game*)primitiveGame;
- (void)setPrimitiveGame:(nullable Game*)value;

- (nullable RosterPlayer*)primitivePlayer;
- (void)setPrimitivePlayer:(nullable RosterPlayer*)value;

@end

@interface GameEventAttributes: NSObject 
+ (NSString *)is8m;
+ (NSString *)isExtraManGoal;
+ (NSString *)penaltyTime;
+ (NSString *)timestamp;
@end

@interface GameEventRelationships: NSObject
+ (NSString *)event;
+ (NSString *)game;
+ (NSString *)player;
@end

NS_ASSUME_NONNULL_END
