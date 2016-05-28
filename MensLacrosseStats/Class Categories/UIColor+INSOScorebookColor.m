//
//  UIColor+INSOScorebookColor.m
//  ScorebookLite
//
//  Created by James Dabrowski on 9/27/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "UIColor+INSOScorebookColor.h"

@implementation UIColor (INSOScorebookColor)

+ (UIColor*)scorebookBlue
{
    // rgb(0, 59, 111);
    return [UIColor colorWithRed:0.000 green:0.231 blue:0.435 alpha:1.000];
}

+ (UIColor*)scorebookBackgroundWhite
{
    return [UIColor colorWithRed:0.961 green:0.973 blue:0.980 alpha:1.000];
}

+ (UIColor*)scorebookText
{
    // rgb(19, 45 ,26) ?
    return [UIColor colorWithRed:0.075 green:0.176 blue:0.102 alpha:1.000];
}

+ (UIColor*)scorebookGreen
{
    // rgb(47, 118, 20)
    return [UIColor colorWithRed:0.184 green:0.463 blue:0.078 alpha:1.000];
}

+ (UIColor *)scorebookYellow
{
    // rgb(237, 186, 38);
    return [UIColor colorWithRed:0.925 green:0.733 blue:0.149 alpha:1.000];
}

+ (UIColor *)scorebookRed
{
    // rgb(129, 0, 15);
    return [UIColor colorWithRed:0.506 green:0.000 blue:0.059 alpha:1.000];
}

+ (UIColor *)scorebookTeal
{
    // rgb(0, 128, 128);
    return [UIColor colorWithRed:0.000 green:0.502 blue:0.502 alpha:1.000]; 
}

+ (UIColor *)scorebookBackgroundTeal
{
    // rgb (245, 250, 250)
    return [UIColor colorWithRed:0.961 green:0.980 blue:0.980 alpha:1.000];
}


@end
