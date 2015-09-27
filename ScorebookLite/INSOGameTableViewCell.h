//
//  INSOGameTableViewCell.h
//  ScorebookLite
//
//  Created by James Dabrowski on 9/26/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface INSOGameTableViewCell : UITableViewCell
// IBOutlets
@property (nonatomic, weak) IBOutlet UILabel* gameDateTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel* homeTeamLabel;
@property (nonatomic, weak) IBOutlet UILabel* visitingTeamLabel;
@property (nonatomic, weak) IBOutlet UILabel* homeScoreLabel;
@property (nonatomic, weak) IBOutlet UILabel* visitingScoreLabel;
@property (nonatomic, weak) IBOutlet UILabel* locationLabel; 

@end
