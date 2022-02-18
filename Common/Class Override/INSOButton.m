//
//  INSOButton.m
//  LacrosseStats
//
//  Created by James Dabrowski on 6/28/16.
//  Copyright © 2016 Intangible Software. All rights reserved.
//

#import "INSOButton.h"

@implementation INSOButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _borderColor = [UIColor clearColor];
        _borderWidth = 0.0;
        _cornerRadius = 0.0;
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        _borderColor = [UIColor clearColor];
        _borderWidth = 0.0;
        _cornerRadius = 0.0;
    }
    
    return self;
}

- (instancetype)init
{
    self = [super init];
    return self; 
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    _borderWidth = borderWidth;
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;
}

- (void)drawRect:(CGRect)rect
{
    self.layer.cornerRadius = self.cornerRadius;
    self.layer.borderWidth = self.borderWidth;
    self.layer.borderColor = [self.borderColor CGColor];
    self.layer.masksToBounds = YES; 
}


@end
