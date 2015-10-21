//
//  INSOPenaltyTimeViewController.h
//  Scorebook
//
//  Created by Jim Dabrowski on 3/18/15.
//  Copyright (c) 2015 IntangibleSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Event.h"

@class RosterPlayer;

@interface INSOPenaltyTimeViewController : UIViewController

@property (nonatomic) RosterPlayer* rosterPlayer;

@property (nonatomic) Event* event;

@end
