//
//  INSOGameStatsViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/29/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "NSManagedObject+GameEventAggregate.h"

#import "MensLacrosseStatsAppDelegate.h"

#import "INSOGameStatsViewController.h"
#import "INSOMensLacrosseStatsConstants.h"
#import "INSOGameStatTableViewCell.h"
#import "INSOGameEventCounter.h"

#import "Game.h"
#import "EventCategory.h"
#import "Event.h"
#import "GameEvent.h"

static NSString * const INSOGameStatsCellIdentifier = @"GameStatsCell";

@interface INSOGameStatsViewController () <UITableViewDataSource, UITableViewDelegate>
// IBOutlets
@property (nonatomic, weak) IBOutlet UITableView* statsTable;

// Private Properties
@property (nonatomic) INSOGameEventCounter* eventCounter;
@property (nonatomic) NSArray* eventStatsArray;
@property (nonatomic) NSManagedObjectContext* managedObjectContext;

@end

@implementation INSOGameStatsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.eventStatsArray = nil;
    [self.statsTable reloadData]; 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Private Properties
- (NSArray*)eventStatsArray
{
    if (!_eventStatsArray) {
        NSMutableArray* temp = [NSMutableArray new];
        
        // Add fielding sub-array
        NSDictionary* fieldingDictionary = [self fieldingEvents];
        if (fieldingDictionary) {
            [temp addObject:fieldingDictionary];
        }
        
        // Add scoring sub-array
        NSDictionary* scoringDictionary = [self scoringEvents];
        if (scoringDictionary) {
            [temp addObject:scoringDictionary];
        }
        
        // Add penalty sub-array
        [temp addObject:[self penaltyEvents]];
        
        _eventStatsArray = temp;
    }
    return _eventStatsArray;
}

- (INSOGameEventCounter*)eventCounter
{
    if (!_eventCounter) {
        _eventCounter = [[INSOGameEventCounter alloc] initWithGame:self.game];
    }
    return _eventCounter;
}

#pragma mark - Private Methods
- (void)configureGameStatCell:(INSOGameStatTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* sectionDictionary = self.eventStatsArray[indexPath.section];
    
    if ([sectionDictionary[INSOTitleKey] isEqualToString:NSLocalizedString(@"Penalties", nil)]) {
        NSNumber* penaltyCount = sectionDictionary[INSOPenaltyCountKey];
        NSString* penaltiesString;
        if ([penaltyCount integerValue] == 1) {
            penaltiesString = NSLocalizedString(@"penalty", nil);
        } else {
            penaltiesString = NSLocalizedString(@"penalties", nil);
        }
        
        cell.statNameLabel.text = [NSString stringWithFormat:@"%@ %@", penaltyCount, penaltiesString];
        
        double penaltyTime = [sectionDictionary[INSOPenaltyTimeKey] doubleValue];
        NSDateComponentsFormatter* penaltyTimeFormatter = [[NSDateComponentsFormatter alloc] init];
        penaltyTimeFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropLeading;
        penaltyTimeFormatter.allowedUnits = (NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
        
        cell.statCountLabel.text = [penaltyTimeFormatter stringFromTimeInterval:penaltyTime];
        
    } else {
        NSArray* eventsArray = sectionDictionary[INSOEventsKey];
        Event* event = [eventsArray objectAtIndex:indexPath.row];
        cell.statNameLabel.text = event.title;
        cell.statCountLabel.text = [NSString stringWithFormat:@"%@", [self.eventCounter eventCount:event.eventCodeValue]];
    }
}

- (NSDictionary*)fieldingEvents
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"statCategory == %@", @(INSOStatCategoryFielding)];
    NSSet* fieldingEventsSet = [self.game.eventsToRecord filteredSetUsingPredicate:predicate];
    
    // Just be done if we don't have any fielding events to report
    if ([fieldingEventsSet count] == 0) {
        return nil;
    }

    NSMutableDictionary* fieldingDictionary = [NSMutableDictionary new];
    [fieldingDictionary setObject:NSLocalizedString(@"Fielding", nil) forKey:INSOTitleKey];
    
    NSArray* fieldingEvents = [[[self.game.eventsToRecord filteredSetUsingPredicate:predicate] allObjects] sortedArrayUsingComparator:^NSComparisonResult(Event*  _Nonnull event1, Event*  _Nonnull event2) {
        return [event1.title compare:event2.title];
    }];
    
    [fieldingDictionary setObject:fieldingEvents forKey:INSOEventsKey];
    
    return fieldingDictionary;
}

- (NSDictionary*)scoringEvents
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"statCategory == %@", @(INSOStatCategoryScoring)];
    NSSet* scoringEventsSet = [self.game.eventsToRecord filteredSetUsingPredicate:predicate];
    
    // Just be done if we don't have any fielding events to report
    if ([scoringEventsSet count] == 0) {
        return nil;
    }
    
    NSMutableDictionary* scoringDictionary = [NSMutableDictionary new];
    [scoringDictionary setObject:NSLocalizedString(@"Scoring", nil) forKey:INSOTitleKey];
    
    NSArray* scoringEvents = [[[self.game.eventsToRecord filteredSetUsingPredicate:predicate] allObjects] sortedArrayUsingComparator:^NSComparisonResult(Event*  _Nonnull event1, Event*  _Nonnull event2) {
        return [event1.title compare:event2.title];
    }];
    
    [scoringDictionary setObject:scoringEvents forKey:INSOEventsKey];
    
    return scoringDictionary;
}

- (NSDictionary*)penaltyEvents
{
    NSNumber* penaltyCount = [self.eventCounter totalPenalties];
    NSNumber* penaltyTime = [self.eventCounter totalPenaltyTime];
    
    NSString* title = NSLocalizedString(@"Penalties", nil);
    
    return @{INSOTitleKey:title, INSOPenaltyCountKey:penaltyCount, INSOPenaltyTimeKey:penaltyTime, INSOEventsKey:@[@"Should I really be doing this?"]};
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.eventStatsArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary* sectionDictionary = self.eventStatsArray[section];
    return [sectionDictionary[INSOEventsKey] count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary* sectionDictionary = self.eventStatsArray[section];
    return sectionDictionary[INSOTitleKey];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    INSOGameStatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:INSOGameStatsCellIdentifier forIndexPath:indexPath];
    
    [self configureGameStatCell:cell atIndexPath:indexPath]; 
    
    return cell;
}


@end
