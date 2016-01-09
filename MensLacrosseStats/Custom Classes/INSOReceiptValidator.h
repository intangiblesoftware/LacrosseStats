//
//  INSOReceiptValidator.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 12/12/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface INSOReceiptValidator : NSObject

@property (nonatomic, readonly) BOOL    appIsPurchased;
@property (nonatomic, readonly) NSDate *appPurchaseDate;
@property (nonatomic, readonly) NSDate *appExpirationDate;
@property (nonatomic, readonly) BOOL    appPurchaseExpired;

- (void)validateReceipt; 

@end

