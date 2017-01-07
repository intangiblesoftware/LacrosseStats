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
@property (nonatomic, assign) BOOL isExportingForBoys;

@end

@implementation INSOGameStatsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[[INSOProductManager sharedManager] appProductName] isEqualToString:INSOMensProductName]) {
        self.isExportingForBoys = YES;
    } else {
        self.isExportingForBoys = NO;
    }

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
    
    // Draws (instead of faceoffs)
    if ([self.game didRecordEvent:INSOEventCodeDrawTaken] && [self.game didRecordEvent:INSOEventCodeDrawControl]) {
        NSInteger homeDrawsTaken = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeDrawTaken] integerValue];
        NSInteger homeDrawControl = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeDrawControl] integerValue];
        CGFloat   homeDrawControlPct = (homeDrawsTaken > 0) ? (CGFloat)homeDrawControl / homeDrawsTaken : 0.0;
        NSString *homeDrawControlPctString = [self.percentFormatter stringFromNumber:@(homeDrawControlPct)];
        
        NSInteger visitorDrawsTaken = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeDrawTaken] integerValue];
        NSInteger visitorDrawControl = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeDrawControl] integerValue];
        CGFloat   visitorDrawControlPct = (visitorDrawsTaken > 0) ? (CGFloat)visitorDrawControl / visitorDrawsTaken : 0.0;
        NSString *visitorDrawControlPctString = [self.percentFormatter stringFromNumber:@(visitorDrawControlPct)];
        
        NSString *homeStatString = [NSString stringWithFormat:@"%@/%@ %@", @(homeDrawControl), @(homeDrawsTaken), homeDrawControlPctString];
        NSString *visitorStatString = [NSString stringWithFormat:@"%@/%@ %@", @(visitorDrawControl), @(visitorDrawsTaken), visitorDrawControlPctString];
        
        [sectionData addObject:@{INSOHomeStatKey:homeStatString, INSOStatNameKey:@"Draws", INSOVisitorStatKey:visitorStatString}];
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
    
    // Man-up (girls call it man-up, boys call it emo. Go figure.)
    if ([self.game didRecordEvent:INSOEventCodeManUp]) {
        NSNumber *homeManUp = [self.eventCounter eventCountForHomeTeam:INSOEventCodeManUp];
        NSNumber *visitorManUp = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeManUp];
        
        [sectionData addObject:@{INSOHomeStatKey:homeManUp, INSOStatNameKey:@"Man-up", INSOVisitorStatKey:visitorManUp}];
    }
    
    // Man-up scoring
    if ([self.game didRecordEvent:INSOEventCodeManUp] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger homeManUpGoals = [[self.eventCounter extraManGoalsForHomeTeam] integerValue];
        NSInteger visitorManUpGoals = [[self.eventCounter extraManGoalsForVisitingTeam] integerValue];
        
        [sectionData addObject:@{INSOHomeStatKey:@(homeManUpGoals), INSOStatNameKey:@"Man-up Scoring", INSOVisitorStatKey:@(visitorManUpGoals)}];
        
        // Just do the emo scoring here while we're at it.
        // EMO scoring = emo goals / emo
        NSInteger homeManUp = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeManUp] integerValue];
        NSInteger visitorManUp = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeManUp] integerValue];
        
        CGFloat homeManUpScoring = (homeManUp > 0) ? (CGFloat)homeManUpGoals / homeManUp : 0.0;
        NSString *homeManUpScoringString = [self.percentFormatter stringFromNumber:@(homeManUpScoring)];
        CGFloat visitorManUpScoring = (visitorManUp > 0) ? (CGFloat)visitorManUpGoals / visitorManUp : 0.0;
        NSString *visitorManUpScoringString = [self.percentFormatter stringFromNumber:@(visitorManUpScoring)];
        
        [sectionData addObject:@{INSOHomeStatKey:homeManUpScoringString, INSOStatNameKey:@"Man-up Scoring", INSOVisitorStatKey:visitorManUpScoringString}];
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
    NSString *sectionTitle;
    self.isExportingForBoys ? (sectionTitle = @"Penalties") : (sectionTitle = @"Fouls");
    penaltySection[INSOSectionTitleKey] = NSLocalizedString(sectionTitle, nil);
    NSMutableArray *sectionData = [NSMutableArray new];
    penaltySection[INSOSectionDataKey] = sectionData;
    
    if (self.isExportingForBoys) {
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
    } else {
        // Fouls
        NSInteger homeFouls = [[self.eventCounter totalFoulsForHomeTeam] integerValue];
        NSInteger visitorFouls = [[self.eventCounter totalFoulsForVisitingTeam] integerValue];
        
        [sectionData addObject:@{INSOHomeStatKey:@(homeFouls), INSOStatNameKey:@"Fouls", INSOVisitorStatKey:@(visitorFouls)}];
        
        // 8-meter awarded
        NSInteger home8m = [[self.eventCounter eventCountForHomeTeam:INSOEventCode8mFreePosition] integerValue];
        NSInteger visitor8m = [[self.eventCounter eventCountForVisitingTeam:INSOEventCode8mFreePosition] integerValue];
        
        [sectionData addObject:@{INSOHomeStatKey:@(home8m), INSOStatNameKey:@"8m (Free Position)", INSOVisitorStatKey:@(visitor8m)}];
        
        // 8-meter shots and goals
        NSNumber *homeFPS = [self.eventCounter freePositionEventCountForHomeTeam:INSOEventCodeShot];
        NSNumber *visitorFPS = [self.eventCounter freePositionEventCountForVisitingTeam:INSOEventCodeShot];
        
        NSNumber *homeFPSOG = [self.eventCounter freePositionEventCountForHomeTeam:INSOEventCodeShotOnGoal];
        NSNumber *visitorFPSOG = [self.eventCounter freePositionEventCountForVisitingTeam:INSOEventCodeShotOnGoal];
        
        NSNumber *homeFPGoal = [self.eventCounter freePositionEventCountForHomeTeam:INSOEventCodeGoal];
        NSNumber *visitorFPGoal = [self.eventCounter freePositionEventCountForVisitingTeam:INSOEventCodeGoal];
        
        NSString *homeStatString = [NSString stringWithFormat:@"%@/%@/%@", homeFPS, homeFPSOG, homeFPGoal];
        NSString *visitorStatString = [NSString stringWithFormat:@"%@/%@/%@", visitorFPS, visitorFPSOG,visitorFPGoal];
        [sectionData addObject:@{INSOHomeStatKey:homeStatString, INSOStatNameKey:@"8m (Free Position)\nShots/SOG/Goals", INSOVisitorStatKey:visitorStatString}];

        // Green cards
        NSInteger homeGreenCards = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeGreenCard] integerValue];
        NSInteger visitorGreenCards = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeGreenCard] integerValue];
        
        [sectionData addObject:@{INSOHomeStatKey:@(homeGreenCards), INSOStatNameKey:@"Green Cards", INSOVisitorStatKey:@(visitorGreenCards)}];
        
        // Yellow cards
        NSInteger homeYellowCards = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeYellowCard] integerValue];
        NSInteger visitorYellowCards = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeYellowCard] integerValue];
        
        [sectionData addObject:@{INSOHomeStatKey:@(homeYellowCards), INSOStatNameKey:@"Yellow Cards", INSOVisitorStatKey:@(visitorYellowCards)}];
        
        // Red cards
        NSInteger homeRedCards = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeRedCard] integerValue];
        NSInteger visitorRedCards = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeRedCard] integerValue];
        
        [sectionData addObject:@{INSOHomeStatKey:@(homeRedCards), INSOStatNameKey:@"Red Cards", INSOVisitorStatKey:@(visitorRedCards)}];
    }
    return penaltySection;
}

- (NSDictionary*)statsDictionaryForPlayer:(RosterPlayer*)rosterPlayer
{
    NSMutableDictionary* statsDictionary = [NSMutableDictionary new];
 /*
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
    
    // Groundballs
    event = [Event eventForCode:INSOEventCodeGroundball inManagedObjectContext:self.managedObjectContext];
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

    // Caused turnover
    event = [Event eventForCode:INSOEventCodeCausedTurnover inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Won faceoff
    event = [Event eventForCode:INSOEventCodeFaceoffWon inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Lost faceoff
    event = [Event eventForCode:INSOEventCodeFaceoffLost inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Goals allowed
    event = [Event eventForCode:INSOEventCodeGoalAllowed inManagedObjectContext:self.managedObjectContext];
    if ([self.game.eventsToRecord containsObject:event]) {
        statTitle = event.title;
        eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        statValueString = [NSString stringWithFormat:@"%@", eventCount];
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:statValueString}];
    }
    
    // Interceptions
    event = [Event eventForCode:INSOEventCodeInterception inManagedObjectContext:self.managedObjectContext];
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
    
    // Now sort those stats by title
    [statsArray sortUsingComparator:^NSComparisonResult(NSDictionary*  _Nonnull stat1, NSDictionary*  _Nonnull stat2) {
        return [stat1[INSOStatTitleKey] compare:stat2[INSOStatTitleKey]];
    }];
    
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
        [statsArray addObject:@{INSOStatTitleKey:statTitle, INSOStatValueKey:penaltyTimeString}];
    }
    */
    [statsDictionary setObject:[NSArray new] forKey:INSOStatsKey];
    
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
    INSOGameStatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:INSOGameStatsCellIdentifier forIndexPath:indexPath];
    
    [self configureGameStatCell:cell atIndexPath:indexPath]; 
    
    return cell;
}


@end
