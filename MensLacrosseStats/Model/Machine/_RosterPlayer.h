// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RosterPlayer.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class GameEvent;
@class Game;

@interface RosterPlayerID : NSManagedObjectID {}
@end

@interface _RosterPlayer : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (nullable NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) RosterPlayerID *objectID;

@property (nonatomic, strong, nullable) NSNumber* isTeam;

@property (atomic) BOOL isTeamValue;
- (BOOL)isTeamValue;
- (void)setIsTeamValue:(BOOL)value_;

@property (nonatomic, strong, nullable) NSNumber* number;

@property (atomic) int16_t numberValue;
- (int16_t)numberValue;
- (void)setNumberValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSSet<GameEvent*> *events;
- (nullable NSMutableSet<GameEvent*>*)eventsSet;

@property (nonatomic, strong, nullable) Game *game;

@end

@interface _RosterPlayer (EventsCoreDataGeneratedAccessors)
- (void)addEvents:(NSSet<GameEvent*>*)value_;
- (void)removeEvents:(NSSet<GameEvent*>*)value_;
- (void)addEventsObject:(GameEvent*)value_;
- (void)removeEventsObject:(GameEvent*)value_;

@end

@interface _RosterPlayer (CoreDataGeneratedPrimitiveAccessors)

- (nullable NSNumber*)primitiveIsTeam;
- (void)setPrimitiveIsTeam:(nullable NSNumber*)value;

- (BOOL)primitiveIsTeamValue;
- (void)setPrimitiveIsTeamValue:(BOOL)value_;

- (nullable NSNumber*)primitiveNumber;
- (void)setPrimitiveNumber:(nullable NSNumber*)value;

- (int16_t)primitiveNumberValue;
- (void)setPrimitiveNumberValue:(int16_t)value_;

- (NSMutableSet<GameEvent*>*)primitiveEvents;
- (void)setPrimitiveEvents:(NSMutableSet<GameEvent*>*)value;

- (nullable Game*)primitiveGame;
- (void)setPrimitiveGame:(nullable Game*)value;

@end

@interface RosterPlayerAttributes: NSObject 
+ (NSString *)isTeam;
+ (NSString *)number;
@end

@interface RosterPlayerRelationships: NSObject
+ (NSString *)events;
+ (NSString *)game;
@end

NS_ASSUME_NONNULL_END
