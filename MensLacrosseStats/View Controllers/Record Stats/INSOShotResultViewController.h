//
//  INSOShotResultViewController.h
//  Scorebook
//
//  Created by Jim Dabrowski on 3/26/15.
//  Copyright (c) 2015 IntangibleSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RosterPlayer;
@class Event;

#import "INSOMensLacrosseStatsEnum.h"

@interface INSOShotResultViewController : UIViewController

@property (nonatomic) RosterPlayer* rosterPlayer;

@property (nonatomic, assign) INSOGoalResult initialResultSegment;
@property (nonatomic) BOOL is8mShot; 

@end
