//
//  INSOGameEventCounter.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/31/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "INSOMensLacrosseStatsEnum.h"

@class Game;
@class RosterPlayer;

@interface INSOGameEventCounter : NSObject

- (instancetype)initWithGame:(Game*)game;

- (NSNumber *)eventCount:(INSOEventCode)eventCode;
- (NSNumber *)eventCount:(INSOEventCode)eventCode forRosterPlayer:(RosterPlayer*)rosterPlayer;
- (NSNumber *)eventCountForHomeTeam:(INSOEventCode)eventCode;
- (NSNumber *)eventCountForVisitingTeam:(INSOEventCode)eventCode;

- (NSNumber *)extraManGoalsForHomeTeam;
- (NSNumber *)extraManGoalsForVisitingTeam;
- (NSNumber *)manDownGoalsAllowedForHomeTeam;
- (NSNumber *)manDownGoalsAllowedForVisitingTeam;

- (NSNumber *)totalPenalties;
- (NSNumber *)totalPenaltiesForBoysRosterPlayer:(RosterPlayer*)rosterPlayer;
- (NSNumber *)totalPenaltiesForGirlsRosterPlayer:(RosterPlayer*)rosterPlayer;
- (NSNumber *)totalPenaltyTime;
- (NSNumber *)totalPenaltyTimeforRosterPlayer:(RosterPlayer*)rosterPlayer;

@end
