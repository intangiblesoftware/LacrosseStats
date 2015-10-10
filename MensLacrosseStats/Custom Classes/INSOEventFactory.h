//
//  INSOEventFactory.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/3/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "INSOMensLacrosseStatsEnum.h"

@class Game;

extern NSString * const INSOEventCodeKey;
extern NSString * const INSOEventTitleKey;
extern NSString * const INSOCategoryCodeKey;
extern NSString * const INSOCategoryTitleKey;
extern NSString * const INSOCategorySortOrderKey;
extern NSString * const INSOCategoryStatsKey;

@interface INSOEventFactory : NSObject

// Public Interface
- (instancetype)init;

- (NSArray*)eventArray;
- (NSArray*)eventArrayForGame:(Game*)game;

- (NSString*)titleForEventCode:(NSNumber*)eventCode;
- (NSString*)titleForCategoryCode:(NSNumber*)categoryCode; 

@end
