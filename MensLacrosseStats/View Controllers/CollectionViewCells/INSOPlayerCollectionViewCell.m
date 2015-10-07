//
//  INSOPlayerCollectionViewCell.m
//  MensStatsTracker
//
//  Created by James Dabrowski on 9/28/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "UIColor+INSOScorebookColor.h"

#import "INSOPlayerCollectionViewCell.h"

@implementation INSOPlayerCollectionViewCell

- (void)awakeFromNib
{
    // Taken from: http://pinkstone.co.uk/how-to-build-a-uicollectionview-in-ios-8/
    // standard background (deselected)
    UIView *bgView = [[UIView alloc]initWithFrame:self.bounds];
    self.backgroundView = bgView;
    self.backgroundView.backgroundColor = [UIColor whiteColor];
    self.backgroundView.layer.borderColor = [[UIColor scorebookBlue] CGColor];
    self.backgroundView.layer.borderWidth = 1.0;
    
    // selected background
    UIView *selectedView = [[UIView alloc]initWithFrame:self.bounds];
    self.selectedBackgroundView = selectedView;
    self.selectedBackgroundView.backgroundColor = [UIColor scorebookBlue];
    self.selectedBackgroundView.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.selectedBackgroundView.layer.borderWidth = 1.0;
}

@end
