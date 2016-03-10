//
//  INSOWomensGameStatsViewController.m
//
//
//  Created by James Dabrowski on 10/29/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "NSManagedObject+GameEventAggregate.h"

#import "WomensAppDelegate.h"

#import "INSOWomensGameStatsViewController.h"
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

@interface INSOWomensGameStatsViewController () <UITableViewDataSource, UITableViewDelegate>

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

@implementation INSOWomensGameStatsViewController

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
        NSDictionary* foulDictionary = [self foulEvents];
        if (foulDictionary) {
            [temp addObject:foulDictionary];
        }
        
        _gameStatsArray = temp;
    }
    return _gameStatsArray;
}

- (NSArray*)playerStatsArray
{
    if (!_playerStatsArray) {
        NSMutableArray* temp = [NSMutableArray new];
        
        NSSortDescriptor* sortByNumber = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
        NSArray* sortedPlayers = [self.game.players sortedArrayUsingDescriptors:@[sortByNumber]];

        for (RosterPlayer* rosterPlayer in sortedPlayers) {
            NSDictionary* playerStatsDictionary = [self statsDictionaryForPlayer:rosterPlayer];
            [temp addObject:playerStatsDictionary];
        }
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
        WomensAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
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
    NSDictionary* sectionDictionary;
    if (self.statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndexGame) {
        sectionDictionary = self.gameStatsArray[indexPath.section];
    } else {
        sectionDictionary = self.playerStatsArray[indexPath.section];
    }
    
    NSArray* statsArray = sectionDictionary[INSOStatsKey];
    NSDictionary* cellDictionary = statsArray[indexPath.row];
    cell.statNameLabel.text = cellDictionary[INSOStatTitleKey];
    cell.statCountLabel.text = cellDictionary[INSOStatValueKey];
}

- (NSDictionary*)fieldingEvents
{
    // First, make sure we have events to report
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"statCategory == %@", @(INSOStatCategoryFielding)];
    NSSet* fieldingEventsSet = [self.game.eventsToRecord filteredSetUsingPredicate:predicate];
    
    // Just be done if we don't have any fielding events to report
    if ([fieldingEventsSet count] == 0) {
        return nil;
    }

    // Do the section title
    NSMutableDictionary* fieldingDictionary = [NSMutableDictionary new];
    [fieldingDictionary setObject:NSLocalizedString(@"Fielding", nil) forKey:INSOSectionTitleKey];
    
    // Now do the events
    NSArray* fieldingEvents = [[[self.game.eventsToRecord filteredSetUsingPredicate:predicate] allObjects] sortedArrayUsingComparator:^NSComparisonResult(Event*  _Nonnull event1, Event*  _Nonnull event2) {
        return [event1.title compare:event2.title];
    }];
    
    NSMutableArray* fieldingStats = [NSMutableArray new];
    for (Event* event in fieldingEvents) {
        NSNumber* eventCount = [self.eventCounter eventCount:event.eventCodeValue];
        [fieldingStats addObject:@{INSOStatTitleKey:event.title, INSOStatValueKey:[NSString stringWithFormat:@"%@", eventCount]}];
    }
    [fieldingDictionary setObject:fieldingStats forKey:INSOStatsKey];
    
    return fieldingDictionary;
}

- (NSDictionary*)scoringEvents
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"statCategory == %@", @(INSOStatCategoryScoring)];
    NSSet* scoringEventsSet = [self.game.eventsToRecord filteredSetUsingPredicate:predicate];
    
    // Just be done if we don't have any scoring events to report
    if ([scoringEventsSet count] == 0) {
        return nil;
    }
    
    NSMutableDictionary* scoringDictionary = [NSMutableDictionary new];
    [scoringDictionary setObject:NSLocalizedString(@"Scoring", nil) forKey:INSOSectionTitleKey];
    
    // Now do the events
    NSArray* scoringEvents = [[[self.game.eventsToRecord filteredSetUsingPredicate:predicate] allObjects] sortedArrayUsingComparator:^NSComparisonResult(Event*  _Nonnull event1, Event*  _Nonnull event2) {
        return [event1.title compare:event2.title];
    }];
    
    NSMutableArray* scoringStats = [NSMutableArray new];
    for (Event* event in scoringEvents) {
        NSNumber* eventCount = [self.eventCounter eventCount:event.eventCodeValue];
        [scoringStats addObject:@{INSOStatTitleKey:event.title, INSOStatValueKey:[NSString stringWithFormat:@"%@", eventCount]}];
    }
    [scoringDictionary setObject:scoringStats forKey:INSOStatsKey];
    
    return scoringDictionary;
}

- (NSDictionary*)foulEvents
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"statCategory == %@ OR statCategory == %@", @(INSOStatCategoryPenalty), @(INSOStatCategoryExpulsion)];
    NSSet* foulEventSet = [self.game.eventsToRecord filteredSetUsingPredicate:predicate];
    
    // Just be done
    if ([foulEventSet count] == 0) {
        return nil;
    }
    
    NSMutableDictionary* foulDictionary = [NSMutableDictionary new];
    [foulDictionary setObject:NSLocalizedString(@"Fouls", nil) forKey:INSOSectionTitleKey];
    
    // And now penalties
    NSArray* foulEvents = [[[self.game.eventsToRecord filteredSetUsingPredicate:predicate] allObjects] sortedArrayUsingComparator:^NSComparisonResult(Event*  _Nonnull event1, Event*  _Nonnull event2) {
        return [event1.title compare:event2.title];
    }];
    
    NSMutableArray* foulStats = [NSMutableArray new];
    for (Event* event in foulEvents) {
        NSNumber* eventCount = [self.eventCounter eventCount:event.eventCodeValue];
        [foulStats addObject:@{INSOStatTitleKey:event.title, INSOStatValueKey:[NSString stringWithFormat:@"%@", eventCount]}];
    }
    [foulDictionary setObject:foulStats forKey:INSOStatsKey];
    
    return foulDictionary;
}

- (NSDictionary*)statsDictionaryForPlayer:(RosterPlayer*)rosterPlayer
{
    NSMutableDictionary* statsDictionary = [NSMutableDictionary new];
    
    NSString* sectionTitle;
    if (rosterPlayer.isTeamValue) {
        sectionTitle = NSLocalizedString(@"Team", nil);
    } else {
        sectionTitle = [NSString stringWithFormat:@"#%@", rosterPlayer.number];
    }
    [statsDictionary setObject:sectionTitle forKey:INSOSectionTitleKey];
    
    // Now build the  stats array
    NSMutableArray* statsArray = [NSMutableArray new];
    Event* event;
    NSNumber* eventCount;
    NSString* statTitle;
    NSString* statValueString;
    
    // Draws taken
    event = [Event eventForCode:INSOEventCodeDrawTaken inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Draw control
    event = [Event eventForCode:INSOEventCodeDrawControl inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Draw possessions
    event = [Event eventForCode:INSOEventCodeDrawPossession inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Groundballs
    event = [Event eventForCode:INSOEventCodeGroundball inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Turnover
    event = [Event eventForCode:INSOEventCodeTurnover inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Caused turnover
    event = [Event eventForCode:INSOEventCodeCausedTurnover inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Shots
    event = [Event eventForCode:INSOEventCodeShot inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }

    // Goals
    event = [Event eventForCode:INSOEventCodeGoal inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }

    // Assists
    event = [Event eventForCode:INSOEventCodeAssist inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }

    // Shots on goal
    event = [Event eventForCode:INSOEventCodeShotOnGoal inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }

    // Saves
    event = [Event eventForCode:INSOEventCodeSave inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }

    // Fouls
    event = [Event eventForCode:INSOEventCodeMinorFoul inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Green cards
    event = [Event eventForCode:INSOEventCodeGreenCard inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Yellow cards
    event = [Event eventForCode:INSOEventCodeYellowCard inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Red cards
    event = [Event eventForCode:INSOEventCodeRedCard inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // 8m free position
    event = [Event eventForCode:INSOEventCode8mFreePosition inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // 8m free position shots
    event = [Event eventForCode:INSOEventCode8mFreePositionShot inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Now sort those stats by title
//    [statsArray sortUsingComparator:^NSComparisonResult(NSDictionary*  _Nonnull stat1, NSDictionary*  _Nonnull stat2) {
//        return [stat1[INSOStatTitleKey] compare:stat2[INSOStatTitleKey]];
//    }];
    
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
    NSDictionary* sectionDictionary;
    if (self.statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndexGame) {
        sectionDictionary = self.gameStatsArray[section];
    } else {
        sectionDictionary = self.playerStatsArray[section];
    }
    
    return [sectionDictionary[INSOStatsKey] count];
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary* sectionDictionary;
    if (self.statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndexGame) {
        sectionDictionary = self.gameStatsArray[section];
    } else {
        sectionDictionary = self.playerStatsArray[section];
    }
    
    return sectionDictionary[INSOSectionTitleKey];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    INSOGameStatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:INSOGameStatsCellIdentifier forIndexPath:indexPath];
    
    [self configureGameStatCell:cell atIndexPath:indexPath]; 
    
    return cell;
}


@end
