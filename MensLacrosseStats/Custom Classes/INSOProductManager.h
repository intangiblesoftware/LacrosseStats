//
//  INSOProductManager.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 12/26/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol INSOProductPurchaseDelegate;

@interface INSOProductManager : NSObject

+(instancetype)sharedManager;

@property (nonatomic, weak) id<INSOProductPurchaseDelegate> delegate;

@property (nonatomic, readonly) BOOL    appStoreUnavailable; 

@property (nonatomic, readonly) BOOL    isPurchased;
@property (nonatomic, readonly) BOOL    purchaseExpired;

@property (nonatomic, readonly) NSDate* purchaseDate;
@property (nonatomic, readonly) NSDate* expirationDate;

@property (nonatomic, readonly) NSDecimalNumber* productPrice;
@property (nonatomic, readonly) NSString* productTitle;

- (void)refreshProducts; 

- (void)validateReceipt;

- (void)purchaseProduct;
- (void)restorePurchase;

@end

@protocol INSOProductPurchaseDelegate <NSObject>

- (void)productsRefreshed; 
- (void)transactionCompleted;
- (void)transactionFailed;
- (void)transactionRestored; 

@end