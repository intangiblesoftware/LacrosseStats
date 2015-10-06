//
//  INSOEventArrayFactory.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/3/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "INSOMensLacrosseStatsEnum.h"

@class Game;

@interface INSOEventArrayFactory : NSObject

// Public Interface
- (NSArray*)allEvents;
- (NSArray*)eventsForGame:(Game*)game;

@end
