#import "Game.h"
#import "RosterPlayer.h"
#import "Event.h"
#import "GameEvent.h"

@interface Game ()

// Private interface goes here.

@end

@implementation Game

- (void)awakeFromFetch
{
    [super awakeFromFetch];

    // Make sure this doesn't happen when we create a game.
    
    // If we're missing the Other Team, gotta update this object
    if (![self rosterContainsPlayerWithNumber:@(INSOOtherTeamPlayerNumber)]) {
        // Create other team player.
        RosterPlayer *otherTeamPlayer = [RosterPlayer insertInManagedObjectContext:self.managedObjectContext];
        otherTeamPlayer.numberValue = INSOOtherTeamPlayerNumber;
        otherTeamPlayer.isTeamValue = YES;
        [self addPlayersObject:otherTeamPlayer];
        
        // Update goals for other team.
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"event.eventCodeValue = %@", @(INSOEventCodeGoalAllowed)];
        NSSet *goalsAllowedSet = [self.events filteredSetUsingPredicate:predicate];
        for (GameEvent *event in goalsAllowedSet) {
            GameEvent* goalEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
            
            // Set its properties
            goalEvent.timestamp = event.timestamp;
            
            // Set its relations
            goalEvent.event = [Event eventForCode:INSOEventCodeGoal inManagedObjectContext:self.managedObjectContext];
            goalEvent.game = self;
            goalEvent.player = otherTeamPlayer;
            goalEvent.isExtraManGoalValue = NO;
            goalEvent.is8mValue = NO;
        }
        
        // Update score for game
        if ([self.teamWatching isEqualToString:self.homeTeam]) {
            self.visitorScoreValue = [goalsAllowedSet count];
        } else {
            self.homeScoreValue = [goalsAllowedSet count];
        }
    } else {
        // Just update game score.
        [self updateScores]; 
    }
}

- (NSInteger)teamWatchingGoals
{
    NSSet* goals = [self.events objectsPassingTest:^BOOL(GameEvent*  _Nonnull gameEvent, BOOL * _Nonnull stop) {
        return (gameEvent.event.eventCodeValue == INSOEventCodeGoal && gameEvent.player.numberValue >= INSOTeamWatchingPlayerNumber);
    }];
    return [goals count];
}

- (NSInteger)otherTeamGoals
{
    NSSet* goals = [self.events objectsPassingTest:^BOOL(GameEvent*  _Nonnull gameEvent, BOOL * _Nonnull stop) {
        return (gameEvent.event.eventCodeValue == INSOEventCodeGoal && gameEvent.player.numberValue == INSOOtherTeamPlayerNumber);
    }];
    return [goals count];
}


- (RosterPlayer*)teamPlayer
{
    NSNumber* teamPlayerNumber = [NSNumber numberWithInteger:-1];
    
    RosterPlayer* _teamPlayer = [self playerWithNumber:teamPlayerNumber];
    
    if (!_teamPlayer) {
        _teamPlayer = [RosterPlayer insertInManagedObjectContext:self.managedObjectContext];
        _teamPlayer.number = teamPlayerNumber;
    }
    
    return _teamPlayer;
}

- (BOOL)rosterContainsPlayerWithNumber:(NSNumber *)number
{
    BOOL __block containsPlayer = NO;
    [self.players enumerateObjectsUsingBlock:^(RosterPlayer*  _Nonnull rosterPlayer, BOOL * _Nonnull stop) {
        if ([rosterPlayer.number isEqualToNumber:number]) {
            containsPlayer = YES;
            *stop = YES;
        }
    }];

    return containsPlayer;
}

- (RosterPlayer*)playerWithNumber:(NSNumber *)number
{
    NSSet* matchingPlayers = [self.players objectsPassingTest:^BOOL(RosterPlayer *  _Nonnull rosterPlayer, BOOL * _Nonnull stop) {
        return [rosterPlayer.number isEqualToNumber:number];
    }];
    
    return [matchingPlayers anyObject];
}

- (BOOL)didRecordEvent:(INSOEventCode)eventCode
{
    BOOL __block recordedEvent = NO;
    [self.eventsToRecord enumerateObjectsUsingBlock:^(Event*  _Nonnull event, BOOL * _Nonnull stop) {
        if (event.eventCodeValue == eventCode) {
            recordedEvent = YES;
            *stop = YES;
        }
    }];
    
    return recordedEvent;
}

- (void)updateScores
{
    if ([self.homeTeam isEqualToString:self.teamWatching]) {
        self.homeScoreValue = [self teamWatchingGoals];
    } else {
        self.homeScoreValue = [self otherTeamGoals];
    }
    
    if ([self.visitingTeam isEqualToString:self.teamWatching]) {
        self.visitorScoreValue = [self teamWatchingGoals];
    } else {
        self.visitorScoreValue = [self otherTeamGoals];
    }
}

@end
