//
//  INSOButton.h
//  LacrosseStats
//
//  Created by James Dabrowski on 6/28/16.
//  Copyright © 2016 Intangible Software. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface INSOButton : UIButton

@property (nonatomic, strong) IBInspectable UIColor *borderColor;
@property (nonatomic, assign) IBInspectable CGFloat  borderWidth;
@property (nonatomic, assign) IBInspectable CGFloat  cornerRadius;

@end
