//
//  INSOEventFactory.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/3/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOEventFactory.h"

NSString * const INSOEventCodeKey         = @"EventCode";
NSString * const INSOEventTitleKey        = @"EventTitle";
NSString * const INSOCategoryCodeKey      = @"CategoryCode";
NSString * const INSOCategoryTitleKey     = @"CategoryTitle";
NSString * const INSOCategorySortOrderKey = @"SortOrder";
NSString * const INSOCategoryStatsKey     = @"CategoryStats";

typedef NS_ENUM(NSUInteger, CategoryIndex) {
    CategoryIndexGameEvents = 1,
    CategoryIndexPersonalFouls,
    CategoryIndexTechnicalFouls,
    CategoryIndexExpulsionFouls
};

@interface INSOEventFactory ()

@property (nonatomic) NSArray* allEvents;

@property (nonatomic) NSMutableArray* storedCategories;
@property (nonatomic) NSMutableArray* storedEvents;

@property (nonatomic) NSDictionary* eventTitles;
@property (nonatomic) NSDictionary* categoryTitles;

@end

@implementation INSOEventFactory
#pragma mark - Lifecycle
- (instancetype)init
{
    self = [super init];
    
    if (self) {
        // First do the categories
        NSString* path = [[NSBundle mainBundle] bundlePath];
        NSString* categoriesPath = [path stringByAppendingPathComponent:@"Categories.plist"];
        _storedCategories = [[[NSArray alloc] initWithContentsOfFile:categoriesPath] mutableCopy];
        
        // Now sort the categories.
        [_storedCategories sortUsingComparator:^NSComparisonResult(NSDictionary*  _Nonnull category1, NSDictionary*  _Nonnull category2) {
            return [category1[INSOCategorySortOrderKey] compare:category2[INSOCategorySortOrderKey]];
        }];
        
        NSMutableDictionary* tempCategoryTitles = [NSMutableDictionary new];
        for (NSDictionary* categoryDictionary in _storedCategories) {
            [tempCategoryTitles setObject:categoryDictionary[INSOCategoryTitleKey] forKey:categoryDictionary[INSOCategoryCodeKey]];
        }
        self.categoryTitles = tempCategoryTitles;

        // Now do the events
        NSString* eventsPath = [path stringByAppendingPathComponent:@"Events.plist"];
        _storedEvents = [[[NSArray alloc] initWithContentsOfFile:eventsPath] mutableCopy];
        
        NSMutableDictionary* tempEventTitles = [NSMutableDictionary new];
        for (NSDictionary* eventDictionary in _storedEvents) {
            [tempEventTitles setObject:eventDictionary[INSOEventTitleKey] forKey:eventDictionary[INSOEventCodeKey]];
        }
        self.eventTitles = tempEventTitles; 
    }
    
    return self;
}

- (NSArray*)allEvents
{
    if (!_allEvents) {
        // Now put all events into sub-arrays
        NSMutableArray* actionEventCodes        = [NSMutableArray new];
        NSMutableArray* personalFoulEventCodes  = [NSMutableArray new];
        NSMutableArray* technicalFoulEventCodes = [NSMutableArray new];
        NSMutableArray* expulsionFoulEventCodes = [NSMutableArray new];
        
        for (NSDictionary* eventDictionary in self.storedEvents) {
            switch ([eventDictionary[INSOCategoryCodeKey] integerValue]) {
                case CategoryIndexGameEvents:
                    [actionEventCodes addObject:eventDictionary[INSOEventCodeKey]];
                    break;
                case CategoryIndexPersonalFouls:
                    [personalFoulEventCodes addObject:eventDictionary[INSOEventCodeKey]];
                    break;
                case CategoryIndexTechnicalFouls:
                    [technicalFoulEventCodes addObject:eventDictionary[INSOEventCodeKey]];
                    break;
                case CategoryIndexExpulsionFouls:
                    [expulsionFoulEventCodes addObject:eventDictionary[INSOEventCodeKey]];
                    break;
                default:
                    break;
            }
        }
        
        // Now sort each sub-array
        [actionEventCodes sortUsingComparator:^NSComparisonResult(NSNumber*  _Nonnull eventCode1, NSNumber*  _Nonnull eventCode2) {
            return [[self titleForEventCode:eventCode1] compare:[self titleForEventCode:eventCode2]];
        }];
        
        [personalFoulEventCodes sortUsingComparator:^NSComparisonResult(NSNumber*  _Nonnull eventCode1, NSNumber*  _Nonnull eventCode2) {
            return [[self titleForEventCode:eventCode1] compare:[self titleForEventCode:eventCode2]];
        }];
        
        [technicalFoulEventCodes sortUsingComparator:^NSComparisonResult(NSNumber*  _Nonnull eventCode1, NSNumber*  _Nonnull eventCode2) {
            return [[self titleForEventCode:eventCode1] compare:[self titleForEventCode:eventCode2]];
        }];
        
        [expulsionFoulEventCodes sortUsingComparator:^NSComparisonResult(NSNumber*  _Nonnull eventCode1, NSNumber*  _Nonnull eventCode2) {
            return [[self titleForEventCode:eventCode1] compare:[self titleForEventCode:eventCode2]];
        }];

        // Now add each sub-array to main array, if they have events
        NSMutableArray* tempAllEvents = [NSMutableArray new];
        
        if ([actionEventCodes count] > 0) {
            NSDictionary* dictionary = @{INSOCategoryCodeKey:[NSNumber numberWithInt:1],INSOCategoryStatsKey:actionEventCodes};
            [tempAllEvents addObject:dictionary];
        }
        
        if ([personalFoulEventCodes count] > 0) {
            NSDictionary* dictionary = @{INSOCategoryCodeKey:[NSNumber numberWithInt:2],INSOCategoryStatsKey:personalFoulEventCodes};
            [tempAllEvents addObject:dictionary];
        }
        
        if ([technicalFoulEventCodes count] > 0) {
            NSDictionary* dictionary = @{INSOCategoryCodeKey:[NSNumber numberWithInt:3],INSOCategoryStatsKey:technicalFoulEventCodes};
            [tempAllEvents addObject:dictionary];
        }
        
        if ([expulsionFoulEventCodes count] > 0) {
            NSDictionary* dictionary = @{INSOCategoryCodeKey:[NSNumber numberWithInt:4],INSOCategoryStatsKey:expulsionFoulEventCodes};
            [tempAllEvents addObject:dictionary];
        }
        
        _allEvents = tempAllEvents;
    }
    
    return _allEvents;
}

#pragma mark - Public Method
- (NSArray*)eventArray
{
    return [self.allEvents copy];
}

- (NSArray*)eventArrayForGame:(Game*)game
{
    return [NSArray new];
}

- (NSString*)titleForEventCode:(NSNumber *)eventCode
{
    return self.eventTitles[eventCode];
}

- (NSString*)titleForCategoryCode:(NSNumber *)categoryCode
{
    return self.categoryTitles[categoryCode];
}

@end

