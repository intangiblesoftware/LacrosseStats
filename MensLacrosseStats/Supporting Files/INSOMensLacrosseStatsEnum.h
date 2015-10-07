//
//  INSOMensLacrosseStatsEnum.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 9/24/15.
//  Copyright © 2015 Jim Dabrowski. All rights reserved.
//

#ifndef INSOMensLacrosseStats_h
#define INSOMensLacrosseStats_h

typedef NS_ENUM(NSUInteger, INSOCategoryCode) {
    INSOCategoryCodeGameAction     = 1,
    INSOCategoryCodePersonalFouls  = 2,
    INSOCategoryCodeTechnicalFouls = 3,
    INSOCategoryCodeExpulsionFouls = 4
};

typedef NS_ENUM(NSInteger, INSOEventCode) {
    INSOEventCodeGameActions     = 1,
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
    
    INSOEventCodePersonalFouls            = 2,
    INSOEventCodeCrosscheck               = 201,
    INSOEventCodeIllegalBodyCheck         = 202,
    INSOEventCodeCheckInvolvingHeadOrNeck = 203,
    INSOEventCodeIllegalCrosse            = 204,
    INSOEventCodeUseOfIllegalEquipment    = 205,
    INSOEventCodeSlashing                 = 206,
    INSOEventCodeTripping                 = 207,
    INSOEventCodeUnnecessaryRoughness     = 208,
    INSOEventCodeUnsportsmanlikeConduct   = 209,
    
    INSOEventCodeTechnicalFouls            = 3,
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
    
    INSOEventCodeExplusionFouls     = 4,
    INSOEventCodeFighting           = 401,
    INSOEventCodeFlagrantMisconduct = 402,
    INSOEventCodeTobacco            = 403,
};

#endif /* INSOMensLacrosseStats_h */
