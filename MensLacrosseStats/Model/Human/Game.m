#import "Game.h"
#import "RosterPlayer.h"

@interface Game ()

// Private interface goes here.

@end

@implementation Game

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

@end
