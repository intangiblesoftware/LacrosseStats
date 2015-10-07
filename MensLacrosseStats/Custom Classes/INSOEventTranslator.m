//
//  INSOEventTranslator.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/5/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOEventTranslator.h"

static NSString * EventCodeKey = @"EventCode";
static NSString * EventTitleKey = @"EventTitle";
static NSString * CategoryCodeKey = @"CategoryCode";
static NSString * CategoryTitleKey = @"CategoryTitle";
static NSString * CategorySortOrderKey = @"SortOrder";

@interface INSOEventTranslator ()

@property (nonatomic) NSMutableDictionary* events;
@property (nonatomic) NSArray* categories;

@end

@implementation INSOEventTranslator
#pragma mark - Lifecycle
- (instancetype)init
{
    self = [super init];
    
    if (self) {
        // First do the categories
        NSString* path = [[NSBundle mainBundle] bundlePath];
        NSString* categoriesPath = [path stringByAppendingPathComponent:@"Categories.plist"];
        _categories = [[NSArray alloc] initWithContentsOfFile:categoriesPath];
        
        // And now the events
        NSString* eventsPath = [path stringByAppendingPathComponent:@"Events.plist"];
        NSArray* storedEvents = [[NSArray alloc] initWithContentsOfFile:eventsPath];

        _events = [NSMutableDictionary new];
        for (NSDictionary* eventDictionary in storedEvents) {
            [_events setObject:eventDictionary[EventTitleKey] forKey:eventDictionary[EventCodeKey]];
        }
    }
    
    return self;
}

#pragma mark - Public Methods
- (NSString*)titleForCategoryCode:(NSNumber *)categoryCode
{
    return @"foo";
}

- (NSString*)titleForCategoryAtIndex:(NSInteger)index
{
    NSDictionary* categoryDictionary = self.categories[index];
    return categoryDictionary[CategoryTitleKey];
}

- (NSString*)titleForEventCode:(NSNumber *)eventCode
{
    return self.events[eventCode];
}

@end
