//
//  INSOPickerTextField.m
//  ScorebookLite
//
//  Created by James Dabrowski on 9/27/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOPickerTextField.h"

@implementation INSOPickerTextField

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.clipsToBounds = YES;
        [self setRightViewMode:UITextFieldViewModeAlways];
        self.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"down_arrow"]];
    }
    
    return self;
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
    CGRect textRect = [super rightViewRectForBounds:bounds];
    textRect.origin.x -= 10.0;
    return textRect;
}

// When showing picker views to fill in text fields, I don't want to show
// the insertion pointer. So, I'm subclassing the UITextField class just so
// I can eliminate the caretRect of a UITextField.
- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    return CGRectZero;
}

@end
