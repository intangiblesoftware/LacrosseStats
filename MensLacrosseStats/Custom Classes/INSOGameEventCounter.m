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

@property (nonatomic, assign) BOOL isWatchingHomeTeam;

@end

@implementation INSOGameEventCounter

- (instancetype)initWithGame:(Game*)game
{
    self = [super init];
    
    if (self) {
        _game = game;
        _managedObjectContext = game.managedObjectContext;
        _isWatchingHomeTeam = [game.homeTeam isEqualToString:game.teamWatching];
    }
    
    return self;
}

- (NSNumber*)eventCount:(INSOEventCode)eventCode
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@", self.game, @(eventCode)];
    return [GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext];
}

- (NSNumber *)eventCountForHomeTeam:(INSOEventCode)eventCode
{
    NSInteger eventCount;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@ AND player.number == %@", self.game, @(eventCode), self.isWatchingHomeTeam ? @(INSOTeamWatchingPlayerNumber) : @(INSOOtherTeamPlayerNumber)];
    eventCount = [[GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext] integerValue];
    if (self.isWatchingHomeTeam) {
        // Now cycle through all the players as well.
        NSInteger playerCount = 0;
        for (RosterPlayer *player in self.game.players) {
            if (player.numberValue >= 0) {
                playerCount += [[self eventCount:eventCode forRosterPlayer:player] integerValue];
            }
        }
        eventCount += playerCount;
    }
    return @(eventCount);
}

- (NSNumber *)freePositionEventCountForHomeTeam:(INSOEventCode)eventCode
{
    NSInteger eventCount;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@ AND player.number == %@ AND is8m == %@", self.game, @(eventCode), self.isWatchingHomeTeam ? @(INSOTeamWatchingPlayerNumber) : @(INSOOtherTeamPlayerNumber), @(YES)];
    eventCount = [[GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext] integerValue];
    if (self.isWatchingHomeTeam) {
        // Now cycle through all the players as well.
        NSInteger playerCount = 0;
        for (RosterPlayer *player in self.game.players) {
            if (player.numberValue >= 0) {
                playerCount += [[self freePositionEventCount:eventCode forRosterPlayer:player] integerValue];
            }
        }
        eventCount += playerCount;
    }
    return @(eventCount);
}

- (NSNumber *)eventCountForVisitingTeam:(INSOEventCode)eventCode
{
    NSInteger eventCount;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@ AND player.number == %@", self.game, @(eventCode), self.isWatchingHomeTeam ? @(INSOOtherTeamPlayerNumber) : @(INSOTeamWatchingPlayerNumber)];
    eventCount = [[GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext] integerValue];
    if (!self.isWatchingHomeTeam) {
        // Now cycle through all the players as well.
        NSInteger playerCount = 0;
        for (RosterPlayer *player in self.game.players) {
            if (player.numberValue >= 0) {
                playerCount += [[self eventCount:eventCode forRosterPlayer:player] integerValue];
            }
        }
        eventCount += playerCount;
    }
    return @(eventCount);
}

- (NSNumber *)freePositionEventCountForVisitingTeam:(INSOEventCode)eventCode
{
    NSInteger eventCount;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@ AND player.number == %@ AND is8m == %@", self.game, @(eventCode), self.isWatchingHomeTeam ? @(INSOOtherTeamPlayerNumber) : @(INSOTeamWatchingPlayerNumber), @(YES)];
    eventCount = [[GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext] integerValue];
    if (!self.isWatchingHomeTeam) {
        // Now cycle through all the players as well.
        NSInteger playerCount = 0;
        for (RosterPlayer *player in self.game.players) {
            if (player.numberValue >= 0) {
                playerCount += [[self freePositionEventCount:eventCode forRosterPlayer:player] integerValue];
            }
        }
        eventCount += playerCount;
    }
    return @(eventCount);
}

- (NSNumber*)eventCount:(INSOEventCode)eventCode forRosterPlayer:(RosterPlayer*)rosterPlayer
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@ AND player == %@", self.game, @(eventCode), rosterPlayer];
    return [GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext];
}

- (NSNumber*)freePositionEventCount:(INSOEventCode)eventCode forRosterPlayer:(RosterPlayer*)rosterPlayer
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@ AND player == %@ AND is8m == %@", self.game, @(eventCode), rosterPlayer, @(YES)];
    return [GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext];
}

- (NSNumber *)extraManGoalsForHomeTeam
{
    NSInteger eventCount;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@ AND player.number == %@ AND isExtraManGoal == YES", self.game, @(INSOEventCodeGoal), self.isWatchingHomeTeam ? @(INSOTeamWatchingPlayerNumber) : @(INSOOtherTeamPlayerNumber)];
    eventCount = [[GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext] integerValue];
    if (self.isWatchingHomeTeam) {
        // Now cycle through all the players as well.
        for (RosterPlayer *player in self.game.players) {
            if (player.numberValue >= 0) {
                for (GameEvent *gameEvent in player.events) {
                    if (gameEvent.isExtraManGoalValue) {
                        eventCount += 1;
                    }
                }
            }
        }
    }
    return @(eventCount);
}

- (NSNumber *)extraManGoalsForVisitingTeam
{
    NSInteger eventCount;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@ AND player.number == %@ AND isExtraManGoal == YES", self.game, @(INSOEventCodeGoal), self.isWatchingHomeTeam ? @(INSOOtherTeamPlayerNumber) : @(INSOTeamWatchingPlayerNumber)];
    eventCount = [[GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext] integerValue];
    if (!self.isWatchingHomeTeam) {
        // Now cycle through all the players as well.
        for (RosterPlayer *player in self.game.players) {
            if (player.numberValue >= 0) {
                for (GameEvent *gameEvent in player.events) {
                    if (gameEvent.isExtraManGoalValue) {
                        eventCount += 1;
                    }
                }
            }
        }
    }
    return @(eventCount);
}

- (NSNumber*)totalPenaltiesForHomeTeam
{
    NSInteger eventCount;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game == %@ AND (event.categoryCode == %@ OR event.categoryCode == %@) AND player.number == %@", self.game, @(INSOCategoryCodePersonalFouls), @(INSOCategoryCodeTechnicalFouls), self.isWatchingHomeTeam ? @(INSOTeamWatchingPlayerNumber) : @(INSOOtherTeamPlayerNumber)];
    eventCount = [[GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext] integerValue];
    if (self.isWatchingHomeTeam) {
        // Now cycle through all the players as well.
        for (RosterPlayer *player in self.game.players) {
            if (player.numberValue >= 0) {
                for (GameEvent *gameEvent in player.events) {
                    if ((gameEvent.event.categoryCodeValue == INSOCategoryCodePersonalFouls) || (gameEvent.event.categoryCodeValue == INSOCategoryCodeTechnicalFouls)) {
                        eventCount += 1;
                    }
                }
            }
        }
    }
    return @(eventCount);
}

- (NSNumber *)totalPenaltiesForVisitingTeam
{
    NSInteger eventCount;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game == %@ AND (event.categoryCode == %@ OR event.categoryCode == %@) AND player.number == %@", self.game, @(INSOCategoryCodePersonalFouls), @(INSOCategoryCodeTechnicalFouls), self.isWatchingHomeTeam ? @(INSOOtherTeamPlayerNumber) : @(INSOTeamWatchingPlayerNumber)];
    eventCount = [[GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext] integerValue];
    if (!self.isWatchingHomeTeam) {
        // Now cycle through all the players as well.
        for (RosterPlayer *player in self.game.players) {
            if (player.numberValue >= 0) {
                for (GameEvent *gameEvent in player.events) {
                    if ((gameEvent.event.categoryCodeValue == INSOCategoryCodePersonalFouls) || (gameEvent.event.categoryCodeValue == INSOCategoryCodeTechnicalFouls)) {
                        eventCount += 1;
                    }
                }
            }
        }
    }
    return @(eventCount);
}

- (NSNumber *)totalFoulsForHomeTeam
{
    NSInteger eventCount;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game == %@ AND (event.eventCode == %@ OR event.eventCode == %@) AND player.number == %@", self.game, @(INSOEventCodeMinorFoul), @(INSOEventCodeMajorFoul), self.isWatchingHomeTeam ? @(INSOTeamWatchingPlayerNumber) : @(INSOOtherTeamPlayerNumber)];
    eventCount = [[GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext] integerValue];
    if (self.isWatchingHomeTeam) {
        // Now cycle through all the players as well.
        for (RosterPlayer *player in self.game.players) {
            if (player.numberValue >= 0) {
                for (GameEvent *gameEvent in player.events) {
                    if ((gameEvent.event.eventCodeValue == INSOEventCodeMinorFoul) || (gameEvent.event.eventCodeValue == INSOEventCodeMajorFoul)) {
                        eventCount += 1;
                    }
                }
            }
        }
    }
    return @(eventCount);
}

- (NSNumber *)totalFoulsForVisitingTeam
{
    NSInteger eventCount;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game == %@ AND (event.eventCode == %@ OR event.eventCode == %@) AND player.number == %@", self.game, @(INSOEventCodeMinorFoul), @(INSOEventCodeMajorFoul), self.isWatchingHomeTeam ? @(INSOOtherTeamPlayerNumber) : @(INSOTeamWatchingPlayerNumber)];
    eventCount = [[GameEvent aggregateOperation:@"count:" onAttribute:@"timestamp" withPredicate:predicate inManagedObjectContext:self.managedObjectContext] integerValue];
    if (!self.isWatchingHomeTeam) {
        // Now cycle through all the players as well.
        for (RosterPlayer *player in self.game.players) {
            if (player.numberValue >= 0) {
                for (GameEvent *gameEvent in player.events) {
                    if ((gameEvent.event.eventCodeValue == INSOEventCodeMinorFoul) || (gameEvent.event.eventCodeValue == INSOEventCodeMajorFoul)) {
                        eventCount += 1;
                    }
                }
            }
        }
    }
    return @(eventCount);
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

- (NSNumber*)totalPenaltyTimeforRosterPlayer:(RosterPlayer*)rosterPlayer
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND (event.categoryCode == %@ OR event.categoryCode == %@) AND player == %@", self.game, @(INSOCategoryCodePersonalFouls), @(INSOCategoryCodeTechnicalFouls), rosterPlayer];
    return [GameEvent aggregateOperation:@"sum:" onAttribute:@"penaltyTime" withPredicate:predicate inManagedObjectContext:self.managedObjectContext];
}

- (NSNumber *)totalPenaltyTimeForHomeTeam
{
    NSInteger penaltyTime;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game == %@ AND (event.categoryCode == %@ OR event.categoryCode == %@) AND player.number == %@", self.game, @(INSOCategoryCodePersonalFouls), @(INSOCategoryCodeTechnicalFouls), self.isWatchingHomeTeam ? @(INSOTeamWatchingPlayerNumber) : @(INSOOtherTeamPlayerNumber)];
    penaltyTime = [[GameEvent aggregateOperation:@"sum:" onAttribute:@"penaltyTime" withPredicate:predicate inManagedObjectContext:self.managedObjectContext] integerValue];
    if (self.isWatchingHomeTeam) {
        // Now cycle through all the players as well.
        for (RosterPlayer *player in self.game.players) {
            if (player.numberValue >= 0) {
                for (GameEvent *gameEvent in player.events) {
                    if ((gameEvent.event.categoryCodeValue == INSOCategoryCodePersonalFouls) || (gameEvent.event.categoryCodeValue == INSOCategoryCodeTechnicalFouls)) {
                        penaltyTime += gameEvent.penaltyTimeValue;
                    }
                }
            }
        }
    }
    return @(penaltyTime);
}

- (NSNumber *)totalPenaltyTimeForVisitingTeam
{
    NSInteger penaltyTime;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"game == %@ AND (event.categoryCode == %@ OR event.categoryCode == %@) AND player.number == %@", self.game, @(INSOCategoryCodePersonalFouls), @(INSOCategoryCodeTechnicalFouls), self.isWatchingHomeTeam ? @(INSOOtherTeamPlayerNumber) : @(INSOTeamWatchingPlayerNumber)];
    penaltyTime = [[GameEvent aggregateOperation:@"sum:" onAttribute:@"penaltyTime" withPredicate:predicate inManagedObjectContext:self.managedObjectContext] integerValue];
    if (!self.isWatchingHomeTeam) {
        // Now cycle through all the players as well.
        for (RosterPlayer *player in self.game.players) {
            if (player.numberValue >= 0) {
                for (GameEvent *gameEvent in player.events) {
                    if ((gameEvent.event.categoryCodeValue == INSOCategoryCodePersonalFouls) || (gameEvent.event.categoryCodeValue == INSOCategoryCodeTechnicalFouls)) {
                        penaltyTime += gameEvent.penaltyTimeValue;
                    }
                }
            }
        }
    }
    return @(penaltyTime);
}

@end
