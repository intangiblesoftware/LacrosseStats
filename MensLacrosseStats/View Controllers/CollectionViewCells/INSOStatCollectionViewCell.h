//
//  INSOStatCollectionViewCell.h
//  MensStatsTracker
//
//  Created by James Dabrowski on 9/30/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface INSOStatCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel* statNameLabel;
@property (nonatomic, weak) IBOutlet UIImageView* accessoryImageView;

@end
