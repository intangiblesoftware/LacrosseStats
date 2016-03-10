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

#import "INSOWomensInApp.h"
#import "INSOWomensReceipt.h"

#import "INSOMensLacrosseStatsConstants.h"

#import "INSOReceiptValidator.h"

static NSString * const INSOMensBundleIdentifier = @"com.intangiblesoftware.menslacrossestats";
static NSString * const INSOWomensBundleIdentifier = @"com.intangiblesoftware.womenslacrossestats";

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
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID isEqualToString:INSOMensBundleIdentifier]) {
        INSOValidateInAppPurchase_CheckInAppPurchases(@[INSOMensLacrosseStatsOneYearProductIdentifier], ^(NSString *identifier, BOOL isPresent, NSDictionary *purchaseInfo) {
            if (isPresent) {
                [self processPurchaseInfo:purchaseInfo];
            } else {
                _appPurchaseDate = nil;
                _appIsPurchased = NO;
                _appExpirationDate = nil;
            }
        }, self);
    } else if ([bundleID isEqualToString:INSOWomensBundleIdentifier]) {
        INSOWomensInApp_CheckInAppPurchases(@[INSOWomensLacrosseStatsOneYearProductIdentifier], ^(NSString *identifier, BOOL isPresent, NSDictionary *purchaseInfo) {
            if (isPresent) {
                [self processPurchaseInfo:purchaseInfo];
            } else {
                _appPurchaseDate = nil;
                _appIsPurchased = NO;
                _appExpirationDate = nil;
            }
        }, self);
    }
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
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID isEqualToString:INSOMensBundleIdentifier]) {
        INSOValidateReceipt_CheckInAppPurchases(@[INSOMensLacrosseStatsOneYearProductIdentifier], ^(NSString *identifier, BOOL isPresent, NSDictionary *purchaseInfo) {
            if (isPresent) {
                [self processPurchaseInfo:purchaseInfo];
            } else {
                _appPurchaseDate = nil;
                _appIsPurchased = NO;
                _appExpirationDate = nil;
            }
        });
    } else if ([bundleID isEqualToString:INSOWomensBundleIdentifier]) {
        INSOWomensReceipt_CheckInAppPurchases(@[INSOWomensLacrosseStatsOneYearProductIdentifier], ^(NSString *identifier, BOOL isPresent, NSDictionary *purchaseInfo) {
            if (isPresent) {
                [self processPurchaseInfo:purchaseInfo];
            } else {
                _appPurchaseDate = nil;
                _appIsPurchased = NO;
                _appExpirationDate = nil; 
            }
        });
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    // Likely unnecessary, but setting anyway.
    _appPurchaseDate = nil;
    _appIsPurchased = NO;
    _appExpirationDate = nil;
}

@end
