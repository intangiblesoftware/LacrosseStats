//
//  INSOReceiptValidator.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 12/12/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

@import StoreKit;

#import "INSOValidateInAppPurchase.h"
#import "INSOValidateReceipt.h"

#import "INSOMensLacrosseStatsConstants.h"

#import "INSOReceiptValidator.h"


@interface INSOReceiptValidator () <SKRequestDelegate>

@end

@implementation INSOReceiptValidator
- (instancetype)init
{
    self = [super init];
    if (self) {
        // Custom initialization here. 
        _appPurchaseDate = nil;
        _appExpirationDate = nil;
        _appIsPurchased = NO;
    }
    return self;
}

- (BOOL)appPurchaseExpired
{
    NSDate* now = [NSDate date];
    return [self.appExpirationDate compare:now] == NSOrderedAscending;
}

- (void)validateReceipt
{
    INSOValidateInAppPurchase_CheckInAppPurchases(@[INSOMensLacrosseStatsOneYearProductIdentifier], ^(NSString *identifier, BOOL isPresent, NSDictionary *purchaseInfo) {
        if (isPresent) {
            [self processPurchaseInfo:purchaseInfo];
        } else {
            _appPurchaseDate = nil;
            _appIsPurchased = NO;
            _appExpirationDate = nil;
        }
    }, self);
}

- (void)processPurchaseInfo:(NSDictionary*) purchaseInfo
{
    // May have multiple purchase dates, need to get the latest one.
    if (!_appPurchaseDate) {
        _appPurchaseDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    }
    
    NSDate* originalPurchaseDate = purchaseInfo[INSOValidateInAppPurchase_INAPP_ATTRIBUTETYPE_ORIGINALPURCHASEDATE];
    if ([originalPurchaseDate compare:_appPurchaseDate] == NSOrderedDescending) {
        _appPurchaseDate = originalPurchaseDate;
        _appIsPurchased = YES;
        _appExpirationDate = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear value:1 toDate:_appPurchaseDate options:kNilOptions];
    }
}

#pragma mark - SKProductsRequestDelegate
- (void)requestDidFinish:(SKRequest *)request
{
    INSOValidateReceipt_CheckInAppPurchases(@[INSOMensLacrosseStatsOneYearProductIdentifier], ^(NSString *identifier, BOOL isPresent, NSDictionary *purchaseInfo) {
        if (isPresent) {
            [self processPurchaseInfo:purchaseInfo];
        } else {
            _appPurchaseDate = nil;
            _appIsPurchased = NO;
            _appExpirationDate = nil;
        }
    });
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    // Likely unnecessary, but setting anyway.
    _appPurchaseDate = nil;
    _appIsPurchased = NO;
    _appExpirationDate = nil;
}

@end
