//
//  INSOEmailStatsViewController.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 11/25/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Game;

@interface INSOEmailStatsViewController : UIViewController

@property (nonatomic) Game* game; 
@property (nonatomic) BOOL isExportingForMaxPreps;

@end
