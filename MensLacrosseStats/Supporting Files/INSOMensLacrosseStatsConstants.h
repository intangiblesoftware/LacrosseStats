//
//  INSOMensLacrosseStatsConstant.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 9/29/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface INSOMensLacrosseStatsConstants : NSObject

// User Defaults
extern NSString * const INSODefaultShouldImportCategoriesAndEventsKey;
extern NSString * const INSOExportGameSummaryDefaultKey;
extern NSString * const INSOExportPlayerStatsDefaultKey;
extern NSString * const INSOExportMaxPrepsDefaultKey;

// Import Keys
extern NSString * const INSOEventTitleKey;
extern NSString * const INSOEventCodeKey;
extern NSString * const INSOCategoryTitleKey;
extern NSString * const INSOCategoryCodeKey;
extern NSString * const INSOCategoryEventsKey;
extern NSString * const INSOStatCategoryKey; 

extern const NSInteger INSOExplusionPenaltyTime;

// Some other keys
extern NSString * const INSOTitleKey;
extern NSString * const INSOEventsKey;
extern NSString * const INSOPenaltyTimeKey;
extern NSString * const INSOPenaltyCountKey;
extern NSString * const INSOPlayerKey;
extern NSString * const INSOStatsKey;
extern NSString * const INSOSectionTitleKey; 
extern NSString * const INSOSectionDataKey;
extern NSString * const INSOHomeStatKey;
extern NSString * const INSOVisitorStatKey;
extern NSString * const INSOStatNameKey;

// Product identifier
extern NSString * const INSOMensProductName;
extern NSString * const INSOWomensProductName;
extern NSString * const INSOMensIdentifier;
extern NSString * const INSOWomensIdentifier;

// MaxPreps Company ID
extern NSString * const INSOMaxPrepsMensLacrosseCompanyID;
extern NSString * const INSOMaxPrepsWomensLacrosseCompanyID;


@end
