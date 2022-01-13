// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Game.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class GameEvent;
@class Event;
@class RosterPlayer;

@interface GameID : NSManagedObjectID {}
@end

@interface _Game : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (nullable NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) GameID *objectID;

@property (nonatomic, strong, nullable) NSDate* gameDateTime;

@property (nonatomic, strong, nullable) NSNumber* homeScore;

@property (atomic) int16_t homeScoreValue;
- (int16_t)homeScoreValue;
- (void)setHomeScoreValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSString* homeTeam;

@property (nonatomic, strong, nullable) NSString* location;

@property (nonatomic, strong, nullable) NSString* teamWatching;

@property (nonatomic, strong, nullable) NSString* visitingTeam;

@property (nonatomic, strong, nullable) NSNumber* visitorScore;

@property (atomic) int16_t visitorScoreValue;
- (int16_t)visitorScoreValue;
- (void)setVisitorScoreValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSSet<GameEvent*> *events;
- (nullable NSMutableSet<GameEvent*>*)eventsSet;

@property (nonatomic, strong, nullable) NSSet<Event*> *eventsToRecord;
- (nullable NSMutableSet<Event*>*)eventsToRecordSet;

@property (nonatomic, strong, nullable) NSSet<RosterPlayer*> *players;
- (nullable NSMutableSet<RosterPlayer*>*)playersSet;

@end

@interface _Game (EventsCoreDataGeneratedAccessors)
- (void)addEvents:(NSSet<GameEvent*>*)value_;
- (void)removeEvents:(NSSet<GameEvent*>*)value_;
- (void)addEventsObject:(GameEvent*)value_;
- (void)removeEventsObject:(GameEvent*)value_;

@end

@interface _Game (EventsToRecordCoreDataGeneratedAccessors)
- (void)addEventsToRecord:(NSSet<Event*>*)value_;
- (void)removeEventsToRecord:(NSSet<Event*>*)value_;
- (void)addEventsToRecordObject:(Event*)value_;
- (void)removeEventsToRecordObject:(Event*)value_;

@end

@interface _Game (PlayersCoreDataGeneratedAccessors)
- (void)addPlayers:(NSSet<RosterPlayer*>*)value_;
- (void)removePlayers:(NSSet<RosterPlayer*>*)value_;
- (void)addPlayersObject:(RosterPlayer*)value_;
- (void)removePlayersObject:(RosterPlayer*)value_;

@end

@interface _Game (CoreDataGeneratedPrimitiveAccessors)

- (nullable NSDate*)primitiveGameDateTime;
- (void)setPrimitiveGameDateTime:(nullable NSDate*)value;

- (nullable NSNumber*)primitiveHomeScore;
- (void)setPrimitiveHomeScore:(nullable NSNumber*)value;

- (int16_t)primitiveHomeScoreValue;
- (void)setPrimitiveHomeScoreValue:(int16_t)value_;

- (nullable NSString*)primitiveHomeTeam;
- (void)setPrimitiveHomeTeam:(nullable NSString*)value;

- (nullable NSString*)primitiveLocation;
- (void)setPrimitiveLocation:(nullable NSString*)value;

- (nullable NSString*)primitiveTeamWatching;
- (void)setPrimitiveTeamWatching:(nullable NSString*)value;

- (nullable NSString*)primitiveVisitingTeam;
- (void)setPrimitiveVisitingTeam:(nullable NSString*)value;

- (nullable NSNumber*)primitiveVisitorScore;
- (void)setPrimitiveVisitorScore:(nullable NSNumber*)value;

- (int16_t)primitiveVisitorScoreValue;
- (void)setPrimitiveVisitorScoreValue:(int16_t)value_;

- (NSMutableSet<GameEvent*>*)primitiveEvents;
- (void)setPrimitiveEvents:(NSMutableSet<GameEvent*>*)value;

- (NSMutableSet<Event*>*)primitiveEventsToRecord;
- (void)setPrimitiveEventsToRecord:(NSMutableSet<Event*>*)value;

- (NSMutableSet<RosterPlayer*>*)primitivePlayers;
- (void)setPrimitivePlayers:(NSMutableSet<RosterPlayer*>*)value;

@end

@interface GameAttributes: NSObject 
+ (NSString *)gameDateTime;
+ (NSString *)homeScore;
+ (NSString *)homeTeam;
+ (NSString *)location;
+ (NSString *)teamWatching;
+ (NSString *)visitingTeam;
+ (NSString *)visitorScore;
@end

@interface GameRelationships: NSObject
+ (NSString *)events;
+ (NSString *)eventsToRecord;
+ (NSString *)players;
@end

NS_ASSUME_NONNULL_END
