//
//  INSOEventInterpreter.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/3/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOEventInterpreter.h"

static NSString * EventCodeKey = @"EventCode";
static NSString * EventTitleKey = @"EventTitle";
static NSString * CategoryCodeKey = @"CategoryCode";
static NSString * CategoryTitleKey = @"CategoryTitle";
static NSString * CategorySortOrderKey = @"SortOrder";

@interface INSOEventInterpreter ()

@property (nonatomic) NSDictionary* eventsDictionary;
@property (nonatomic) NSArray* categoriesArray;

@end

@implementation INSOEventInterpreter
#pragma mark - Lifecycle
- (instancetype)init
{
    self = [super init];
    
    if (self) {
        // Get the events from the plist
        NSString* path = [[NSBundle mainBundle] bundlePath];
        NSString* eventsPath = [path stringByAppendingPathComponent:@"Events.plist"];
        _eventsDictionary = [[NSDictionary alloc] initWithContentsOfFile:eventsPath];
        
        // And the categories
        NSString* categoriesPath = [path stringByAppendingString:@"Categories.plist"];
        _categoriesArray = [[NSArray alloc] initWithContentsOfFile:categoriesPath];

        // Now the all events array
        _allEventCodes = [_eventsDictionary allKeys];
        
        // And the all categories array
        NSMutableArray* categoryCodesArray = [NSMutableArray new];
        for (NSDictionary* categoryDictionary in _categoriesArray) {
            NSNumber* categoryCode = categoryDictionary[CategoryCodeKey];
            [categoryCodesArray addObject:categoryCode];
        }
        _allCategories = [categoryCodesArray copy];
    }
    return self;
}

#pragma mark - Public Method
- (NSString*)titleForEventCode:(INSOEventCode)eventCode
{
    NSString* eventCodeString = [NSString stringWithFormat:@"%@", @(eventCode)];
    NSDictionary* eventDictionary = [self.eventsDictionary objectForKey:eventCodeString];
    return eventDictionary[EventTitleKey];
}

- (NSString*)titleForCateogoryCode:(INSOCategoryCode)categoryCode
{
    NSString* title;
    
    for (NSDictionary* categoryDictionary in self.categoriesArray) {
        if ([categoryDictionary[CategoryCodeKey] integerValue] == categoryCode) {
            title = categoryDictionary[CategoryTitleKey];
        }
    }
    
    return title;
}

- (INSOCategoryCode)categoryCodeForEvent:(INSOEventCode)eventCode
{
    NSString* eventCodeString = [NSString stringWithFormat:@"%@", @(eventCode)];
    NSDictionary* eventDictionary = [self.eventsDictionary objectForKey:eventCodeString];
    return eventDictionary[CategoryCodeKey];
}


@end
