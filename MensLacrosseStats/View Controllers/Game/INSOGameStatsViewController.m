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
#import "INSOProductManager.h"

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
static NSString * const INSOPlayerStatsCellIdentifier = @"PlayerStatCell";

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
@property (nonatomic) NSNumberFormatter *percentFormatter;

@end

@implementation INSOGameStatsViewController

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
        
        // Add extra-man events
        NSDictionary *extraManDictionary = [self extraManEvents];
        if (extraManDictionary) {
            [temp addObject:extraManDictionary]; 
        }
        
        // Add penalty sub-array
        NSDictionary* penaltyDictionary = [self penaltyEvents];
        if (penaltyDictionary) {
            [temp addObject:penaltyDictionary];
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
        NSMutableArray* sortedPlayers = [[self.game.players sortedArrayUsingDescriptors:@[sortByNumber]] mutableCopy];
        [sortedPlayers filterUsingPredicate:[NSPredicate predicateWithFormat:@"number >= 0"]];
        
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
        MensLacrosseStatsAppDelegate* appDelegate = (MensLacrosseStatsAppDelegate *)[[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

- (NSNumberFormatter *)percentFormatter
{
    if (!_percentFormatter) {
        _percentFormatter = [NSNumberFormatter new];
        _percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
    }
    return _percentFormatter;
}

#pragma mark - IBActions
- (void)changeStats:(id)sender
{
    [self.statsTable reloadData];

    // Scroll to top of player stats array (if we have somewhere to scroll to)
    if ([self.playerStatsArray count] > 0) {
        [self.statsTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
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
    
    NSArray* statsArray = sectionDictionary[INSOSectionDataKey];
    NSDictionary *cellStats = statsArray[indexPath.row];
    cell.homeStatLabel.text = [NSString stringWithFormat:@"%@", cellStats[INSOHomeStatKey]];
    cell.statNameLabel.text = [NSString stringWithFormat:@"%@", cellStats[INSOStatNameKey]];
    cell.visitorStatLabel.text = [NSString stringWithFormat:@"%@", cellStats[INSOVisitorStatKey]];
}

- (NSDictionary*)fieldingEvents
{
    NSMutableDictionary *fieldingSection = [NSMutableDictionary new];
    
    // Section title
    fieldingSection[INSOSectionTitleKey] = NSLocalizedString(@"Fielding", nil);
    NSMutableArray *sectionData = [NSMutableArray new];
    fieldingSection[INSOSectionDataKey] = sectionData;
    
    // Groundballs
    if ([self.game didRecordEvent:INSOEventCodeGroundball]) {
        NSNumber *homeGroundBalls = [self.eventCounter eventCountForHomeTeam:INSOEventCodeGroundball];
        NSNumber *visitorGroundBalls = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeGroundball];
        [sectionData addObject:@{INSOHomeStatKey:homeGroundBalls, INSOStatNameKey:@"Groundballs", INSOVisitorStatKey:visitorGroundBalls}];
    }
    
    // Faceoffs
    if ([self.game didRecordEvent:INSOEventCodeFaceoffWon] && [self.game didRecordEvent:INSOEventCodeFaceoffLost]) {
        NSInteger homeFaceoffsWon = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeFaceoffWon] integerValue];
        NSInteger homeFaceoffsLost = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeFaceoffLost] integerValue];
        NSInteger homeFaceoffs = homeFaceoffsWon + homeFaceoffsLost;
        CGFloat   homeFaceoffPct = (homeFaceoffs > 0) ? (CGFloat)homeFaceoffsWon / homeFaceoffs : 0.0;
        NSString *homeFaceoffPctString = [self.percentFormatter stringFromNumber:@(homeFaceoffPct)];
        
        NSInteger visitorFaceoffsWon = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeFaceoffWon] integerValue];
        NSInteger visitorFaceoffsLost = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeFaceoffLost] integerValue];
        NSInteger visitorFaceoffs = visitorFaceoffsWon + visitorFaceoffsLost;
        CGFloat   visitorFaceoffPct = (visitorFaceoffs > 0) ? (CGFloat)visitorFaceoffsWon / visitorFaceoffs : 0.0;
        NSString *visitorFaceoffPctString = [self.percentFormatter stringFromNumber:@(visitorFaceoffPct)];
        
        NSString *homeStatString = [NSString stringWithFormat:@"%@/%@ %@", @(homeFaceoffsWon), @(homeFaceoffs), homeFaceoffPctString];
        NSString *visitorStatString = [NSString stringWithFormat:@"%@/%@ %@", @(visitorFaceoffsWon), @(visitorFaceoffs), visitorFaceoffPctString];
        
        [sectionData addObject:@{INSOHomeStatKey:homeStatString, INSOStatNameKey:@"Faceoffs", INSOVisitorStatKey:visitorStatString}];
    }
    
    // Clears
    if ([self.game didRecordEvent:INSOEventCodeClearSuccessful] && [self.game didRecordEvent:INSOEventCodeClearFailed]) {
        NSInteger homeClearSuccessful = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeClearSuccessful] integerValue];
        NSInteger homeClearFailed = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeClearFailed] integerValue];
        NSInteger homeClears = homeClearSuccessful + homeClearFailed;
        CGFloat   homeClearPct = (homeClears > 0) ? (CGFloat)homeClearSuccessful / homeClears : 0.0;
        NSString *homeClearPctString = [self.percentFormatter stringFromNumber:@(homeClearPct)];
        
        NSInteger visitorClearSuccessful = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeClearSuccessful] integerValue];
        NSInteger visitorClearFailed = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeClearFailed] integerValue];
        NSInteger visitorClears = visitorClearSuccessful + visitorClearFailed;
        CGFloat   visitorClearPct = (visitorClears > 0) ? (CGFloat)visitorClearSuccessful / visitorClears : 0.0;
        NSString *visitorClearPctString = [self.percentFormatter stringFromNumber:@(visitorClearPct)];
        
        NSString *homeStatString = [NSString stringWithFormat:@"%@/%@ %@", @(homeClearSuccessful), @(homeClears), homeClearPctString];
        NSString *visitorStatString = [NSString stringWithFormat:@"%@/%@ %@", @(visitorClearSuccessful), @(visitorClears), visitorClearPctString];
        
        [sectionData addObject:@{INSOHomeStatKey:homeStatString, INSOStatNameKey:@"Clears", INSOVisitorStatKey:visitorStatString}];
    }
    
    // Interceptions
    if ([self.game didRecordEvent:INSOEventCodeInterception]) {
        NSNumber *homeInterceptions = [self.eventCounter eventCountForHomeTeam:INSOEventCodeInterception];
        NSNumber *visitorInterceptions = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeInterception];
        
        [sectionData addObject:@{INSOHomeStatKey:homeInterceptions, INSOStatNameKey:@"Interceptions", INSOVisitorStatKey:visitorInterceptions}];
    }
    
    // Turnovers
    if ([self.game didRecordEvent:INSOEventCodeTurnover]) {
        NSNumber *homeTurnovers = [self.eventCounter eventCountForHomeTeam:INSOEventCodeTurnover];
        NSNumber *visitorTurnovers = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeTurnover];
        
        [sectionData addObject:@{INSOHomeStatKey:homeTurnovers, INSOStatNameKey:@"Turnovers", INSOVisitorStatKey:visitorTurnovers}];
    }
    
    // Caused Turnovers
    if ([self.game didRecordEvent:INSOEventCodeCausedTurnover]) {
        NSNumber *homeCausedTurnovers = [self.eventCounter eventCountForHomeTeam:INSOEventCodeCausedTurnover];
        NSNumber *visitorCausedTurnovers = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeCausedTurnover];
        
        [sectionData addObject:@{INSOHomeStatKey:homeCausedTurnovers, INSOStatNameKey:@"Caused Turnover", INSOVisitorStatKey:visitorCausedTurnovers}];
    }
    
    return fieldingSection;
}

- (NSDictionary*)scoringEvents
{
    NSMutableDictionary *scoringSection = [NSMutableDictionary new];
    
    // Section title
    scoringSection[INSOSectionTitleKey] = NSLocalizedString(@"Scoring", nil);
    NSMutableArray *sectionData = [NSMutableArray new];
    scoringSection[INSOSectionDataKey] = sectionData;
    
    // Shots
    if ([self.game didRecordEvent:INSOEventCodeShot]) {
        NSNumber *homeShots = [self.eventCounter eventCountForHomeTeam:INSOEventCodeShot];
        NSNumber *visitorShots = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeShot];
        
        [sectionData addObject:@{INSOHomeStatKey:homeShots, INSOStatNameKey:@"Shots", INSOVisitorStatKey:visitorShots}];
    }

    // Goals
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        NSNumber *homeGoals = [self.eventCounter eventCountForHomeTeam:INSOEventCodeGoal];
        NSNumber *visitorGoals = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeGoal];
        
        [sectionData addObject:@{INSOHomeStatKey:homeGoals, INSOStatNameKey:@"Goals", INSOVisitorStatKey:visitorGoals}];
    }

    // Shooting pct. (Percent of shots that result in a goal)
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger homeShots = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeShot] integerValue];
        NSInteger homeGoals = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeGoal] integerValue];
        CGFloat   homeShootingPct = (homeShots > 0) ? (CGFloat)homeGoals / homeShots : 0.0;
        NSString *homeShootingPctString = [self.percentFormatter stringFromNumber:@(homeShootingPct)];
        
        NSInteger visitorShots = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeShot] integerValue];
        NSInteger visitorGoals = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeGoal] integerValue];
        CGFloat   visitorShootingPct = (visitorShots > 0) ? (CGFloat)visitorGoals / visitorShots : 0.0;
        NSString *visitorShootingPctString = [self.percentFormatter stringFromNumber:@(visitorShootingPct)];
        
        [sectionData addObject:@{INSOHomeStatKey:homeShootingPctString, INSOStatNameKey:@"Shooting Percent\n(Goals / Shots)", INSOVisitorStatKey:visitorShootingPctString}];
    }
    
    // Shots on goal
    if ([self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        NSNumber *homeSOG = [self.eventCounter eventCountForHomeTeam:INSOEventCodeShotOnGoal];
        NSNumber *visitorSOG = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeShotOnGoal];
        
        [sectionData addObject:@{INSOHomeStatKey:homeSOG, INSOStatNameKey:@"Shots on Goal", INSOVisitorStatKey:visitorSOG}];
    }

    // Misses = shots - shots on goal;
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        NSInteger homeShots = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeShot] integerValue];
        NSInteger homeSOG = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeShotOnGoal] integerValue];
        NSInteger homeMisses = homeShots - homeSOG;
        homeMisses = homeMisses < 0 ? 0 : homeMisses;
        
        NSInteger visitorShots = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeShot] integerValue];
        NSInteger visitorSOG = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeShotOnGoal] integerValue];
        NSInteger visitorMisses = visitorShots - visitorSOG;
        visitorMisses = visitorMisses < 0 ? 0 : visitorMisses;
        
        [sectionData addObject:@{INSOHomeStatKey:@(homeMisses), INSOStatNameKey:@"Misses", INSOVisitorStatKey:@(visitorMisses)}];
    }
    
    // Shooting accuracy = shots on goal / shots (what percent of your shots were on goal)
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        NSInteger homeShots = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeShot] integerValue];
        NSInteger homeSOG = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeShotOnGoal] integerValue];
        CGFloat   homeAccuracy = (homeShots > 0) ? (CGFloat)homeSOG / homeShots : 0.0;
        NSString *homeAccuracyString = [self.percentFormatter stringFromNumber:@(homeAccuracy)];
        
        NSInteger visitorShots = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeShot] integerValue];
        NSInteger visitorSOG = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeShotOnGoal] integerValue];
        CGFloat   visitorAccuracy = (visitorShots > 0) ? (CGFloat)visitorSOG / visitorShots : 0.0;
        NSString *visitorAccuracyString = [self.percentFormatter stringFromNumber:@(visitorAccuracy)];
        
        [sectionData addObject:@{INSOHomeStatKey:homeAccuracyString, INSOStatNameKey:@"Shooting Accuracy\n(Shots on Goal / Shots)", INSOVisitorStatKey:visitorAccuracyString}];
    }
    
    // Assists
    if ([self.game didRecordEvent:INSOEventCodeAssist]) {
        NSNumber *homeAssists = [self.eventCounter eventCountForHomeTeam:INSOEventCodeAssist];
        NSNumber *visitorAssists = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeAssist];
        
        [sectionData addObject:@{INSOHomeStatKey:homeAssists, INSOStatNameKey:@"Assists", INSOVisitorStatKey:visitorAssists}];
    }

    // Saves
    if ([self.game didRecordEvent:INSOEventCodeSave]) {
        NSNumber *homeSaves = [self.eventCounter eventCountForHomeTeam:INSOEventCodeSave];
        NSNumber *visitorSaves = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeSave];
        
        [sectionData addObject:@{INSOHomeStatKey:homeSaves, INSOStatNameKey:@"Saves", INSOVisitorStatKey:visitorSaves}];
    }
    
    // Goals allowed
    if ([self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        NSNumber *homeGoalsAllowed = [self.eventCounter eventCountForHomeTeam:INSOEventCodeGoalAllowed];
        NSNumber *visitorGoalsAllowed = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeGoalAllowed];
        
        [sectionData addObject:@{INSOHomeStatKey:homeGoalsAllowed, INSOStatNameKey:@"Goals Allowed", INSOVisitorStatKey:visitorGoalsAllowed}];
    }
    
    // Save pct. = saves / (saves + goals allowed)
    if ([self.game didRecordEvent:INSOEventCodeSave] && [self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        NSInteger homeSaves = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeSave] integerValue];
        NSInteger homeGoalsAllowed = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeGoalAllowed] integerValue];
        CGFloat   homeSavePct = (homeSaves + homeGoalsAllowed) > 0 ? (CGFloat)homeSaves / (homeSaves + homeGoalsAllowed) : 0.0;
        NSString *homeSavePctString = [self.percentFormatter stringFromNumber:@(homeSavePct)];
        
        NSInteger visitorSaves = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeSave] integerValue];
        NSInteger visitorGoalsAllowed = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeGoalAllowed] integerValue];
        CGFloat   visitorSavePct = (visitorSaves + visitorGoalsAllowed) > 0 ? (CGFloat)visitorSaves / (visitorSaves + visitorGoalsAllowed) : 0.0;
        NSString *visitorSavePctString = [self.percentFormatter stringFromNumber:@(visitorSavePct)];
        
        [sectionData addObject:@{INSOHomeStatKey:homeSavePctString, INSOStatNameKey:@"Save Percent", INSOVisitorStatKey:visitorSavePctString}];
    }
    
    return scoringSection;
}

- (NSDictionary *)extraManEvents
{
    NSMutableDictionary *extraManSection = [NSMutableDictionary new];
    
    // Section title
    extraManSection[INSOSectionTitleKey] = NSLocalizedString(@"Extra-Man", nil);
    NSMutableArray *sectionData = [NSMutableArray new];
    extraManSection[INSOSectionDataKey] = sectionData;
    
    // EMO
    if ([self.game didRecordEvent:INSOEventCodeEMO]) {
        NSNumber *homeEMO = [self.eventCounter eventCountForHomeTeam:INSOEventCodeEMO];
        NSNumber *visitorEMO = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeEMO];
        
        [sectionData addObject:@{INSOHomeStatKey:homeEMO, INSOStatNameKey:@"Extra-man Opportunities", INSOVisitorStatKey:visitorEMO}];
    }
    
    // EMO goals
    if ([self.game didRecordEvent:INSOEventCodeEMO] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger homeEMOGoals = [[self.eventCounter extraManGoalsForHomeTeam] integerValue];
        NSInteger visitorEMOGoals = [[self.eventCounter extraManGoalsForVisitingTeam] integerValue];
        
        [sectionData addObject:@{INSOHomeStatKey:@(homeEMOGoals), INSOStatNameKey:@"Extra-man Goals", INSOVisitorStatKey:@(visitorEMOGoals)}];
        
        // Just do the emo scoring here while we're at it.
        // EMO scoring = emo goals / emo
        NSInteger homeEMO = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeEMO] integerValue];
        NSInteger visitorEMO = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeEMO] integerValue];
        
        CGFloat homeEMOScoring = (homeEMO > 0) ? (CGFloat)homeEMOGoals / homeEMO : 0.0;
        NSString *homeEMOScoringString = [self.percentFormatter stringFromNumber:@(homeEMOScoring)];
        CGFloat visitorEMOScoring = (visitorEMO > 0) ? (CGFloat)visitorEMOGoals / visitorEMO : 0.0;
        NSString *visitorEMOScoringString = [self.percentFormatter stringFromNumber:@(visitorEMOScoring)];
        
        [sectionData addObject:@{INSOHomeStatKey:homeEMOScoringString, INSOStatNameKey:@"Extra-man Scoring", INSOVisitorStatKey:visitorEMOScoringString}];
    }
    
    // Man-down
    if ([self.game didRecordEvent:INSOEventCodeManDown]) {
        NSNumber *homeManDown = [self.eventCounter eventCountForHomeTeam:INSOEventCodeManDown];
        NSNumber *visitorManDown = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeManDown];
        
        [sectionData addObject:@{INSOHomeStatKey:homeManDown, INSOStatNameKey:@"Man-down", INSOVisitorStatKey:visitorManDown}];
    }
    
    // Man-down goals allowed
    // A man-down goal allowed is an extra-man goal scored by the other team.
    // Proceed accordingly.
    if ([self.game didRecordEvent:INSOEventCodeManDown] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger homeManDown = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeManDown] integerValue];
        NSInteger visitorManDown = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeManDown] integerValue];
        
        NSInteger homeMDGoalsAllowed = [[self.eventCounter extraManGoalsForVisitingTeam] integerValue];
        NSInteger visitorMDGoalsAllowed = [[self.eventCounter extraManGoalsForHomeTeam] integerValue];
        
        
        CGFloat homeManDownScoring = (homeManDown > 0) ? (CGFloat)homeMDGoalsAllowed / homeManDown : 0.0;
        CGFloat visitorManDownScoring = (visitorManDown > 0) ? (CGFloat)visitorMDGoalsAllowed / visitorManDown : 0.0;
        
        // Man-down scoring = man-down goals allowed / man-down
        NSString *homeManDownScoringString = [self.percentFormatter stringFromNumber:@(homeManDownScoring)];
        NSString *visitorManDownScoringString = [self.percentFormatter stringFromNumber:@(visitorManDownScoring)];
        
        [sectionData addObject:@{INSOHomeStatKey:@(homeMDGoalsAllowed), INSOStatNameKey:@"Man-down Goals Allowed", INSOVisitorStatKey:@(visitorMDGoalsAllowed)}];

        [sectionData addObject:@{INSOHomeStatKey:homeManDownScoringString, INSOStatNameKey:@"Man-down Scoring", INSOVisitorStatKey:visitorManDownScoringString}];
    }
    
    return extraManSection;
}

- (NSDictionary*)penaltyEvents
{
    NSMutableDictionary *penaltySection = [NSMutableDictionary new];
    
    // Section title depends on boys or girls
    NSString *sectionTitle = NSLocalizedString(@"Penalties", nil);
    penaltySection[INSOSectionTitleKey] = NSLocalizedString(sectionTitle, nil);
    NSMutableArray *sectionData = [NSMutableArray new];
    penaltySection[INSOSectionDataKey] = sectionData;
    
    // Penalties
    NSNumber *homePenalties = [self.eventCounter totalPenaltiesForHomeTeam];
    NSNumber *visitorPenalties = [self.eventCounter totalPenaltiesForVisitingTeam];
    
    [sectionData addObject:@{INSOHomeStatKey:homePenalties, INSOStatNameKey:@"Penalties", INSOVisitorStatKey:visitorPenalties}];
    
    // Penalty Time
    NSInteger homePenaltySeconds = [[self.eventCounter totalPenaltyTimeForHomeTeam] integerValue];
    NSInteger visitorPenaltySeconds = [[self.eventCounter totalPenaltyTimeForVisitingTeam] integerValue];
    
    NSDateComponentsFormatter* penaltyTimeFormatter = [[NSDateComponentsFormatter alloc] init];
    penaltyTimeFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropLeading;
    penaltyTimeFormatter.allowedUnits = (NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
    NSString *homePenaltyTimeString = [penaltyTimeFormatter stringFromTimeInterval:homePenaltySeconds];
    NSString *visitorPentaltyTimeString = [penaltyTimeFormatter stringFromTimeInterval:visitorPenaltySeconds];
    
    [sectionData addObject:@{INSOHomeStatKey:homePenaltyTimeString, INSOStatNameKey:@"Penalty Time", INSOVisitorStatKey:visitorPentaltyTimeString}];

    return penaltySection;
}

- (NSDictionary*)statsDictionaryForPlayer:(RosterPlayer*)rosterPlayer
{
    NSMutableDictionary* statsDictionary = [NSMutableDictionary new];
    
    NSString* sectionTitle = [NSString stringWithFormat:@"#%@", rosterPlayer.number];
    [statsDictionary setObject:sectionTitle forKey:INSOSectionTitleKey];
    
    // Now build the  stats array
    NSMutableArray* statsArray = [NSMutableArray new];
    [statsDictionary setObject:statsArray forKey:INSOSectionDataKey];
    
    Event* event;
    NSNumber* eventCount;
    NSString* statTitle;
    NSString* statValueString;
    
    // Groundballs
    event = [Event eventForCode:INSOEventCodeGroundball inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatNameKey:statTitle, INSOHomeStatKey:statValueString}];
    }
    
    // Shots
    event = [Event eventForCode:INSOEventCodeShot inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatNameKey:statTitle, INSOHomeStatKey:statValueString}];
    }

    // Goals
    event = [Event eventForCode:INSOEventCodeGoal inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatNameKey:statTitle, INSOHomeStatKey:statValueString}];
    }

    // Assists
    event = [Event eventForCode:INSOEventCodeAssist inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatNameKey:statTitle, INSOHomeStatKey:statValueString}];
    }

    // Shots on goal
    event = [Event eventForCode:INSOEventCodeShotOnGoal inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatNameKey:statTitle, INSOHomeStatKey:statValueString}];
    }

    // Saves
    event = [Event eventForCode:INSOEventCodeSave inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatNameKey:statTitle, INSOHomeStatKey:statValueString}];
    }

    // Caused turnover
    event = [Event eventForCode:INSOEventCodeCausedTurnover inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatNameKey:statTitle, INSOHomeStatKey:statValueString}];
    }
    
    // Won faceoff
    event = [Event eventForCode:INSOEventCodeFaceoffWon inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatNameKey:statTitle, INSOHomeStatKey:statValueString}];
    }
    
    // Lost faceoff
    event = [Event eventForCode:INSOEventCodeFaceoffLost inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatNameKey:statTitle, INSOHomeStatKey:statValueString}];
    }
    
    // Goals allowed
    event = [Event eventForCode:INSOEventCodeGoalAllowed inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatNameKey:statTitle, INSOHomeStatKey:statValueString}];
    }
    
    // Interceptions
    event = [Event eventForCode:INSOEventCodeInterception inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatNameKey:statTitle, INSOHomeStatKey:statValueString}];
    }
    
    // Turnover
    event = [Event eventForCode:INSOEventCodeTurnover inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatNameKey:statTitle, INSOHomeStatKey:statValueString}];
    }
    
    // And now penalties
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"statCategory == %@ OR statCategory == %@", @(INSOStatCategoryPenalty), @(INSOStatCategoryExpulsion)];
    NSSet* penaltyEventSet = [self.game.eventsToRecord filteredSetUsingPredicate:predicate];
    
    // Just be done
    if ([penaltyEventSet count] > 0) {
        NSNumber* totalPenalties = [self.eventCounter totalPenaltiesForBoysRosterPlayer:rosterPlayer];
        double totalPenaltyTime = [[self.eventCounter totalPenaltyTimeforRosterPlayer:rosterPlayer] doubleValue];
        
        NSDateComponentsFormatter* penaltyTimeFormatter = [[NSDateComponentsFormatter alloc] init];
        penaltyTimeFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropLeading;
        penaltyTimeFormatter.allowedUnits = (NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
        
        NSString* penaltyTimeString = [penaltyTimeFormatter stringFromTimeInterval:totalPenaltyTime];
        if ([totalPenalties integerValue] == 0) {
            statTitle = NSLocalizedString(@"No penalties", nil);
            penaltyTimeString = @"";
        } else if ([totalPenalties integerValue] == 1) {
            NSString* localizedTitle = NSLocalizedString(@"%@ penalty", nil);
            statTitle = [NSString stringWithFormat:localizedTitle, totalPenalties];
        } else {
            NSString* localizedTitle = NSLocalizedString(@"%@ penalties", nil);
            statTitle = [NSString stringWithFormat:localizedTitle, totalPenalties];
        }
        [statsArray addObject:@{INSOStatNameKey:statTitle, INSOHomeStatKey:penaltyTimeString}];
    }

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
    
    NSArray *sectionData = sectionDictionary[INSOSectionDataKey];
    return [sectionData count];
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    INSOGameStatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SectionHeaderCell"];
    cell.statNameLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    INSOGameStatTableViewCell *cell;
    if (self.statSourceSegmentedControl.selectedSegmentIndex == INSOStatSourceIndexGame) {
        cell = [tableView dequeueReusableCellWithIdentifier:INSOGameStatsCellIdentifier forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:INSOPlayerStatsCellIdentifier forIndexPath:indexPath];
    }
    
    [self configureGameStatCell:cell atIndexPath:indexPath];
    
    return cell;
}


@end
