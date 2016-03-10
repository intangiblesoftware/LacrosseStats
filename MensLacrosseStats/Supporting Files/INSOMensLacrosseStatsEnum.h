//
//  INSOMensLacrosseStatsEnum.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 9/24/15.
//  Copyright © 2015 Jim Dabrowski. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef INSOMensLacrosseStats_h
#define INSOMensLacrosseStats_h

typedef NS_ENUM(NSUInteger, INSOCategoryCode) {
    INSOCategoryCodeGameAction     = 100,
    INSOCategoryCodePersonalFouls  = 200,
    INSOCategoryCodeTechnicalFouls = 300,
    INSOCategoryCodeExpulsionFouls = 400
};

typedef NS_ENUM(NSInteger, INSOEventCode) {
    INSOEventCodeGoal            = 101,
    INSOEventCodeAssist          = 102,
    INSOEventCodeSave            = 103,
    INSOEventCodeGroundball      = 104,
    INSOEventCodeFaceoffWon      = 105,
    INSOEventCodeFaceoffLost     = 106,
    INSOEventCodeShot            = 107,
    INSOEventCodeClearSuccessful = 108,
    INSOEventCodeClearFailed     = 109,
    INSOEventCodeTurnover        = 110,
    INSOEventCodeCausedTurnover  = 111,
    INSOEventCodeTimeOut         = 112,
    INSOEventCodeEnteredGame     = 113,
    INSOEventCodeLeftGame        = 114,
    INSOEventCodeEMO             = 115,
    INSOEventCodeGoalAllowed     = 116,
    INSOEventCodeShotOnGoal      = 117,
    INSOEventCodeInterception    = 118,
    INSOEventCodeManDown         = 119,
    
    INSOEventCodeDrawControl     = 151,
    INSOEventCodeDrawPossession  = 152,
    INSOEventCodeDrawTaken       = 153,
    INSOEventCodeManUp           = 153,
    
    INSOEventCodeCrossCheck               = 201,
    INSOEventCodeIllegalBodyCheck         = 202,
    INSOEventCodeCheckInvolvingHeadOrNeck = 203,
    INSOEventCodeIllegalCrosse            = 204,
    INSOEventCodeUseOfIllegalEquipment    = 205,
    INSOEventCodeSlashing                 = 206,
    INSOEventCodeTripping                 = 207,
    INSOEventCodeUnnecessaryRoughness     = 208,
    INSOEventCodeUnsportsmanlikeConduct   = 209,
    
    INSOEventCode8mFreePosition           = 251,
    INSOEventCode8mFreePositionShot       = 252,
    INSOEventCodeMinorFoul                = 253,
    INSOEventCodeGreenCard                = 254,
    INSOEventCodeYellowCard               = 255,
    INSOEventCodeMajorFoul                = 256,
    
    INSOEventCodeCreaseViolation           = 301,
    INSOEventCodeGoalkeeperInterference    = 302,
    INSOEventCodeHolding                   = 303,
    INSOEventCodeIllegalOffensiveScreening = 304,
    INSOEventCodeIllegalProcedure          = 305,
    INSOEventCodeConductFoul               = 306,
    INSOEventCodeInterference              = 307,
    INSOEventCodeOffside                   = 308,
    INSOEventCodePushing                   = 309,
    INSOEventCodeStalling                  = 310,
    INSOEventCodeWardingOff                = 311,
    INSOEventCodeWithholdingBallFromPlay   = 312,
    INSOEventCodeTargetingHeadOrNeck       = 313,
    
    INSOEventCodeFighting           = 401,
    INSOEventCodeFlagrantMisconduct = 402,
    INSOEventCodeTobacco            = 403,
    
    INSOEventCodeRedCard            = 451
};

typedef NS_ENUM(NSInteger, INSOGoalResult) {
    INSOGoalResultNone = -1,
    INSOGoalResultMiss,
    INSOGoalResultSave,
    INSOGoalResultGoal
};

typedef NS_ENUM(NSUInteger, INSOStatCategory) {
    INSOStatCategoryNone,
    INSOStatCategoryFielding,
    INSOStatCategoryScoring,
    INSOStatCategoryPenalty,
    INSOStatCategoryExpulsion
};

#endif /* INSOMensLacrosseStats_h */
