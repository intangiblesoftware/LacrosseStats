//
//  INSOMensLacrosseStatsConstants.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 9/29/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOMensLacrosseStatsConstants.h"

@implementation INSOMensLacrosseStatsConstants

#pragma mark - User Defaults
NSString * const INSODefaultShouldImportCategoriesAndEventsKey = @"INSOShouldImportCategoriesKey";
NSString * const INSOExportGameSummaryDefaultKey               = @"INSOExportGameSummaryDefaultKey";
NSString * const INSOExportPlayerStatsDefaultKey               = @"INSOExportPlayerStatsDefaultKey";
NSString * const INSOExportMaxPrepsDefaultKey                  = @"INSOExportMaxPrepsDefaultKey";

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
NSString * const INSOSectionTitleKey = @"sectionTitle";
NSString * const INSOSectionDataKey = @"sectionData";
NSString * const INSOHomeStatKey = @"homeStat";
NSString * const INSOVisitorStatKey = @"visitorStat";
NSString * const INSOStatNameKey = @"statName";

#pragma mark - Product Identifier
NSString * const INSOMensProductName = @"Men’s Lacrosse Stats";
NSString * const INSOWomensProductName = @"Women’s Lacrosse Stats";
NSString * const INSOMensIdentifier = @"com.intangiblesoftware.menslacrossestats";
NSString * const INSOWomensIdentifier = @"com.intangiblesoftware.womenslacrossestats";

#pragma mark - Company identifiers
NSString * const INSOMaxPrepsMensLacrosseCompanyID = @"9bfb842d-9e44-45f2-9bf8-203e2847bb66";
NSString * const INSOMaxPrepsWomensLacrosseCompanyID = @"f6bb6836-2849-4f23-807d-e4e275d0e785"; 


@end
