//
//  INSOProductManager.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 12/26/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol INSOProductManagerDelegate;

@interface INSOProductManager : NSObject

+(instancetype)sharedManager;

@property (nonatomic, weak) id<INSOProductManagerDelegate> delegate;
// Public Properties
@property (nonatomic, readonly) BOOL canPurchaseProduct;

@property (nonatomic, readonly) BOOL productIsPurchased;
@property (nonatomic, readonly) BOOL productPurchaseExpired;

@property (nonatomic, readonly) NSDate *productPurchaseDate;
@property (nonatomic, readonly) NSDate *productExpirationDate;

@property (nonatomic, readonly) NSDecimalNumber *productPrice;
@property (nonatomic, readonly) NSString        *productTitle;

// Public Methods
- (void)refreshProduct;
- (void)purchaseProduct;
- (void)restorePurchase;

@end

@protocol INSOProductManagerDelegate <NSObject>

- (void)didRefreshProduct;
- (void)didPurchaseProduct;
- (void)productPurchaseFailed;
- (void)didRestorePurchase; 

@end