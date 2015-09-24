//
//  ScorebookLiteEnum.h
//  ScorebookLite
//
//  Created by James Dabrowski on 9/24/15.
//  Copyright © 2015 Jim Dabrowski. All rights reserved.
//

#ifndef ScorebookLiteEnum_h
#define ScorebookLiteEnum_h

typedef NS_ENUM(NSInteger, EventCode) {
    EventCodeGameActions     = 1,
    EventCodeGoal            = 101,
    EventCodeAssist          = 102,
    EventCodeSave            = 103,
    EventCodeGroundball      = 104,
    EventCodeFaceoffWon      = 105,
    EventCodeFaceoffLost     = 106,
    EventCodeShot            = 107,
    EventCodeClearSuccessful = 108,
    EventCodeClearFailed     = 109,
    EventCodeTurnover        = 110,
    EventCodeCausedTurnover  = 111,
    EventCodeTimeOut         = 112,
    EventCodeEnteredGame     = 113,
    EventCodeLeftGame        = 114,
    EventCodeEMO             = 115,
    EventCodeGoalAllowed     = 116,
    EventCodeShotOnGoal      = 117,
    
    EventCodePersonalFouls            = 2,
    EventCodeCrosscheck               = 201,
    EventCodeIllegalBodyCheck         = 202,
    EventCodeCheckInvolvingHeadOrNeck = 203,
    EventCodeIllegalCrosse            = 204,
    EventCodeUseOfIllegalEquipment    = 205,
    EventCodeSlashing                 = 206,
    EventCodeTripping                 = 207,
    EventCodeUnnecessaryRoughness     = 208,
    EventCodeUnsportsmanlikeConduct   = 209,
    
    EventCodeTechnicalFouls            = 3,
    EventCodeCreaseViolation           = 301,
    EventCodeGoalkeeperInterference    = 302,
    EventCodeHolding                   = 303,
    EventCodeIllegalOffensiveScreening = 304,
    EventCodeIllegalProcedure          = 305,
    EventCodeConductFoul               = 306,
    EventCodeInterference              = 307,
    EventCodeOffside                   = 308,
    EventCodePushing                   = 309,
    EventCodeStalling                  = 310,
    EventCodeWardingOff                = 311,
    EventCodeWithholdingBallFromPlay   = 312,
    EventCodeTargetingHeadOrNeck       = 313,
    
    EventCodeExplusionFouls     = 4,
    EventCodeFighting           = 401,
    EventCodeFlagrantMisconduct = 402,
    EventCodeTobacco            = 403,
};

typedef NS_ENUM(NSUInteger, EventCategory) {
    EventCategoryGameAction    = 1,
    EventCategoryPersonalFoul  = 2,
    EventCategoryTechnicalFoul = 3,
    EventCategoryExpulsionFoul = 4
};

#endif /* ScorebookLiteEnum_h */
