//
//  INSOEventInterpreter.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/3/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "INSOMensLacrosseStatsEnum.h"

@interface INSOEventInterpreter : NSObject

// Public Interface
@property (nonatomic, readonly) NSArray* allEventCodes;
@property (nonatomic, readonly) NSArray* allCategories;

- (NSString*)titleForEventCode:(INSOEventCode)eventCode;
- (NSString*)titleForCateogoryCode:(INSOCategoryCode)categoryCode;

- (INSOCategoryCode)categoryCodeForEvent:(INSOEventCode)eventCode;

@end
