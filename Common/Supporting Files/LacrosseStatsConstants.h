//
//  INSOMensLacrosseStatsConstant.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 9/29/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LacrosseStatsConstants : NSObject

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

// Product identifier
extern NSString * const INSOMensProductName;
extern NSString * const INSOWomensProductName;
extern NSString * const INSOMensIdentifier;
extern NSString * const INSOWomensIdentifier;

// MaxPreps Company ID
extern NSString * const INSOMaxPrepsMensLacrosseCompanyID;
extern NSString * const INSOMaxPrepsWomensLacrosseCompanyID;


@end
