//
//  INSOProductManager.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 12/26/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

@import StoreKit;

#import "INSOValidateReceipt.h"
#import "INSOProductManager.h"

static NSString * const INSOMensLacrosseStatsOneYearProductIdentifier = @"com.intangiblesoftware.menslacrossestats.1year";

@interface INSOProductManager () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

// Private Properties
@property (nonatomic) SKProduct* oneYearProduct;

// Private Methods
- (void)requestProductsFromAppStore;

@end

@implementation INSOProductManager
+ (INSOProductManager *)sharedManager
{
    static INSOProductManager * _sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[INSOProductManager alloc] init];
    });
    return _sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Custom initialization here.
        _appStoreUnavailable = YES;
        _isPurchased = NO;
        _purchaseDate = nil;
        _expirationDate = nil;            
    }
    return self;
}

#pragma mark - Public Properties
- (BOOL)purchaseExpired
{
    NSDate* now = [NSDate date];
    return [_expirationDate compare:now] == NSOrderedAscending;
}

- (NSDecimalNumber*)productPrice
{
    if (self.oneYearProduct) {
        return self.oneYearProduct.price;
    } else {
        return [NSDecimalNumber zero];
    }
}

- (NSString*)productTitle
{
    if (self.oneYearProduct) {
        return self.oneYearProduct.localizedTitle;
    } else {
        return NSLocalizedString(@"Unavailable", nil); 
    }
}

#pragma mark - Public Methods
- (void)validateReceipt
{
    ValidateReceipt_CheckInAppPurchases(@[INSOMensLacrosseStatsOneYearProductIdentifier], ^(NSString *identifier, BOOL isPresent, NSDictionary *purchaseInfo) {
        if (isPresent) {
            NSLog(@"Receipt present. Saving info.");
            // Receipt is present and presumably is valid
            
            // May have multiple purchase dates, need to get the latest one.
            NSDate* originalPurchaseDate = purchaseInfo[ValidateReceipt_INAPP_ATTRIBUTETYPE_ORIGINALPURCHASEDATE];
            _purchaseDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
            if ([originalPurchaseDate compare:_purchaseDate] == NSOrderedDescending) {
                _purchaseDate = originalPurchaseDate;
                _appStoreUnavailable = NO;
                _isPurchased = YES;
                
                NSDateComponents* components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:_purchaseDate];
                components.year += 1;
                _expirationDate = [[NSCalendar currentCalendar] dateFromComponents:components];
            }
        } else {
            // Receipt is not present
            NSLog(@"receipt not present.");
            NSLog(@"Gotta go do something else.");
        }
        
        // Now go get products
        [self requestProductsFromAppStore];
        
    }, self);
}

- (void)purchaseProduct
{
    
}

- (void)restorePurchase
{
    
}

#pragma mark - Private Methods
- (void)requestProductsFromAppStore
{
    // Now kick off a request to iTunes for the products.
    NSSet* productsSet = [NSSet setWithObject:INSOMensLacrosseStatsOneYearProductIdentifier];
    SKProductsRequest* productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productsSet];
    productsRequest.delegate = self;
    [productsRequest start];
}

- (void)completeTransaction:(SKPaymentTransaction*)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)transactionFailed:(SKPaymentTransaction*)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)transactionRestored:(SKPaymentTransaction*)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}
#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    self.oneYearProduct = [response.products firstObject];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    _appStoreUnavailable = YES;
}

#pragma mark - SKPymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for (SKPaymentTransaction* transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                break;
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self transactionFailed:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self transactionRestored:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
                break;
            default:
                break;
        }
    }
}


@end
