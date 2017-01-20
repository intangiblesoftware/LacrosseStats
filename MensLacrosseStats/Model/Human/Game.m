#import "Game.h"
#import "RosterPlayer.h"
#import "Event.h"

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
        NSLog(@"Create other team player.");
        
        // Update goals for other team.
        NSLog(@"Update goals for other team.");
        
        // Update score for game
        NSLog(@"Update score for game.");
    }
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

@end
