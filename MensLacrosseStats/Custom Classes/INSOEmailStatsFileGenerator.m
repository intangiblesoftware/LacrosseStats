//
//  INSOEmailStatsFileGenerator.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 11/27/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//
#import <UIKit/UIKit.h>

#import "INSOEmailStatsFileGenerator.h"
#import "INSOGameEventCounter.h"
#import "INSOMensLacrosseStatsConstants.h"
#import "INSOMensLacrosseStatsEnum.h"
#import "INSOProductManager.h"

#import "Game.h"
#import "Event.h"
#import "EventCategory.h"
#import "RosterPlayer.h"

@interface INSOEmailStatsFileGenerator ()

@property (nonatomic) BOOL shouldExportPenalties;
@property (nonatomic) BOOL isExportingForBoys;

@property (nonatomic) NSArray *maxPrepsBoysEvents;
@property (nonatomic) NSArray *maxPrepsGirlsEvents;

@property (nonatomic) NSArray *playersArray;

@property (nonatomic) NSNumberFormatter *percentFormatter;

@end

@implementation INSOEmailStatsFileGenerator
#pragma mark - Lifecycle
- (instancetype)init
{
    self = [self initWithGame:nil];
    return self;
}

- (instancetype)initWithGame:(Game*)game
{
    self = [super init];
    
    if (self) {
        _game = game;
        
        if ([[[INSOProductManager sharedManager] appProductName] isEqualToString:INSOMensProductName]) {
            _isExportingForBoys = YES;
        } else {
            _isExportingForBoys = NO;
        }
        
        // First create the array of event codes for events recorded in the game
        // This will vary from boys to girls
        NSPredicate* predicate;
        if (_isExportingForBoys) {
            predicate = [NSPredicate predicateWithFormat:@"categoryCode == %@", @(INSOCategoryCodeGameAction)];
        } else {
            predicate = [NSPredicate predicateWithFormat:@"categoryCode != %@", @(INSOCategoryCodeTechnicalFouls)];
        }
        
        // Now figure out if we should export penalties
        NSPredicate* penaltyPredicate = [NSPredicate predicateWithFormat:@"categoryCode != %@", @(INSOCategoryCodeGameAction)];
        NSSet* penaltyEvents = [_game.eventsToRecord filteredSetUsingPredicate:penaltyPredicate];
        _shouldExportPenalties = [penaltyEvents count] > 0;
    }
    
    return self;
}

#pragma mark - Public interface

- (void)createGameSummaryData:(completion)completion
{
    NSMutableString *fileContents = [[NSMutableString alloc] init];
    
    [fileContents appendString:[self gameStatsFileHeader]];
    [fileContents appendString:[self gameStatsFieldingSection]];
    [fileContents appendString:[self gameStatsScoringSection]];
    [fileContents appendString:[self gameStatsExtraManSection]];
    [fileContents appendString:[self gameStatsPenaltySection]];
    [fileContents appendString:[self gameStatsFileFooter]];
    
    UIPrintPageRenderer *pageRenderer = [[UIPrintPageRenderer alloc] init];
    CGRect pageFrame = CGRectMake(0.0, 36.0, 612, 828); // 612 x 792 = us letter in pixels
    [pageRenderer setValue:[NSValue valueWithCGRect:pageFrame] forKey:@"paperRect"];
    [pageRenderer setValue:[NSValue valueWithCGRect:pageFrame] forKey:@"printableRect"];
    
    UIPrintFormatter *printFormatter = [[UIMarkupTextPrintFormatter alloc] initWithMarkupText:fileContents];
    [UIPrintInteractionController sharedPrintController].printFormatter = printFormatter;
    
    [pageRenderer addPrintFormatter:printFormatter startingAtPageAtIndex:0];
    
    NSMutableData *gameSummaryData = [NSMutableData new];
    UIGraphicsBeginPDFContextToData(gameSummaryData, CGRectZero, nil);
    UIGraphicsBeginPDFPage();
    [pageRenderer drawPageAtIndex:0 inRect:UIGraphicsGetPDFContextBounds()];
    UIGraphicsEndPDFContext();
    
    completion(gameSummaryData);
}

- (void)createPlayerStatsData:(completion)completion
{
    NSMutableArray *gameStatsArray = [NSMutableArray new];
    
    // Create header row
    NSArray *header = [self headerRowForPlayerStats];
    [gameStatsArray addObject:[header componentsJoinedByString:@","]];
    
    // Create player stats rows
    for (RosterPlayer* rosterPlayer in self.playersArray) {
        if (!rosterPlayer.isTeamValue) {
            NSArray* dataRow = [self dataRowForPlayer:rosterPlayer];
            [gameStatsArray addObject:[dataRow componentsJoinedByString:@","]];
        }
    }

    // Convert to string
    NSString *playerStatsString = [gameStatsArray componentsJoinedByString:@"\n"];
    
    // Send it on back
    NSData* playerStatsData = [playerStatsString dataUsingEncoding:NSUTF8StringEncoding];
    completion(playerStatsData);
}

- (void)createMaxPrepsGameStatsData:(completion)completion
{
    if (self.isExportingForBoys) {
        [self createBoysMaxPrepsGameStatsFile:^(NSData *gameStatsData) {
            completion(gameStatsData);
        }];
    } else {
        [self createGirlsMaxPrepsGameStatsFile:^(NSData *gameStatsData) {
            completion(gameStatsData);
        }];
    }
}

#pragma mark - Private Properties
- (NSArray *)playersArray
{
    if (!_playersArray) {
        // And now player numbers, but only players. Not team players
        NSSortDescriptor* sortByNumber = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
        _playersArray = [_game.players sortedArrayUsingDescriptors:@[sortByNumber]];
        NSPredicate *nonTeamPredicate = [NSPredicate predicateWithFormat:@"number >= 0"];
        _playersArray = [_playersArray filteredArrayUsingPredicate:nonTeamPredicate];
    }
    return _playersArray;
}

- (NSNumberFormatter *)percentFormatter
{
    if (!_percentFormatter) {
        _percentFormatter = [NSNumberFormatter new];
        _percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
    }
    return _percentFormatter;
}

- (void)createBoysMaxPrepsGameStatsFile:(completion)completion
{
    NSMutableArray* gameStatsArray = [NSMutableArray new];
    
    // First line is company ID
    [gameStatsArray addObject:INSOMaxPrepsMensLacrosseCompanyID];
    
    // Then comes the header (maxPreps style!)
    NSArray* headerRow = [self maxPrepsBoysHeaderRow];
    [gameStatsArray addObject:[headerRow componentsJoinedByString:@"|"]];
    
    // Now data rows for each person in the game (but not the team player!)
    for (RosterPlayer* rosterPlayer in self.playersArray) {
        if (!rosterPlayer.isTeamValue) {
            NSArray* dataRow = [self maxPrepsBoysDataRowForPlayer:rosterPlayer];
            [gameStatsArray addObject:[dataRow componentsJoinedByString:@"|"]];
        }
    }
    
    // Now convert entire array to string
    NSString* maxPrepsStatsString = [gameStatsArray componentsJoinedByString:@"\n"];
    
    // Now call the completion block
    NSData* maxPrepsData = [maxPrepsStatsString dataUsingEncoding:NSUTF8StringEncoding];
    completion(maxPrepsData);
}

- (void)createGirlsMaxPrepsGameStatsFile:(completion)completion
{
    NSMutableArray* gameStatsArray = [NSMutableArray new];
    
    // First line is company ID
    [gameStatsArray addObject:INSOMaxPrepsWomensLacrosseCompanyID];
    
    // Then comes the header (maxPreps style!)
    NSArray* headerRow = [self maxPrepsGirlsHeaderRow];
    [gameStatsArray addObject:[headerRow componentsJoinedByString:@"|"]];
    
    // Now data rows for each person in the game (but not the team player!)
    for (RosterPlayer* rosterPlayer in self.playersArray) {
        if (!rosterPlayer.isTeamValue) {
            NSArray* dataRow = [self maxPrepsGirlsDataRowForPlayer:rosterPlayer];
            [gameStatsArray addObject:[dataRow componentsJoinedByString:@"|"]];
        }
    }
    
    // Now convert entire array to string
    NSString* maxPrepsStatsString = [gameStatsArray componentsJoinedByString:@"\n"];
    
    // Now call the completion block
    NSData* maxPrepsData = [maxPrepsStatsString dataUsingEncoding:NSUTF8StringEncoding];
    completion(maxPrepsData);
}

- (NSArray *)maxPrepsBoysEvents
{
    if (!_maxPrepsBoysEvents) {
        NSMutableSet* maxPrepsBoysEventSet = [NSMutableSet new];
        
        Event* event;
        
        // goals
        event = [Event eventForCode:INSOEventCodeGoal inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsBoysEventSet addObject:event];
        
        // assists
        event = [Event eventForCode:INSOEventCodeAssist inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsBoysEventSet addObject:event];
        
        // shots on goal
        event = [Event eventForCode:INSOEventCodeShotOnGoal inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsBoysEventSet addObject:event];
        
        // groundballs
        event = [Event eventForCode:INSOEventCodeGroundball inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsBoysEventSet addObject:event];

        // interceptions
        event = [Event eventForCode:INSOEventCodeInterception inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsBoysEventSet addObject:event];
        
        // faceoffs won
        event = [Event eventForCode:INSOEventCodeFaceoffWon inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsBoysEventSet addObject:event];
        
        // goals against
        event = [Event eventForCode:INSOEventCodeGoalAllowed inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsBoysEventSet addObject:event];
        
        // saves
        event = [Event eventForCode:INSOEventCodeSave inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsBoysEventSet addObject:event];
        
        // Now get the intersection
        [maxPrepsBoysEventSet intersectSet:self.game.eventsToRecord];
        
        _maxPrepsBoysEvents = [maxPrepsBoysEventSet allObjects];
    }
    
    return _maxPrepsBoysEvents;
}

- (NSArray *)maxPrepsGirlsEvents
{
    if (!_maxPrepsGirlsEvents) {
        NSMutableSet* maxPrepsGirlsEventSet = [NSMutableSet new];
        
        Event* event;
        
        // goals
        event = [Event eventForCode:INSOEventCodeGoal inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsGirlsEventSet addObject:event];
        
        // assists
        event = [Event eventForCode:INSOEventCodeAssist inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsGirlsEventSet addObject:event];
        
        // shots on goal
        event = [Event eventForCode:INSOEventCodeShotOnGoal inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsGirlsEventSet addObject:event];
        
        // groundballs
        event = [Event eventForCode:INSOEventCodeGroundball inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsGirlsEventSet addObject:event];
        
        // Interceptions
        event = [Event eventForCode:INSOEventCodeInterception inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsGirlsEventSet addObject:event];
        
        // faceoffs won
        event = [Event eventForCode:INSOEventCodeDrawPossession inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsGirlsEventSet addObject:event];
        
        // Faceoff attempts
        event = [Event eventForCode:INSOEventCodeDrawTaken inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsGirlsEventSet addObject:event];
        
        // goals against
        event = [Event eventForCode:INSOEventCodeGoalAllowed inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsGirlsEventSet addObject:event];
        
        // saves
        event = [Event eventForCode:INSOEventCodeSave inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsGirlsEventSet addObject:event];
        
        // Now get the intersection
        [maxPrepsGirlsEventSet intersectSet:self.game.eventsToRecord];
        
        _maxPrepsGirlsEvents = [maxPrepsGirlsEventSet allObjects];
    }
    
    return _maxPrepsGirlsEvents;
}

#pragma mark - Private methods
- (NSString *)gameStatsFileHeader {
    NSError *error = nil;
    NSString *fileHeader = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GameSummaryHeaderFile" ofType:@"html"] encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error reading game stats file header: %@", error.localizedDescription);
        return nil;
    }
    fileHeader = [fileHeader stringByReplacingOccurrencesOfString:@"#HomeTeam#" withString:self.game.homeTeam];
    fileHeader = [fileHeader stringByReplacingOccurrencesOfString:@"#VisitingTeam#" withString:self.game.visitingTeam];
    fileHeader = [fileHeader stringByReplacingOccurrencesOfString:@"#HomeScore#" withString:[self.game.homeScore stringValue]];
    fileHeader = [fileHeader stringByReplacingOccurrencesOfString:@"#VisitingScore#" withString:[self.game.visitorScore stringValue]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    fileHeader = [fileHeader stringByReplacingOccurrencesOfString:@"#GameDate#" withString:[dateFormatter stringFromDate:self.game.gameDateTime]];
    return fileHeader;
}

- (NSString *)gameStatsFieldingSection {
    NSMutableString *fieldingSection = [[NSMutableString alloc] init];
    
    // Section header
    [fieldingSection appendString:@"<tr>\n"];
    [fieldingSection appendString:@"<th colspan=\"3\">Fielding</th>\n"];
    [fieldingSection appendString:@"</tr>\n"];
    
    // And now the stats
    INSOGameEventCounter *eventCounter = [[INSOGameEventCounter alloc] initWithGame:self.game];
    
    // Groundballs
    if ([self.game didRecordEvent:INSOEventCodeGroundball]) {
        NSNumber *homeGroundBalls = [eventCounter eventCountForHomeTeam:INSOEventCodeGroundball];
        NSNumber *visitorGroundBalls = [eventCounter eventCountForVisitingTeam:INSOEventCodeGroundball];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Groundballs</td><td>%@</td>\n", homeGroundBalls, visitorGroundBalls];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Faceoffs
    if ([self.game didRecordEvent:INSOEventCodeFaceoffWon] && [self.game didRecordEvent:INSOEventCodeFaceoffLost]) {
        NSInteger homeFaceoffsWon = [[eventCounter eventCountForHomeTeam:INSOEventCodeFaceoffWon] integerValue];
        NSInteger homeFaceoffsLost = [[eventCounter eventCountForHomeTeam:INSOEventCodeFaceoffLost] integerValue];
        NSInteger homeFaceoffs = homeFaceoffsWon + homeFaceoffsLost;
        CGFloat   homeFaceoffPct = (homeFaceoffs > 0) ? (CGFloat)homeFaceoffsWon / homeFaceoffs : 0.0;
        NSString *homeFaceoffPctString = [self.percentFormatter stringFromNumber:@(homeFaceoffPct)];
        
        NSInteger visitorFaceoffsWon = [[eventCounter eventCountForVisitingTeam:INSOEventCodeFaceoffWon] integerValue];
        NSInteger visitorFaceoffsLost = [[eventCounter eventCountForVisitingTeam:INSOEventCodeFaceoffLost] integerValue];
        NSInteger visitorFaceoffs = visitorFaceoffsWon + visitorFaceoffsLost;
        CGFloat   visitorFaceoffPct = (visitorFaceoffs > 0) ? (CGFloat)visitorFaceoffsWon / visitorFaceoffs : 0.0;
        NSString *visitorFaceoffPctString = [self.percentFormatter stringFromNumber:@(visitorFaceoffPct)];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@/%@ %@</td><td>Faceoffs</td><td>%@/%@ %@</td>\n", @(homeFaceoffsWon), @(homeFaceoffs), homeFaceoffPctString, @(visitorFaceoffsWon), @(visitorFaceoffs), visitorFaceoffPctString];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Draws (instead of faceoffs)
    if ([self.game didRecordEvent:INSOEventCodeDrawTaken] && [self.game didRecordEvent:INSOEventCodeDrawControl]) {
        NSInteger homeDrawsTaken = [[eventCounter eventCountForHomeTeam:INSOEventCodeDrawTaken] integerValue];
        NSInteger homeDrawControl = [[eventCounter eventCountForHomeTeam:INSOEventCodeDrawControl] integerValue];
        CGFloat   homeDrawControlPct = (homeDrawsTaken > 0) ? (CGFloat)homeDrawControl / homeDrawsTaken : 0.0;
        NSString *homeDrawControlPctString = [self.percentFormatter stringFromNumber:@(homeDrawControlPct)];
        
        NSInteger visitorDrawsTaken = [[eventCounter eventCountForVisitingTeam:INSOEventCodeDrawTaken] integerValue];
        NSInteger visitorDrawControl = [[eventCounter eventCountForVisitingTeam:INSOEventCodeDrawControl] integerValue];
        CGFloat   visitorDrawControlPct = (visitorDrawsTaken > 0) ? (CGFloat)visitorDrawControl / visitorDrawsTaken : 0.0;
        NSString *visitorDrawControlPctString = [self.percentFormatter stringFromNumber:@(visitorDrawControlPct)];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@/%@ %@</td><td>Draw Control</td><td>%@/%@ %@</td>\n", @(homeDrawControl), @(homeDrawsTaken), homeDrawControlPctString, @(visitorDrawControl), @(visitorDrawsTaken), visitorDrawControlPctString];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Clears
    if ([self.game didRecordEvent:INSOEventCodeClearSuccessful] && [self.game didRecordEvent:INSOEventCodeClearFailed]) {
        NSInteger homeClearSuccessful = [[eventCounter eventCountForHomeTeam:INSOEventCodeClearSuccessful] integerValue];
        NSInteger homeClearFailed = [[eventCounter eventCountForHomeTeam:INSOEventCodeClearFailed] integerValue];
        NSInteger homeClears = homeClearSuccessful + homeClearFailed;
        CGFloat   homeClearPct = (homeClears > 0) ? (CGFloat)homeClearSuccessful / homeClears : 0.0;
        NSString *homeClearPctString = [self.percentFormatter stringFromNumber:@(homeClearPct)];
        
        NSInteger visitorClearSuccessful = [[eventCounter eventCountForVisitingTeam:INSOEventCodeClearSuccessful] integerValue];
        NSInteger visitorClearFailed = [[eventCounter eventCountForVisitingTeam:INSOEventCodeClearFailed] integerValue];
        NSInteger visitorClears = visitorClearSuccessful + visitorClearFailed;
        CGFloat   visitorClearPct = (visitorClears > 0) ? (CGFloat)visitorClearSuccessful / visitorClears : 0.0;
        NSString *visitorClearPctString = [self.percentFormatter stringFromNumber:@(visitorClearPct)];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@/%@ %@</td><td>Clears</td><td>%@/%@ %@</td>\n", @(homeClearSuccessful), @(homeClears), homeClearPctString, @(visitorClearSuccessful), @(visitorClears), visitorClearPctString];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Interceptions
    if ([self.game didRecordEvent:INSOEventCodeInterception]) {
        NSNumber *homeInterceptions = [eventCounter eventCountForHomeTeam:INSOEventCodeInterception];
        NSNumber *visitorInterceptions = [eventCounter eventCountForVisitingTeam:INSOEventCodeTurnover];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Interceptions</td><td>%@</td>\n", homeInterceptions, visitorInterceptions];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Turnovers
    if ([self.game didRecordEvent:INSOEventCodeTurnover]) {
        NSNumber *homeTurnovers = [eventCounter eventCountForHomeTeam:INSOEventCodeTurnover];
        NSNumber *visitorTurnovers = [eventCounter eventCountForVisitingTeam:INSOEventCodeTurnover];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Turnovers</td><td>%@</td>\n", homeTurnovers, visitorTurnovers];
        [fieldingSection appendString:@"</tr>\n"];
    }

    // Caused Turnovers
    if ([self.game didRecordEvent:INSOEventCodeCausedTurnover]) {
        NSNumber *homeCausedTurnovers = [eventCounter eventCountForHomeTeam:INSOEventCodeCausedTurnover];
        NSNumber *visitorCausedTurnovers = [eventCounter eventCountForVisitingTeam:INSOEventCodeCausedTurnover];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Caused Turnovers</td><td>%@</td>\n", homeCausedTurnovers, visitorCausedTurnovers];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    return fieldingSection;
}

- (NSString *)gameStatsScoringSection {
    NSMutableString *scoringSection = [[NSMutableString alloc] init];
    
    // Section header
    [scoringSection appendString:@"<tr>\n"];
    [scoringSection appendString:@"<th colspan=\"3\">Scoring</th>\n"];
    [scoringSection appendString:@"</tr>\n"];
    
    // And now the stats
    INSOGameEventCounter *eventCounter = [[INSOGameEventCounter alloc] initWithGame:self.game];
    
    // Shots
    if ([self.game didRecordEvent:INSOEventCodeShot]) {
        NSNumber *homeShots = [eventCounter eventCountForHomeTeam:INSOEventCodeShot];
        NSNumber *visitorShots = [eventCounter eventCountForVisitingTeam:INSOEventCodeShot];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Shots</td><td>%@</td>\n", homeShots, visitorShots];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Goals
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        NSNumber *homeGoals = [eventCounter eventCountForHomeTeam:INSOEventCodeGoal];
        NSNumber *visitorGoals = [eventCounter eventCountForVisitingTeam:INSOEventCodeGoal];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Goals</td><td>%@</td>\n", homeGoals, visitorGoals];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Shooting pct. (Percent of shots that result in a goal)
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger homeShots = [[eventCounter eventCountForHomeTeam:INSOEventCodeShot] integerValue];
        NSInteger homeGoals = [[eventCounter eventCountForHomeTeam:INSOEventCodeGoal] integerValue];
        CGFloat   homeShootingPct = (homeShots > 0) ? (CGFloat)homeGoals / homeShots : 0.0;
        NSString *homeShootingPctString = [self.percentFormatter stringFromNumber:@(homeShootingPct)];
        
        NSInteger visitorShots = [[eventCounter eventCountForVisitingTeam:INSOEventCodeShot] integerValue];
        NSInteger visitorGoals = [[eventCounter eventCountForVisitingTeam:INSOEventCodeGoal] integerValue];
        CGFloat   visitorShootingPct = (visitorShots > 0) ? (CGFloat)visitorGoals / visitorShots : 0.0;
        NSString *visitorShootingPctString = [self.percentFormatter stringFromNumber:@(visitorShootingPct)];

        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Shooting Percent<br/>(Goals / Shots)</td><td>%@</td>\n", homeShootingPctString, visitorShootingPctString];
        [scoringSection appendString:@"</tr>\n"];
    }

    
    // Shots on goal
    if ([self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        NSNumber *homeSOG = [eventCounter eventCountForHomeTeam:INSOEventCodeShotOnGoal];
        NSNumber *visitorSOG = [eventCounter eventCountForVisitingTeam:INSOEventCodeShotOnGoal];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Shots on Goal</td><td>%@</td>\n", homeSOG, visitorSOG];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Misses = shots - shots on goal;
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        NSInteger homeShots = [[eventCounter eventCountForHomeTeam:INSOEventCodeShot] integerValue];
        NSInteger homeSOG = [[eventCounter eventCountForHomeTeam:INSOEventCodeShotOnGoal] integerValue];
        NSInteger homeMisses = homeShots - homeSOG;
        homeMisses = homeMisses < 0 ? 0 : homeMisses;
        
        NSInteger visitorShots = [[eventCounter eventCountForVisitingTeam:INSOEventCodeShot] integerValue];
        NSInteger visitorSOG = [[eventCounter eventCountForVisitingTeam:INSOEventCodeShotOnGoal] integerValue];
        NSInteger visitorMisses = visitorShots - visitorSOG;
        visitorMisses = visitorMisses < 0 ? 0 : visitorMisses;

        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Misses</td><td>%@</td>\n", @(homeMisses), @(visitorMisses)];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Shooting accuracy = shots on goal / shots (what percent of your shots were on goal)
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        NSInteger homeShots = [[eventCounter eventCountForHomeTeam:INSOEventCodeShot] integerValue];
        NSInteger homeSOG = [[eventCounter eventCountForHomeTeam:INSOEventCodeShotOnGoal] integerValue];
        CGFloat   homeAccuracy = (homeShots > 0) ? (CGFloat)homeSOG / homeShots : 0.0;
        NSString *homeAccuracyString = [self.percentFormatter stringFromNumber:@(homeAccuracy)];
        
        NSInteger visitorShots = [[eventCounter eventCountForVisitingTeam:INSOEventCodeShot] integerValue];
        NSInteger visitorSOG = [[eventCounter eventCountForVisitingTeam:INSOEventCodeShotOnGoal] integerValue];
        CGFloat   visitorAccuracy = (visitorShots > 0) ? (CGFloat)visitorSOG / visitorShots : 0.0;
        NSString *visitorAccuracyString = [self.percentFormatter stringFromNumber:@(visitorAccuracy)];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Shooting Accuracy<br/>(Shots on Goal / Shots)</td><td>%@</td>\n", homeAccuracyString, visitorAccuracyString];
        [scoringSection appendString:@"</tr>\n"];
    }

    // Assists
    if ([self.game didRecordEvent:INSOEventCodeAssist]) {
        NSNumber *homeAssists = [eventCounter eventCountForHomeTeam:INSOEventCodeAssist];
        NSNumber *visitorAssists = [eventCounter eventCountForVisitingTeam:INSOEventCodeAssist];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Assists</td><td>%@</td>\n", homeAssists, visitorAssists];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Saves
    if ([self.game didRecordEvent:INSOEventCodeSave]) {
        NSNumber *homeSaves = [eventCounter eventCountForHomeTeam:INSOEventCodeSave];
        NSNumber *visitorSaves = [eventCounter eventCountForVisitingTeam:INSOEventCodeSave];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Saves</td><td>%@</td>\n", homeSaves, visitorSaves];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Goals allowed
    if ([self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        NSNumber *homeGoalsAllowed = [eventCounter eventCountForHomeTeam:INSOEventCodeGoalAllowed];
        NSNumber *visitorGoalsAllowed = [eventCounter eventCountForVisitingTeam:INSOEventCodeGoalAllowed];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Goals Allowed</td><td>%@</td>\n", homeGoalsAllowed, visitorGoalsAllowed];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Save pct. = saves / (saves + goals allowed)
    if ([self.game didRecordEvent:INSOEventCodeSave] && [self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        NSInteger homeSaves = [[eventCounter eventCountForHomeTeam:INSOEventCodeSave] integerValue];
        NSInteger homeGoalsAllowed = [[eventCounter eventCountForHomeTeam:INSOEventCodeGoalAllowed] integerValue];
        CGFloat   homeSavePct = (homeSaves + homeGoalsAllowed) > 0 ? (CGFloat)homeSaves / (homeSaves + homeGoalsAllowed) : 0.0;
        NSString *homeSavePctString = [self.percentFormatter stringFromNumber:@(homeSavePct)];
        
        NSInteger visitorSaves = [[eventCounter eventCountForVisitingTeam:INSOEventCodeSave] integerValue];
        NSInteger visitorGoalsAllowed = [[eventCounter eventCountForVisitingTeam:INSOEventCodeGoalAllowed] integerValue];
        CGFloat   visitorSavePct = (visitorSaves + visitorGoalsAllowed) > 0 ? (CGFloat)visitorSaves / (visitorSaves + visitorGoalsAllowed) : 0.0;
        NSString *visitorSavePctString = [self.percentFormatter stringFromNumber:@(visitorSavePct)];

        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Save Percent</td><td>%@</td>\n", homeSavePctString, visitorSavePctString];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    return scoringSection;
}

- (NSString *)gameStatsExtraManSection {
    NSMutableString *emoSection = [[NSMutableString alloc] init];
    
    // Section header
    [emoSection appendString:@"<tr>\n"];
    [emoSection appendString:@"<th colspan=\"3\">Extra-Man</th>\n"];
    [emoSection appendString:@"</tr>\n"];
    
    // And now the stats
    INSOGameEventCounter *eventCounter = [[INSOGameEventCounter alloc] initWithGame:self.game];
    
    // EMO
    if ([self.game didRecordEvent:INSOEventCodeEMO]) {
        NSNumber *homeEMO = [eventCounter eventCountForHomeTeam:INSOEventCodeEMO];
        NSNumber *visitorEMO = [eventCounter eventCountForVisitingTeam:INSOEventCodeEMO];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>EMO</td><td>%@</td>\n", homeEMO, visitorEMO];
        [emoSection appendString:@"</tr>\n"];
    }
    
    // EMO goals
    if ([self.game didRecordEvent:INSOEventCodeEMO] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger homeEMOGoals = [[eventCounter extraManGoalsForHomeTeam] integerValue];
        NSInteger visitorEMOGoals = [[eventCounter extraManGoalsForVisitingTeam] integerValue];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>EMO Goals</td><td>%@</td>\n", @(homeEMOGoals), @(visitorEMOGoals)];
        [emoSection appendString:@"</tr>\n"];
        
        // Just do the emo scoring here while we're at it.
        // EMO scoring = emo goals / emo
        NSInteger homeEMO = [[eventCounter eventCountForHomeTeam:INSOEventCodeEMO] integerValue];
        NSInteger visitorEMO = [[eventCounter eventCountForVisitingTeam:INSOEventCodeEMO] integerValue];
        
        CGFloat homeEMOScoring = (homeEMO > 0) ? (CGFloat)homeEMOGoals / homeEMO : 0.0;
        NSString *homeEMOScoringString = [self.percentFormatter stringFromNumber:@(homeEMOScoring)];
        CGFloat visitorEMOScoring = (visitorEMO > 0) ? (CGFloat)visitorEMOGoals / visitorEMO : 0.0;
        NSString *visitorEMOScoringString = [self.percentFormatter stringFromNumber:@(visitorEMOScoring)];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>EMO Scoring</td><td>%@</td>\n", homeEMOScoringString, visitorEMOScoringString];
        [emoSection appendString:@"</tr>\n"];
    }

    
    // Man-down
    if ([self.game didRecordEvent:INSOEventCodeManDown]) {
        NSNumber *homeManDown = [eventCounter eventCountForHomeTeam:INSOEventCodeManDown];
        NSNumber *visitorManDown = [eventCounter eventCountForVisitingTeam:INSOEventCodeManDown];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>Man-down</td><td>%@</td>\n", homeManDown, visitorManDown];
        [emoSection appendString:@"</tr>\n"];
    }
    
    // Man-down goals allowed
    // A man-down goal allowed is an extra-man goal scored by the other team.
    // Proceed accordingly.
    if ([self.game didRecordEvent:INSOEventCodeManDown] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger homeManDown = [[eventCounter eventCountForHomeTeam:INSOEventCodeManDown] integerValue];
        NSInteger visitorManDown = [[eventCounter eventCountForVisitingTeam:INSOEventCodeManDown] integerValue];
        
        NSInteger homeMDGoalsAllowed = [[eventCounter extraManGoalsForVisitingTeam] integerValue];
        NSInteger visitorMDGoalsAllowed = [[eventCounter extraManGoalsForHomeTeam] integerValue];
        
        
        CGFloat homeManDownScoring = (homeManDown > 0) ? (CGFloat)homeMDGoalsAllowed / homeManDown : 0.0;
        CGFloat visitorManDownScoring = (visitorManDown > 0) ? (CGFloat)visitorMDGoalsAllowed / visitorManDown : 0.0;

        // Man-down scoring = man-down goals allowed / man-down
        NSString *homeManDownScoringString = [self.percentFormatter stringFromNumber:@(homeManDownScoring)];
        NSString *visitorManDownScoringString = [self.percentFormatter stringFromNumber:@(visitorManDownScoring)];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>Man-down Goals Allowed</td><td>%@</td>\n", @(homeMDGoalsAllowed), @(visitorMDGoalsAllowed)];
        [emoSection appendString:@"</tr>\n"];

        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>Man-down Scoring<br />(Man-down goals allowed / Man-down)</td><td>%@</td>\n", homeManDownScoringString, visitorManDownScoringString];
        [emoSection appendString:@"</tr>\n"];
    }
    
    return emoSection;
}

- (NSString *)gameStatsPenaltySection {
    NSMutableString *penaltySection = [[NSMutableString alloc] init];
    
    // Section title depends on boys or girls
    NSString *sectionTitle;
    self.isExportingForBoys ? (sectionTitle = @"Penalties") : (sectionTitle = @"Fouls");
    
    // Section header
    [penaltySection appendString:@"<tr>\n"];
    [penaltySection appendFormat:@"<th colspan=\"3\">%@</th>\n", sectionTitle];
    [penaltySection appendString:@"</tr>\n"];
    
    // And now the stats
    INSOGameEventCounter *eventCounter = [[INSOGameEventCounter alloc] initWithGame:self.game];
    
    if (self.isExportingForBoys) {
        // Penalties
        NSNumber *homePenalties = [eventCounter totalPenaltiesForHomeTeam];
        NSNumber *visitorPenalties = [eventCounter totalPenaltiesForVisitingTeam];
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Penalties</td><td>%@</td>\n", homePenalties, visitorPenalties];
        [penaltySection appendString:@"</tr>\n"];
        
        // Penalty Time
        NSInteger homePenaltySeconds = [[eventCounter totalPenaltyTimeForHomeTeam] integerValue];
        NSInteger visitorPenaltySeconds = [[eventCounter totalPenaltyTimeForVisitingTeam] integerValue];
        
        NSDateComponentsFormatter* penaltyTimeFormatter = [[NSDateComponentsFormatter alloc] init];
        penaltyTimeFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropLeading;
        penaltyTimeFormatter.allowedUnits = (NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
        NSString *homePenaltyTimeString = [penaltyTimeFormatter stringFromTimeInterval:homePenaltySeconds];
        NSString *visitorPentaltyTimeString = [penaltyTimeFormatter stringFromTimeInterval:visitorPenaltySeconds];
        
        // Penalty Section
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Penalty Time</td><td>%@</td>\n", homePenaltyTimeString, visitorPentaltyTimeString];
        [penaltySection appendString:@"</tr>\n"];
    } else {
        // Fouls
        NSInteger homeFouls = 0;
        NSInteger visitorFouls = 0;
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Fouls</td><td>%@</td>\n", @(homeFouls), @(visitorFouls)];
        [penaltySection appendString:@"</tr>\n"];

        // Green cards
        NSInteger homeGreenCards = 0;
        NSInteger visitorGreenCards = 0;

        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Green Cards</td><td>%@</td>\n", @(homeGreenCards), @(visitorGreenCards)];
        [penaltySection appendString:@"</tr>\n"];

        // Yellow cards
        NSInteger homeYellowCards = 0;
        NSInteger visitorYellowCards = 0;

        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Yellow Cards</td><td>%@</td>\n", @(homeYellowCards), @(visitorYellowCards)];
        [penaltySection appendString:@"</tr>\n"];

        // Red cards
        NSInteger homeRedCards = 0;
        NSInteger visitorRedCards = 0;

        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Red Cards</td><td>%@</td>\n", @(homeRedCards), @(visitorRedCards)];
        [penaltySection appendString:@"</tr>\n"];

    }


    return penaltySection;
}

- (NSString *)gameStatsFileFooter {
    NSError *error = nil;
    NSString *fileFooter = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GameSummaryFooterFile" ofType:@"html"] encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error reading game stats file header: %@", error.localizedDescription);
        return nil;
    }
    return fileFooter;
}

- (NSArray *)headerRowForPlayerStats
{
    NSMutableArray* header = [NSMutableArray new];
    
    // First the player number
    [header addObject:@"Player"];
    
    // Now the event titles
    // Really should localize this...sigh
    Event *event;
    
    // Groundballs
    event = [Event eventForCode:INSOEventCodeGroundball inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    
    // Faceoff attempts
    [header addObject:@"Faceoffs"];
    
    // Faceoffs won
    event = [Event eventForCode:INSOEventCodeFaceoffWon inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    
    // Faceoff %
    [header addObject:@"Faceoff Pct."];
    
    // Turnovers
    event = [Event eventForCode:INSOEventCodeTurnover inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    
    // Caused turnover
    event = [Event eventForCode:INSOEventCodeCausedTurnover inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    
    // Interceptions
    event = [Event eventForCode:INSOEventCodeInterception inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    
    // Shots
    event = [Event eventForCode:INSOEventCodeShot inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    
    // Goals
    event = [Event eventForCode:INSOEventCodeGoal inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    
    // Assists
    event = [Event eventForCode:INSOEventCodeAssist inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    
    // Points
    [header addObject:@"Points"];
    
    // Shooting %
    [header addObject:@"Shooting Pct."];
    
    // SOG
    event = [Event eventForCode:INSOEventCodeShotOnGoal inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    
    // Misses
    [header addObject:@"Misses"];
    
    // Shooting accuracy
    [header addObject:@"Shooting Accuracy"];
    
    // Saves
    event = [Event eventForCode:INSOEventCodeSave inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    
    // Goals allowed
    event = [Event eventForCode:INSOEventCodeGoalAllowed inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    
    // Save %
    [header addObject:@"Save Pct."];
    
    if (self.isExportingForBoys) {
        // Boys penalties are different
            [header addObject:@"Penalties"];
            [header addObject:@"Penalty time"];
    } else {
        [header addObject:@"Penalties"]; 
    }
    
    return header;
}

- (NSArray*)dataRowForPlayer:(RosterPlayer*)rosterPlayer
{
    NSMutableArray* dataRow = [NSMutableArray new];
    
    // First goes the player
    [dataRow addObject:rosterPlayer.number];
    
    // Now we need an event counter
    INSOGameEventCounter* eventCounter = [[INSOGameEventCounter alloc] initWithGame:self.game];
    
    // Groundballs
    if ([self.game didRecordEvent:INSOEventCodeGroundball]) {
        [dataRow addObject:[eventCounter eventCount:INSOEventCodeGroundball forRosterPlayer:rosterPlayer]];
    }
    
    // Faceoff attempts
    NSNumber *faceoffsWon;
    NSNumber *faceoffsLost;
    NSNumber *faceoffAttempts;
    
    if ([self.game didRecordEvent:INSOEventCodeFaceoffWon] && [self.game didRecordEvent:INSOEventCodeFaceoffLost]) {
        faceoffsWon = [eventCounter eventCount:INSOEventCodeFaceoffWon forRosterPlayer:rosterPlayer];
        faceoffsLost = [eventCounter eventCount:INSOEventCodeFaceoffLost forRosterPlayer:rosterPlayer];
        NSInteger attempts = [faceoffsWon integerValue] + [faceoffsLost integerValue];
        faceoffAttempts = [NSNumber numberWithInteger:attempts];
        [dataRow addObject:faceoffAttempts];
    }
    
    // Faceoffs won
    if ([self.game didRecordEvent:INSOEventCodeFaceoffWon] && [self.game didRecordEvent:INSOEventCodeFaceoffLost]) {
        [dataRow addObject:faceoffsWon];
    }
    
    // Faceoff %
    if ([self.game didRecordEvent:INSOEventCodeFaceoffWon] && [self.game didRecordEvent:INSOEventCodeFaceoffLost]) {
        CGFloat faceoffPercent = 0.0;
        if ([faceoffAttempts integerValue] > 0) {
            faceoffPercent = [faceoffsWon floatValue] / [faceoffAttempts floatValue];
            [dataRow addObject:[self.percentFormatter stringFromNumber:@(faceoffPercent)]];
        } else {
            [dataRow addObject:@""];
        }
    }
    
    // Turnovers
    if ([self.game didRecordEvent:INSOEventCodeTurnover]) {
        [dataRow addObject:[eventCounter eventCount:INSOEventCodeTurnover forRosterPlayer:rosterPlayer]];
    }
    
    // Caused turnover
    if ([self.game didRecordEvent:INSOEventCodeCausedTurnover]) {
        [dataRow addObject:[eventCounter eventCount:INSOEventCodeCausedTurnover forRosterPlayer:rosterPlayer]];
    }
    
    // Interceptions
    if ([self.game didRecordEvent:INSOEventCodeInterception]) {
        [dataRow addObject:[eventCounter eventCount:INSOEventCodeInterception forRosterPlayer:rosterPlayer]];
    }
    
    // Shots
    NSNumber *shots;
    if ([self.game didRecordEvent:INSOEventCodeShot]) {
        shots = [eventCounter eventCount:INSOEventCodeShot forRosterPlayer:rosterPlayer];
        [dataRow addObject:shots];
    }
    
    // Goals
    NSNumber *goals;
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        goals = [eventCounter eventCount:INSOEventCodeGoal forRosterPlayer:rosterPlayer];
        [dataRow addObject:goals];
    }
    
    // Assists
    NSNumber *assists;
    if ([self.game didRecordEvent:INSOEventCodeAssist]) {
        assists = [eventCounter eventCount:INSOEventCodeAssist forRosterPlayer:rosterPlayer];
        [dataRow addObject:assists];
    }
    
    // Points
    if ([self.game didRecordEvent:INSOEventCodeAssist] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger points = [assists integerValue] + [goals integerValue];
        [dataRow addObject:@(points)];
    }
    
    // Shooting % (goals / shots);
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        CGFloat shootingPercent = 0.0;
        if ([shots integerValue] > 0) {
            shootingPercent = [goals floatValue] / [shots floatValue];
            [dataRow addObject:[self.percentFormatter stringFromNumber:@(shootingPercent)]];
        } else {
            [dataRow addObject:@""];
        }
    }
    
    // SOG
    NSNumber *sog;
    if ([self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        sog = [eventCounter eventCount:INSOEventCodeShotOnGoal forRosterPlayer:rosterPlayer];
        [dataRow addObject:sog];
    }
    
    // Misses (shots - shots on goal);
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        NSInteger misses = [shots integerValue] - [sog integerValue];
        if (misses < 0) {
            misses = 0;
        }
        [dataRow addObject:@(misses)];
    }
    
    // Shooting accuracy (SOG / Shots)
    if ([self.game didRecordEvent:INSOEventCodeShotOnGoal] && [self.game didRecordEvent:INSOEventCodeShot]) {
        CGFloat shootingAccuracy = 0.0;
        if ([shots integerValue] > 0) {
            shootingAccuracy = [sog floatValue] / [shots floatValue];
            [dataRow addObject:[self.percentFormatter stringFromNumber:@(shootingAccuracy)]];
        } else {
            [dataRow addObject:@""];
        }
    }
    
    // Saves
    NSNumber *saves;
    if ([self.game didRecordEvent:INSOEventCodeSave]) {
        saves = [eventCounter eventCount:INSOEventCodeSave forRosterPlayer:rosterPlayer];
        [dataRow addObject:saves];
    }
    
    // Goals allowed
    NSNumber *goalsAllowed;
    if ([self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        goalsAllowed = [eventCounter eventCount:INSOEventCodeGoalAllowed forRosterPlayer:rosterPlayer];
        [dataRow addObject:goalsAllowed];
    }
    
    // Save %
    if ([self.game didRecordEvent:INSOEventCodeSave] && [self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        CGFloat savePercent = 0.0;
        if (([goalsAllowed integerValue] + [saves integerValue]) > 0) {
            savePercent = [saves floatValue] / ([saves floatValue] + [goalsAllowed floatValue]);
            [dataRow addObject:[self.percentFormatter stringFromNumber:@(savePercent)]];
        } else {
            [dataRow addObject:@""];
        }
    }
    
    // And now the penalties
    if (self.shouldExportPenalties && self.isExportingForBoys) {
        [dataRow addObject:[eventCounter totalPenaltiesForBoysRosterPlayer:rosterPlayer]];
        
        double totalPenaltyTime = [[eventCounter totalPenaltyTimeforRosterPlayer:rosterPlayer] doubleValue];
        
        NSDateComponentsFormatter* penaltyTimeFormatter = [[NSDateComponentsFormatter alloc] init];
        penaltyTimeFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropLeading;
        penaltyTimeFormatter.allowedUnits = (NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
        
        [dataRow addObject:[penaltyTimeFormatter stringFromTimeInterval:totalPenaltyTime]];
    }
    
    return dataRow;
}

- (NSArray* )maxPrepsBoysHeaderRow
{
    NSMutableArray* header = [NSMutableArray new];
    
    // First the player number
    [header addObject:@"Jersey"];
    
    // Now the event titles for the events we've collected
    for (Event* event in self.maxPrepsBoysEvents) {
        [header addObject:event.maxPrepsTitle];
    }
    
    // Now faceoffs.
    if ([self.maxPrepsBoysEvents containsObject:[Event eventForCode:INSOEventCodeFaceoffWon inManagedObjectContext:self.game.managedObjectContext]]) {
        // Only report faceoff attempts if we've actually collected faceoffs.
        [header addObject:@"FaceoffAttempts"];
    }
    
    // Now the penalty titles
    if (self.shouldExportPenalties) {
        [header addObject:@"Penalties"];
        [header addObject:@"PenaltyMinutes"];
        [header addObject:@"PenaltySeconds"];
    }
    
    return header;
}

- (NSArray* )maxPrepsGirlsHeaderRow
{
    NSMutableArray* header = [NSMutableArray new];
    
    // First the player number
    [header addObject:@"Jersey"];
    
    // Now the event titles for the events we've collected
    for (Event* event in self.maxPrepsGirlsEvents) {
        [header addObject:event.maxPrepsTitle];
    }
    
    // Now the penalty titles
    if (self.shouldExportPenalties) {
        [header addObject:@"Penalties"];
    }
    
    return header;
}

- (NSArray*)maxPrepsBoysDataRowForPlayer:(RosterPlayer*)rosterPlayer
{
    NSMutableArray* dataRow = [NSMutableArray new];
    
    // First goes the player
    [dataRow addObject:rosterPlayer.number];
    
    // Now we need an event counter
    INSOGameEventCounter* eventCounter = [[INSOGameEventCounter alloc] initWithGame:self.game];
    
    // Now a count of every event for that number
    for (Event* event in self.maxPrepsBoysEvents) {
        NSNumber* eventCount = [eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        [dataRow addObject:eventCount];
    }
    
    // now add faceoff attempts if we recorded faceoffs won.
    if ([self.maxPrepsBoysEvents containsObject:[Event eventForCode:INSOEventCodeFaceoffWon inManagedObjectContext:self.game.managedObjectContext]]) {
        // Only report faceoff attempts if we've actually collected faceoffs.
        NSInteger faceoffsWon = [[eventCounter eventCount:INSOEventCodeFaceoffWon forRosterPlayer:rosterPlayer] integerValue];
        NSInteger faceoffsLost = [[eventCounter eventCount:INSOEventCodeFaceoffLost forRosterPlayer:rosterPlayer] integerValue];
        NSNumber* faceoffAttempts = [NSNumber numberWithInteger:(faceoffsWon + faceoffsLost)];
        [dataRow addObject:faceoffAttempts];
    }
    
    // And now the penalties
    if (self.shouldExportPenalties) {
        [dataRow addObject:[eventCounter totalPenaltiesForBoysRosterPlayer:rosterPlayer]];
        
        NSInteger totalPenaltyTime = [[eventCounter totalPenaltyTimeforRosterPlayer:rosterPlayer] integerValue];
        NSInteger penaltyMinutes = totalPenaltyTime / 60;
        NSInteger penaltySeconds = totalPenaltyTime % 60;
        
        [dataRow addObject:[NSNumber numberWithInteger:penaltyMinutes]];
        [dataRow addObject:[NSNumber numberWithInteger:penaltySeconds]];
    }
    
    return dataRow;
}

- (NSArray*)maxPrepsGirlsDataRowForPlayer:(RosterPlayer*)rosterPlayer
{
    NSMutableArray* dataRow = [NSMutableArray new];
    
    // First goes the player
    [dataRow addObject:rosterPlayer.number];
    
    // Now we need an event counter
    INSOGameEventCounter* eventCounter = [[INSOGameEventCounter alloc] initWithGame:self.game];
    
    // Now a count of every event for that number
    for (Event* event in self.maxPrepsGirlsEvents) {
        NSNumber* eventCount = [eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        [dataRow addObject:eventCount];
    }
    
    // And now the penalties
    if (self.shouldExportPenalties) {
        [dataRow addObject:[eventCounter totalPenaltiesForGirlsRosterPlayer:rosterPlayer]];
    }
    
    return dataRow;
}

@end
