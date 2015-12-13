//
//  INSOReceiptValidator.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 12/12/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOReceiptValidator.h"

@interface INSOReceiptValidator ()

@end

@implementation INSOReceiptValidator
- (instancetype)init
{
    self = [super init];
    if (self) {
        // Custom initialization here. 
        NSInteger random = arc4random_uniform(100);
        _appIsPurchased = random >= 50;
        
        if (_appIsPurchased) {
            NSDate* now = [NSDate date];
            NSInteger purchasedDaysAgo = arc4random_uniform(365);
                        
            _appPurchaseDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:-purchasedDaysAgo toDate:now options:kNilOptions];
            _appExpirationDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear value:1 toDate:_appPurchaseDate options:kNilOptions];
        }
    }
    return self;
}

- (BOOL)appPurchaseExpired
{
    NSDate* now = [NSDate date];
    return [_appExpirationDate compare:now] == NSOrderedAscending;
}

- (void)validateReceipt
{
    // Do something here to validate?
    // Probably yes eventually, but not now.
    NSInteger random = arc4random_uniform(100);
    _appIsPurchased = random >= 50;
    
    if (_appIsPurchased) {
        NSDate* now = [NSDate date];
        NSInteger purchasedDaysAgo = arc4random_uniform(2 * 365);
        
        _appPurchaseDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:-purchasedDaysAgo toDate:now options:kNilOptions];
        _appExpirationDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear value:1 toDate:_appPurchaseDate options:kNilOptions];
    }
    
    if (_appIsPurchased) {
        NSLog(@"App was purchased on %@ and will expire on %@.", _appPurchaseDate, _appExpirationDate);
    } else {
        NSLog(@"App is not purchased");
    }

}

@end
