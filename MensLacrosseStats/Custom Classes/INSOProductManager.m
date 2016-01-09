//
//  INSOProductManager.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 12/26/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

@import StoreKit;

#import "INSOMensLacrosseStatsConstants.h"

#import "INSOProductManager.h"

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

}

- (void)purchaseProduct
{
    if (self.oneYearProduct && !self.appStoreUnavailable) {
        SKPayment* payment = [SKPayment paymentWithProduct:self.oneYearProduct];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

- (void)restorePurchase
{
    // Just tell they payment queue to restore transactions.
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)refreshProducts
{
    [self requestProductsFromAppStore];
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

#pragma mark - INSOProductPurchaseDelegate
- (void)completeTransaction:(SKPaymentTransaction*)transaction
{
    [self validateReceipt];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    if ([self.delegate respondsToSelector:@selector(transactionCompleted)]) {
        [self.delegate transactionCompleted];
    }
}

- (void)transactionFailed:(SKPaymentTransaction*)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    if ([self.delegate respondsToSelector:@selector(transactionFailed)]) {
        [self.delegate transactionFailed];
    }
}

- (void)transactionRestored:(SKPaymentTransaction*)transaction
{
    [self validateReceipt];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    if ([self.delegate respondsToSelector:@selector(transactionRestored)]) {
        [self.delegate transactionRestored];
    }
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    _appStoreUnavailable = NO;
    self.oneYearProduct = [response.products firstObject];
    
    if ([self.delegate respondsToSelector:@selector(productsRefreshed)]) {
        [self.delegate productsRefreshed];
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    _appStoreUnavailable = YES;
    
    if ([self.delegate respondsToSelector:@selector(productsRefreshed)]) {
        [self.delegate productsRefreshed];
    }
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
