//
//  INSOGameStatTableViewCell.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/29/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface INSOGameStatTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *statNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *homeStatLabel;
@property (nonatomic, weak) IBOutlet UILabel *visitorStatLabel;

@end
