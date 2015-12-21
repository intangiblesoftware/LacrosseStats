//
//  INSOExportOptionsTableViewController.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 12/18/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol INSOStatsExportDelegate;


@interface INSOExportOptionsTableViewController : UITableViewController

@property (nonatomic, weak) id<INSOStatsExportDelegate> delegate; 

@end

@protocol INSOStatsExportDelegate <NSObject>

- (void)didSelectEmailStats;
- (void)didSelectMaxPrepsExport;

@end