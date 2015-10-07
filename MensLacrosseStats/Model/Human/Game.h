#import "_Game.h"

@interface Game : _Game {}
// Class Methods

// Public Properties
@property (nonatomic, readonly) RosterPlayer* teamPlayer;

// Public Methods
- (BOOL)rosterContainsPlayerWithNumber:(NSNumber*)number;
- (RosterPlayer*)playerWithNumber:(NSNumber*)number;

@end
