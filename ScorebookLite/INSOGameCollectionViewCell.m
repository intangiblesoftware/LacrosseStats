//
//  INSOGameCollectionViewCell.m
//  ScorebookLite
//
//  Created by James Dabrowski on 9/24/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOGameCollectionViewCell.h"

@implementation INSOGameCollectionViewCell

- (void)awakeFromNib
{
    // Taken from: http://pinkstone.co.uk/how-to-build-a-uicollectionview-in-ios-8/
    UIView *bgView = [[UIView alloc]initWithFrame:self.bounds];
    
    self.backgroundView = bgView;
    self.backgroundView.backgroundColor = [UIColor whiteColor];
    self.backgroundView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.backgroundView.layer.borderWidth = 1.0;    
}

@end
