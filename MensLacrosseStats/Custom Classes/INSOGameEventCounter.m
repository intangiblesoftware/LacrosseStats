//
//  INSOGameEventCounter.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/31/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "Game.h"
#import "GameEvent.h"
#import "RosterPlayer.h"
#import "Event.h"

#import "NSManagedObject+GameEventAggregate.h"

#import "INSOGameEventCounter.h"
#import "INSOMensLacrosseStatsEnum.h"

@interface INSOGameEventCounter ()

@property (nonatomic) Game* game;
@property (nonatomic) NSManagedObjectContext* managedObjectContext;

@end

@implementation INSOGameEventCounter

- (instancetype)initWithGame:(Game*)game
{
    self = [super init];
    
    if (self) {
        _game = game;
        _managedObjectContext = game.managedObjectContext;
    }
    
    return self;
}

- (NSNumber*)eventCount:(INSOEventCode)eventCode
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@", self.game, @(eventCode)];
    return [GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext];
}

- (NSNumber*)eventCount:(INSOEventCode)eventCode forRosterPlayer:(RosterPlayer*)rosterPlayer
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@ AND player == %@", self.game, @(eventCode), rosterPlayer];
    return [GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext];
}

- (NSNumber*)totalPenalties
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND (event.categoryCode == %@ OR event.categoryCode == %@)", self.game, @(INSOCategoryCodePersonalFouls), @(INSOCategoryCodeTechnicalFouls)];
    return [GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext];
}

- (NSNumber*)totalPenaltiesForBoysRosterPlayer:(RosterPlayer*)rosterPlayer
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND (event.categoryCode == %@ OR event.categoryCode == %@) AND player == %@", self.game, @(INSOCategoryCodePersonalFouls), @(INSOCategoryCodeTechnicalFouls), rosterPlayer];
    return [GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext];
}

- (NSNumber*)totalPenaltiesForGirlsRosterPlayer:(RosterPlayer*)rosterPlayer
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND (event.eventCode == %@ OR event.eventCode == %@) AND player == %@", self.game, @(INSOEventCodeMinorFoul), @(INSOEventCodeMajorFoul), rosterPlayer];
    return [GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext];
}

- (NSNumber*)totalPenaltyTime
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND (event.categoryCode == %@ OR event.categoryCode == %@)", self.game, @(INSOCategoryCodePersonalFouls), @(INSOCategoryCodeTechnicalFouls)];
    return [GameEvent aggregateOperation:@"sum:" onAttribute:@"penaltyTime" withPredicate:predicate inManagedObjectContext:self.managedObjectContext];
}

- (NSNumber*)totalPenaltyTimeforRosterPlayer:(RosterPlayer*)rosterPlayer
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND (event.categoryCode == %@ OR event.categoryCode == %@) AND player == %@", self.game, @(INSOCategoryCodePersonalFouls), @(INSOCategoryCodeTechnicalFouls), rosterPlayer];
    return [GameEvent aggregateOperation:@"sum:" onAttribute:@"penaltyTime" withPredicate:predicate inManagedObjectContext:self.managedObjectContext];
}

@end
