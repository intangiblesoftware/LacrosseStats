//
//  INSOEmailStatsFileGenerator.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 11/27/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Game;

typedef void(^completion)(NSData* gameStatsData);

@interface INSOEmailStatsFileGenerator : NSObject

- (instancetype)init;
- (instancetype)initWithGame:(Game*)game;

@property (nonatomic) Game* game;

- (void)createGameStatsDataFileForAllStats:(completion)completion;
- (void)createGameStatsDataFileForRecordedStats:(completion)completion;

- (void)createBoysMaxPrepsGameStatsFile:(completion)completion;
- (void)createGirlsMaxPrepsGameStatsFile:(completion)completion; 

@end
