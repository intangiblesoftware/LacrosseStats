//
//  INSOMensLacrosseStatsConstants.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 9/29/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOMensLacrosseStatsConstants.h"

@implementation INSOMensLacrosseStatsConstant

#pragma mark - User Defaults
NSString * const INSODefaultShouldImportCategoriesAndEventsKey = @"INSOShouldImportCategoriesKey";

#pragma mark - Import keys
NSString * const INSOEventTitleKey     = @"EventTitle";
NSString * const INSOEventCodeKey      = @"EventCode";
NSString * const INSOCategoryTitleKey  = @"CategoryTitle";
NSString * const INSOCategoryCodeKey   = @"CategoryCode";
NSString * const INSOCategoryEventsKey = @"CategoryEvents";
NSString * const INSOStatCategoryKey   = @"StatCategory"; 

#pragma mark - Other constants
const NSInteger INSOExplusionPenaltyTime = (48 * 60);

NSString * const INSOTitleKey = @"title";
NSString * const INSOEventsKey = @"events"; 
NSString * const INSOPenaltyTimeKey = @"penaltyTime"; 
NSString * const INSOPenaltyCountKey = @"penaltyCount";
NSString * const INSOPlayerKey = @"player";
NSString * const INSOStatsKey = @"stats";
NSString * const INSOStatValueKey = @"statValue"; 

@end
