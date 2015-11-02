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
#import "RosterPlayer.h"

typedef NS_ENUM(NSUInteger, INSOStatSourceIndex) {
    INSOStatSourceIndexGame,
    INSOStatSourceIndexPlayer
};

static NSString * const INSOGameStatsCellIdentifier = @"GameStatsCell";

@interface INSOGameStatsViewController () <UITableViewDataSource, UITableViewDelegate>

// IBOutlets
@property (nonatomic, weak) IBOutlet UITableView* statsTable;
@property (nonatomic, weak) IBOutlet UISegmentedControl* statSourceSegmentedControl;

// IBAction
- (IBAction)changeStats:(id)sender;

// Private Properties
@property (nonatomic) INSOGameEventCounter* eventCounter;
@property (nonatomic) NSArray* gameStatsArray;
@property (nonatomic) NSArray* playerStatsArray;
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
    
    self.gameStatsArray = nil;
    self.playerStatsArray = nil;
    [self.statsTable reloadData]; 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Private Properties
- (NSArray*)gameStatsArray
{
    if (!_gameStatsArray) {
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
        
        _gameStatsArray = temp;
    }
    return _gameStatsArray;
}

- (NSArray*)playerStatsArray
{
    if (!_playerStatsArray) {
        NSMutableArray* temp = [NSMutableArray new];
        
        for (RosterPlayer* rosterPlayer in self.game.players) {
            NSDictionary* playerStatsDictionary = [self statsDictionaryForPlayer:rosterPlayer];
            [temp addObject:playerStatsDictionary];
        }
        
        [temp sortUsingComparator:^NSComparisonResult(NSDictionary*  _Nonnull dictionary1, NSDictionary*  _Nonnull dictionary2) {
            RosterPlayer* rp1 = dictionary1[INSOPlayerKey];
            RosterPlayer* rp2 = dictionary2[INSOPlayerKey];
            return [rp1.number compare:rp2.number];
        }];
        
        _playerStatsArray = temp;
    }
    
    return _playerStatsArray;
}

- (INSOGameEventCounter*)eventCounter
{
    if (!_eventCounter) {
        _eventCounter = [[INSOGameEventCounter alloc] initWithGame:self.game];
    }
    return _eventCounter;
}

- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

#pragma mark - IBActions
- (void)changeStats:(id)sender
{
    [self.statsTable reloadData]; 
}

#pragma mark - Private Methods
- (void)configureGameStatCell:(INSOGameStatTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (self.statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndexGame) {
        NSDictionary* sectionDictionary = self.gameStatsArray[indexPath.section];
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
    } else {
        NSDictionary* sectionDictionary = self.playerStatsArray[indexPath.section];
        NSArray* statsArray = sectionDictionary[INSOStatsKey];
        NSDictionary* cellDictionary = statsArray[indexPath.row];
        cell.statNameLabel.text = cellDictionary[INSOTitleKey];
        cell.statCountLabel.text = [NSString stringWithFormat:@"%@", cellDictionary[INSOStatValueKey]];
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

- (NSDictionary*)statsDictionaryForPlayer:(RosterPlayer*)rosterPlayer
{
    NSMutableDictionary* statsDictionary = [NSMutableDictionary new];
    [statsDictionary setObject:rosterPlayer forKey:INSOPlayerKey];
    
    // Now build the player's stats array
    NSMutableArray* statsArray = [NSMutableArray new];
    Event* event;
    NSNumber* eventCount;
    
    // Groundballs
    event = [Event eventForCode:INSOEventCodeGroundball inManagedObjectContext:self.managedObjectContext];
    eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
    [statsArray addObject:@{INSOTitleKey:event.title, INSOStatValueKey:eventCount}];
    
    // Shots
    event = [Event eventForCode:INSOEventCodeShot inManagedObjectContext:self.managedObjectContext];
    eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
    [statsArray addObject:@{INSOTitleKey:event.title, INSOStatValueKey:eventCount}];

    // Goals
    event = [Event eventForCode:INSOEventCodeGoal inManagedObjectContext:self.managedObjectContext];
    eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
    [statsArray addObject:@{INSOTitleKey:event.title, INSOStatValueKey:eventCount}];

    // Assists
    event = [Event eventForCode:INSOEventCodeAssist inManagedObjectContext:self.managedObjectContext];
    eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
    [statsArray addObject:@{INSOTitleKey:event.title, INSOStatValueKey:eventCount}];

    // Shots on goal
    event = [Event eventForCode:INSOEventCodeShotOnGoal inManagedObjectContext:self.managedObjectContext];
    eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
    [statsArray addObject:@{INSOTitleKey:event.title, INSOStatValueKey:eventCount}];

    // Shots
    event = [Event eventForCode:INSOEventCodeSave inManagedObjectContext:self.managedObjectContext];
    eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
    [statsArray addObject:@{INSOTitleKey:event.title, INSOStatValueKey:eventCount}];

    // And now penalties
    
    [statsDictionary setObject:statsArray forKey:INSOStatsKey];
    
    return statsDictionary;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndexGame) {
        return [self.gameStatsArray count];
    } else {
        return [self.playerStatsArray count];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndexGame) {
        NSDictionary* sectionDictionary = self.gameStatsArray[section];
        return [sectionDictionary[INSOEventsKey] count];
    } else {
        NSDictionary* sectionDictionary = self.playerStatsArray[section];
        return [sectionDictionary[INSOStatsKey] count];
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndexGame) {
        NSDictionary* sectionDictionary = self.gameStatsArray[section];
        return sectionDictionary[INSOTitleKey];
    } else {
        NSDictionary* sectionDictionary = self.playerStatsArray[section];
        RosterPlayer* player = sectionDictionary[INSOPlayerKey];
        
        NSString* title;
        if (player.isTeamValue) {
            title = NSLocalizedString(@"Team", nil);
        } else {
            title = [NSString stringWithFormat:@"#%@", player.number];
        }
        return title;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    INSOGameStatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:INSOGameStatsCellIdentifier forIndexPath:indexPath];
    
    [self configureGameStatCell:cell atIndexPath:indexPath]; 
    
    return cell;
}


@end
