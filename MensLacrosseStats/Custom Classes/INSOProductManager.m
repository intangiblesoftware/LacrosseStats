//
//  INSOProductManager.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 12/26/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

@import StoreKit;

#import "INSOMensLacrosseStatsConstants.h"
#import "INSOReceiptValidator.h"
#import "INSOProductManager.h"

@interface INSOProductManager () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

// Private Properties
@property (nonatomic) INSOReceiptValidator* receiptValidator;
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
        _canPurchaseProduct = NO;
        
        _receiptValidator = [[INSOReceiptValidator alloc] init];
        [_receiptValidator validateReceipt];
    }
    
    return self;
}

#pragma mark - Public Properties
- (BOOL)productIsPurchased
{
#if DEBUG
    return YES;
#else
    return self.receiptValidator.appIsPurchased;
#endif
}

- (BOOL)productPurchaseExpired
{
#if DEBUG
    return NO;
#else
    return self.receiptValidator.appPurchaseExpired;
#endif
}

- (NSDate*)productPurchaseDate
{
#if DEBUG
    return [NSDate date];
#else
    return self.receiptValidator.appPurchaseDate;
#endif
}

- (NSDate*)productExpirationDate
{
#if DEBUG
    return [NSDate date];
#else
    return self.receiptValidator.appExpirationDate;
#endif
}

- (NSDecimalNumber*)productPrice
{
#if DEBUG
    return [NSDecimalNumber decimalNumberWithString:@"99.95"];
#else
    if (self.oneYearProduct) {
        return self.oneYearProduct.price;
    } else {
        return [NSDecimalNumber zero];
    }
#endif
}

- (NSString*)productTitle
{
    if (self.oneYearProduct) {
        return self.oneYearProduct.localizedTitle;
    } else {
        return NSLocalizedString(@"Unavailable", nil); 
    }
}

- (NSString *)appProductName
{
    if ([self.oneYearProduct.productIdentifier isEqualToString:INSOMensLacrosseStatsOneYearProductIdentifier]) {
        return INSOMensProductName;
    } else {
        return INSOWomensProductName;
    }
}

#pragma mark - Public Methods
- (void)purchaseProduct
{
    if (self.oneYearProduct && self.canPurchaseProduct) {
        SKPayment* payment = [SKPayment paymentWithProduct:self.oneYearProduct];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

- (void)restorePurchase
{
    // Just tell they payment queue to restore transactions.
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)refreshProduct
{
    [self.receiptValidator validateReceipt];
    
    [self requestProductsFromAppStore];
}

#pragma mark - Private Properties

#pragma mark - Private Methods
- (void)requestProductsFromAppStore
{
    // Now kick off a request to iTunes for the products.
    NSString* productIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ProductIdentifier"];
    NSSet* productsSet = [NSSet setWithObject:productIdentifier];
    SKProductsRequest* productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productsSet];
    productsRequest.delegate = self;
    [productsRequest start];
}

#pragma mark - INSOProductPurchaseDelegate
- (void)completeTransaction:(SKPaymentTransaction*)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    [self.receiptValidator validateReceipt];
    
    if ([self.delegate respondsToSelector:@selector(didPurchaseProduct)]) {
        [self.delegate didPurchaseProduct];
    }
}

- (void)transactionFailed:(SKPaymentTransaction*)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    if ([self.delegate respondsToSelector:@selector(productPurchaseFailed)]) {
        [self.delegate productPurchaseFailed];
    }
}

- (void)transactionRestored:(SKPaymentTransaction*)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    [self.receiptValidator validateReceipt];
    
    if ([self.delegate respondsToSelector:@selector(didRestorePurchase)]) {
        [self.delegate didRestorePurchase];
    }
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    _canPurchaseProduct = YES;
    self.oneYearProduct = [response.products firstObject];
    
    if ([self.delegate respondsToSelector:@selector(didRefreshProduct)]) {
        [self.delegate didRefreshProduct];
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    _canPurchaseProduct = NO;
    if ([self.delegate respondsToSelector:@selector(didRefreshProduct)]) {
        [self.delegate didRefreshProduct];
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

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [self.receiptValidator validateReceipt];
    
    if ([self.delegate respondsToSelector:@selector(didRestorePurchase)]) {
        [self.delegate didRestorePurchase];
    }
}


@end
