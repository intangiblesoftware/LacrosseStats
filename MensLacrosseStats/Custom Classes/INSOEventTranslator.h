//
//  INSOEventTranslator.h
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/5/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface INSOEventTranslator : NSObject

- (NSString*)titleForEventCode:(NSNumber*)eventCode;
- (NSString*)titleForCategoryCode:(NSNumber*)categoryCode;
- (NSString*)titleForCategoryAtIndex:(NSInteger)index; 

@end
