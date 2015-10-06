//
//  INSOEventArrayFactory.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/3/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOEventArrayFactory.h"

static NSString * EventCodeKey = @"EventCode";
static NSString * EventTitleKey = @"EventTitle";
static NSString * CategoryCodeKey = @"CategoryCode";
static NSString * CategoryTitleKey = @"CategoryTitle";
static NSString * CategorySortOrderKey = @"SortOrder";

typedef NS_ENUM(NSUInteger, CategoryIndex) {
    CategoryIndexGameEvents = 1,
    CategoryIndexPersonalFouls,
    CategoryIndexTechnicalFouls,
    CategoryIndexExpulsionFouls
};

@interface INSOEventArrayFactory ()

@property (nonatomic) NSMutableArray* storedCategories;
@property (nonatomic) NSMutableArray* storedEvents;

@end

@implementation INSOEventArrayFactory
#pragma mark - Lifecycle
- (instancetype)init
{
    self = [super init];
    
    if (self) {
        // First do the categories
        NSString* path = [[NSBundle mainBundle] bundlePath];
        NSString* categoriesPath = [path stringByAppendingString:@"Categories.plist"];
        _storedCategories = [[[NSArray alloc] initWithContentsOfFile:categoriesPath] mutableCopy];
        
        // Now sort the categories.
        [_storedCategories sortUsingComparator:^NSComparisonResult(NSDictionary*  _Nonnull category1, NSDictionary*  _Nonnull category2) {
            return [category1[CategorySortOrderKey] compare:category2[CategorySortOrderKey]];
        }];

        // Now do the events
        NSString* eventsPath = [path stringByAppendingPathComponent:@"Events.plist"];
        NSArray* tempEvents  = [[[NSArray alloc] initWithContentsOfFile:eventsPath] mutableCopy];
        tempEvents = [tempEvents sortedArrayUsingComparator:^NSComparisonResult(NSDictionary*  _Nonnull event1, NSDictionary*  _Nonnull event2) {
            return [event1[EventTitleKey] compare:event2[EventTitleKey]];
        }];
        
        // Now put all events into sub-arrays
        NSMutableArray* actionEventCodes        = [NSMutableArray new];
        NSMutableArray* personalFoulEventCodes  = [NSMutableArray new];
        NSMutableArray* technicalFoulEventCodes = [NSMutableArray new];
        NSMutableArray* expulsionFoulEventCodes = [NSMutableArray new];
        
        for (NSDictionary* eventDictionary in tempEvents) {
            switch ([eventDictionary[CategoryCodeKey] integerValue]) {
                case CategoryIndexGameEvents:
                    [actionEventCodes addObject:eventDictionary[EventCodeKey]];
                    break;
                case CategoryIndexPersonalFouls:
                    [personalFoulEventCodes addObject:eventDictionary[EventCodeKey]];
                    break;
                case CategoryIndexTechnicalFouls:
                    [technicalFoulEventCodes addObject:eventDictionary[EventCodeKey]];
                    break;
                case CategoryIndexExpulsionFouls:
                    [expulsionFoulEventCodes addObject:eventDictionary[EventCodeKey]];
                    break;
                default:
                    break;
            }
        }
        
        // Now sort each sub-array and put into all events
        _storedEvents = [NSMutableArray new];
        if ([actionEventCodes count] > 0) {
//            [actionEventCodes sortUsingComparator:^NSComparisonResult(NSNumber*  _Nonnull number1, NSNumber*  _Nonnull number2) {
//                return [number1 compare:number2];
//            }];
            [_storedEvents addObject:actionEventCodes];
        }
        
        if ([personalFoulEventCodes count] > 0) {
//            [personalFoulEventCodes sortUsingComparator:^NSComparisonResult(NSNumber*  _Nonnull number1, NSNumber*  _Nonnull number2) {
//                return [number1 compare:number2];
//            }];
            [_storedEvents addObject:personalFoulEventCodes];
        }
        
        if ([technicalFoulEventCodes count] > 0) {
//            [technicalFoulEventCodes sortUsingComparator:^NSComparisonResult(NSNumber*  _Nonnull number1, NSNumber*  _Nonnull number2) {
//                return [number1 compare:number2];
//            }];
            [_storedEvents addObject:technicalFoulEventCodes];
        }

        if ([expulsionFoulEventCodes count] > 0) {
//            [expulsionFoulEventCodes sortUsingComparator:^NSComparisonResult(NSNumber*  _Nonnull number1, NSNumber*  _Nonnull number2) {
//                return [number1 compare:number2];
//            }];
            [_storedEvents addObject:expulsionFoulEventCodes];
        }
    }
    
    return self;
}

#pragma mark - Public Method
- (NSArray*)allEvents
{
    return [self.storedEvents copy];
}

- (NSArray*)eventsForGame:(Game*)game
{
    return [NSArray new];
}

@end

