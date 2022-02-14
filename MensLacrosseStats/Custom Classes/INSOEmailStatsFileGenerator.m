//
//  INSOEmailStatsFileGenerator.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 11/27/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//
#import <UIKit/UIKit.h>

#import "INSOEmailStatsFileGenerator.h"
#import "INSOMensLacrosseStatsConstants.h"
#import "INSOMensLacrosseStatsEnum.h"

#import "LacrosseStats-Swift.h"

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

@property (nonatomic) GameEventCounter *eventCounter;

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

        if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:INSOMensIdentifier]) {
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
        
        // We need an event counter
        _eventCounter = [[GameEventCounter alloc] initWith:_game];
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
    NSArray *header = (self.isExportingForBoys ? [self boysHeaderRowForPlayerStats] : [self girlsHeaderRowForPlayerStats]);
    
    [gameStatsArray addObject:[header componentsJoinedByString:@","]];
    
    // Create player stats rows
    for (RosterPlayer* rosterPlayer in self.playersArray) {
        if (!rosterPlayer.isTeamValue) {
            NSArray* dataRow = (self.isExportingForBoys ? [self boysDataRowForPlayer:rosterPlayer] : [self girlsDataRowForPlayer:rosterPlayer]);
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
    
    // Groundballs
    if ([self.game didRecordEvent:INSOEventCodeGroundball]) {
        NSNumber *homeGroundBalls = [[NSNumber alloc] initWithLong: [self.eventCounter countHomeTeamWithEvents:INSOEventCodeGroundball]];
        NSNumber *visitorGroundBalls = [[NSNumber alloc] initWithLong: [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeGroundball]];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Groundballs</td><td>%@</td>\n", homeGroundBalls, visitorGroundBalls];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Faceoffs
    if ([self.game didRecordEvent:INSOEventCodeFaceoffWon] && [self.game didRecordEvent:INSOEventCodeFaceoffLost]) {
        NSInteger homeFaceoffsWon = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeFaceoffWon];
        NSInteger homeFaceoffsLost = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeFaceoffLost];
        NSInteger homeFaceoffs = homeFaceoffsWon + homeFaceoffsLost;
        CGFloat   homeFaceoffPct = (homeFaceoffs > 0) ? (CGFloat)homeFaceoffsWon / homeFaceoffs : 0.0;
        NSString *homeFaceoffPctString = [self.percentFormatter stringFromNumber:@(homeFaceoffPct)];
        
        NSInteger visitorFaceoffsWon = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeFaceoffWon];
        NSInteger visitorFaceoffsLost = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeFaceoffLost];
        NSInteger visitorFaceoffs = visitorFaceoffsWon + visitorFaceoffsLost;
        CGFloat   visitorFaceoffPct = (visitorFaceoffs > 0) ? (CGFloat)visitorFaceoffsWon / visitorFaceoffs : 0.0;
        NSString *visitorFaceoffPctString = [self.percentFormatter stringFromNumber:@(visitorFaceoffPct)];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@/%@ %@</td><td>Faceoffs</td><td>%@/%@ %@</td>\n", @(homeFaceoffsWon), @(homeFaceoffs), homeFaceoffPctString, @(visitorFaceoffsWon), @(visitorFaceoffs), visitorFaceoffPctString];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Draws (instead of faceoffs)
    if ([self.game didRecordEvent:INSOEventCodeDrawTaken] && [self.game didRecordEvent:INSOEventCodeDrawControl]) {
        NSInteger homeDrawsTaken = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeDrawTaken];
        NSInteger homeDrawControl = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeDrawControl];
        CGFloat   homeDrawControlPct = (homeDrawsTaken > 0) ? (CGFloat)homeDrawControl / homeDrawsTaken : 0.0;
        NSString *homeDrawControlPctString = [self.percentFormatter stringFromNumber:@(homeDrawControlPct)];
        
        NSInteger visitorDrawsTaken = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeDrawTaken];
        NSInteger visitorDrawControl = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeDrawControl];
        CGFloat   visitorDrawControlPct = (visitorDrawsTaken > 0) ? (CGFloat)visitorDrawControl / visitorDrawsTaken : 0.0;
        NSString *visitorDrawControlPctString = [self.percentFormatter stringFromNumber:@(visitorDrawControlPct)];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@/%@ %@</td><td>Draw Control</td><td>%@/%@ %@</td>\n", @(homeDrawControl), @(homeDrawsTaken), homeDrawControlPctString, @(visitorDrawControl), @(visitorDrawsTaken), visitorDrawControlPctString];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Clears
    if ([self.game didRecordEvent:INSOEventCodeClearSuccessful] && [self.game didRecordEvent:INSOEventCodeClearFailed]) {
        NSInteger homeClearSuccessful = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeClearSuccessful];
        NSInteger homeClearFailed = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeClearFailed];
        NSInteger homeClears = homeClearSuccessful + homeClearFailed;
        CGFloat   homeClearPct = (homeClears > 0) ? (CGFloat)homeClearSuccessful / homeClears : 0.0;
        NSString *homeClearPctString = [self.percentFormatter stringFromNumber:@(homeClearPct)];
        
        NSInteger visitorClearSuccessful = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeClearSuccessful];
        NSInteger visitorClearFailed = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeClearFailed];
        NSInteger visitorClears = visitorClearSuccessful + visitorClearFailed;
        CGFloat   visitorClearPct = (visitorClears > 0) ? (CGFloat)visitorClearSuccessful / visitorClears : 0.0;
        NSString *visitorClearPctString = [self.percentFormatter stringFromNumber:@(visitorClearPct)];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@/%@ %@</td><td>Clears</td><td>%@/%@ %@</td>\n", @(homeClearSuccessful), @(homeClears), homeClearPctString, @(visitorClearSuccessful), @(visitorClears), visitorClearPctString];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Interceptions
    if ([self.game didRecordEvent:INSOEventCodeInterception]) {
        NSNumber *homeInterceptions = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamWithEvents:INSOEventCodeInterception]];
        NSNumber *visitorInterceptions = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamWithEvents:INSOEventCodeInterception]];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Interceptions</td><td>%@</td>\n", homeInterceptions, visitorInterceptions];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Takeaways
    if ([self.game didRecordEvent:INSOEventCodeTakeaway]) {
        NSNumber *homeTakeaways = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamWithEvents:INSOEventCodeTakeaway]];
        NSNumber *visitorTakeaways = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamWithEvents:INSOEventCodeTakeaway]];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Takeaways</td><td>%@</td>\n", homeTakeaways, visitorTakeaways];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Turnovers
    if ([self.game didRecordEvent:INSOEventCodeTurnover]) {
        NSNumber *homeTurnovers = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamWithEvents:INSOEventCodeTurnover]];
        NSNumber *visitorTurnovers = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamWithEvents:INSOEventCodeTurnover]];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Turnovers</td><td>%@</td>\n", homeTurnovers, visitorTurnovers];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Caused Turnovers
    if ([self.game didRecordEvent:INSOEventCodeCausedTurnover]) {
        NSNumber *homeCausedTurnovers = [[NSNumber alloc] initWithLong: [self.eventCounter countHomeTeamWithEvents:INSOEventCodeCausedTurnover]];
        NSNumber *visitorCausedTurnovers = [[NSNumber alloc] initWithLong: [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeCausedTurnover]];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Caused Turnovers</td><td>%@</td>\n", homeCausedTurnovers, visitorCausedTurnovers];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Unforced Errors
    if ([self.game didRecordEvent:INSOEventCodeUnforcedError]) {
        NSNumber *homeUnforcedErrors = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamWithEvents:INSOEventCodeUnforcedError]];
        NSNumber *visitorUnforcedErrors = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamWithEvents:INSOEventCodeUnforcedError]];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Unforced Errors</td><td>%@</td>\n", homeUnforcedErrors, visitorUnforcedErrors];
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
    
    // Shots
    if ([self.game didRecordEvent:INSOEventCodeShot]) {
        NSNumber *homeShots = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamWithEvents:INSOEventCodeShot]];
        NSNumber *visitorShots = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamWithEvents:INSOEventCodeShot]];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Shots</td><td>%@</td>\n", homeShots, visitorShots];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Goals
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        NSNumber *homeGoals = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamWithEvents:INSOEventCodeGoal]];
        NSNumber *visitorGoals = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamWithEvents:INSOEventCodeGoal]];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Goals</td><td>%@</td>\n", homeGoals, visitorGoals];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Shooting pct. (Percent of shots that result in a goal)
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger homeShots = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeShot];
        NSInteger homeGoals = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeGoal];
        CGFloat   homeShootingPct = (homeShots > 0) ? (CGFloat)homeGoals / homeShots : 0.0;
        NSString *homeShootingPctString = [self.percentFormatter stringFromNumber:@(homeShootingPct)];
        
        NSInteger visitorShots = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeShot];
        NSInteger visitorGoals = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeGoal];
        CGFloat   visitorShootingPct = (visitorShots > 0) ? (CGFloat)visitorGoals / visitorShots : 0.0;
        NSString *visitorShootingPctString = [self.percentFormatter stringFromNumber:@(visitorShootingPct)];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Shooting Percent<br/>(Goals / Shots)</td><td>%@</td>\n", homeShootingPctString, visitorShootingPctString];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Shots on goal
    if ([self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        NSNumber *homeSOG = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamWithEvents:INSOEventCodeShotOnGoal]];
        NSNumber *visitorSOG = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamWithEvents:INSOEventCodeShotOnGoal]];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Shots on Goal</td><td>%@</td>\n", homeSOG, visitorSOG];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Misses = shots - shots on goal;
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        NSInteger homeShots = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeShot];
        NSInteger homeSOG = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeShotOnGoal];
        NSInteger homeMisses = homeShots - homeSOG;
        homeMisses = homeMisses < 0 ? 0 : homeMisses;
        
        NSInteger visitorShots = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeShot];
        NSInteger visitorSOG = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeShotOnGoal];
        NSInteger visitorMisses = visitorShots - visitorSOG;
        visitorMisses = visitorMisses < 0 ? 0 : visitorMisses;
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Misses</td><td>%@</td>\n", @(homeMisses), @(visitorMisses)];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Shooting accuracy = shots on goal / shots (what percent of your shots were on goal)
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        NSInteger homeShots = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeShot];
        NSInteger homeSOG = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeShotOnGoal];
        CGFloat   homeAccuracy = (homeShots > 0) ? (CGFloat)homeSOG / homeShots : 0.0;
        NSString *homeAccuracyString = [self.percentFormatter stringFromNumber:@(homeAccuracy)];
        
        NSInteger visitorShots = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeShot];
        NSInteger visitorSOG = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeShotOnGoal];
        CGFloat   visitorAccuracy = (visitorShots > 0) ? (CGFloat)visitorSOG / visitorShots : 0.0;
        NSString *visitorAccuracyString = [self.percentFormatter stringFromNumber:@(visitorAccuracy)];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Shooting Accuracy<br/>(Shots on Goal / Shots)</td><td>%@</td>\n", homeAccuracyString, visitorAccuracyString];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Assists
    if ([self.game didRecordEvent:INSOEventCodeAssist]) {
        NSNumber *homeAssists = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamWithEvents:INSOEventCodeAssist]];
        NSNumber *visitorAssists = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamWithEvents:INSOEventCodeAssist]];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Assists</td><td>%@</td>\n", homeAssists, visitorAssists];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Saves
    if ([self.game didRecordEvent:INSOEventCodeSave]) {
        NSNumber *homeSaves = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamWithEvents:INSOEventCodeSave]];
        NSNumber *visitorSaves = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamWithEvents:INSOEventCodeSave]];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Saves</td><td>%@</td>\n", homeSaves, visitorSaves];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Goals allowed
    if ([self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        NSNumber *homeGoalsAllowed = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamWithEvents:INSOEventCodeGoalAllowed]];
        NSNumber *visitorGoalsAllowed = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamWithEvents:INSOEventCodeGoalAllowed]];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Goals Allowed</td><td>%@</td>\n", homeGoalsAllowed, visitorGoalsAllowed];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Save pct. = saves / (saves + goals allowed)
    if ([self.game didRecordEvent:INSOEventCodeSave] && [self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        NSInteger homeSaves = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeSave];
        NSInteger homeGoalsAllowed = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeGoalAllowed];
        CGFloat   homeSavePct = (homeSaves + homeGoalsAllowed) > 0 ? (CGFloat)homeSaves / (homeSaves + homeGoalsAllowed) : 0.0;
        NSString *homeSavePctString = [self.percentFormatter stringFromNumber:@(homeSavePct)];
        
        NSInteger visitorSaves = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeSave];
        NSInteger visitorGoalsAllowed = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeGoalAllowed];
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
    
    // EMO
    if ([self.game didRecordEvent:INSOEventCodeEMO]) {
        NSNumber *homeEMO = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamWithEvents:INSOEventCodeEMO]];
        NSNumber *visitorEMO = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamWithEvents:INSOEventCodeEMO]];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>EMO</td><td>%@</td>\n", homeEMO, visitorEMO];
        [emoSection appendString:@"</tr>\n"];
    }
    
    // EMO goals
    if ([self.game didRecordEvent:INSOEventCodeEMO] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger homeEMOGoals = [self.eventCounter extraManGoalsForHomeTeam];
        NSInteger visitorEMOGoals = [self.eventCounter extraManGoalsForVisitingTeam];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>EMO Goals</td><td>%@</td>\n", @(homeEMOGoals), @(visitorEMOGoals)];
        [emoSection appendString:@"</tr>\n"];
        
        // Just do the emo scoring here while we're at it.
        // EMO scoring = emo goals / emo
        NSInteger homeEMO = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeEMO];
        NSInteger visitorEMO = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeEMO];
        
        CGFloat homeEMOScoring = (homeEMO > 0) ? (CGFloat)homeEMOGoals / homeEMO : 0.0;
        NSString *homeEMOScoringString = [self.percentFormatter stringFromNumber:@(homeEMOScoring)];
        CGFloat visitorEMOScoring = (visitorEMO > 0) ? (CGFloat)visitorEMOGoals / visitorEMO : 0.0;
        NSString *visitorEMOScoringString = [self.percentFormatter stringFromNumber:@(visitorEMOScoring)];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>EMO Scoring</td><td>%@</td>\n", homeEMOScoringString, visitorEMOScoringString];
        [emoSection appendString:@"</tr>\n"];
    }
    
    // Man-up (girls call it man-up, boys call it emo. Go figure.)
    if ([self.game didRecordEvent:INSOEventCodeManUp]) {
        NSNumber *homeManUp = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamWithEvents:INSOEventCodeManUp]];
        NSNumber *visitorManUp = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamWithEvents:INSOEventCodeManUp]];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>Man-up</td><td>%@</td>\n", homeManUp, visitorManUp];
        [emoSection appendString:@"</tr>\n"];
    }
    
    // Man-up scoring
    if ([self.game didRecordEvent:INSOEventCodeManUp] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger homeManUpGoals = [self.eventCounter extraManGoalsForHomeTeam];
        NSInteger visitorManUpGoals = [self.eventCounter extraManGoalsForVisitingTeam];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>Man-up Goals</td><td>%@</td>\n", @(homeManUpGoals), @(visitorManUpGoals)];
        [emoSection appendString:@"</tr>\n"];
        
        // Just do the emo scoring here while we're at it.
        // EMO scoring = emo goals / emo
        NSInteger homeManUp = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeManUp];
        NSInteger visitorManUp = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeManUp];
        
        CGFloat homeManUpScoring = (homeManUp > 0) ? (CGFloat)homeManUpGoals / homeManUp : 0.0;
        NSString *homeManUpScoringString = [self.percentFormatter stringFromNumber:@(homeManUpScoring)];
        CGFloat visitorManUpScoring = (visitorManUp > 0) ? (CGFloat)visitorManUpGoals / visitorManUp : 0.0;
        NSString *visitorManUpScoringString = [self.percentFormatter stringFromNumber:@(visitorManUpScoring)];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>Man-up Scoring</td><td>%@</td>\n", homeManUpScoringString, visitorManUpScoringString];
        [emoSection appendString:@"</tr>\n"];
    }
    
    
    // Man-down
    if ([self.game didRecordEvent:INSOEventCodeManDown]) {
        NSNumber *homeManDown = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamWithEvents:INSOEventCodeManDown]];
        NSNumber *visitorManDown = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamWithEvents:INSOEventCodeManDown]];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>Man-down</td><td>%@</td>\n", homeManDown, visitorManDown];
        [emoSection appendString:@"</tr>\n"];
    }
    
    // Man-down goals allowed
    // A man-down goal allowed is an extra-man goal scored by the other team.
    // Proceed accordingly.
    if ([self.game didRecordEvent:INSOEventCodeManDown] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger homeManDown = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeManDown];
        NSInteger visitorManDown = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeManDown];
        
        NSInteger homeMDGoalsAllowed = [self.eventCounter extraManGoalsForVisitingTeam];
        NSInteger visitorMDGoalsAllowed = [self.eventCounter extraManGoalsForHomeTeam];
        
        CGFloat homeManDownScoring = (homeManDown > 0) ? (CGFloat)homeMDGoalsAllowed / homeManDown : 0.0;
        CGFloat visitorManDownScoring = (visitorManDown > 0) ? (CGFloat)visitorMDGoalsAllowed / visitorManDown : 0.0;
        
        // Man-down scoring = man-down goals allowed / man-down
        NSString *homeManDownScoringString = [self.percentFormatter stringFromNumber:@(homeManDownScoring)];
        NSString *visitorManDownScoringString = [self.percentFormatter stringFromNumber:@(visitorManDownScoring)];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>Man-down Goals Allowed</td><td>%@</td>\n", @(homeMDGoalsAllowed), @(visitorMDGoalsAllowed)];
        [emoSection appendString:@"</tr>\n"];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>Man-down Scoring</td><td>%@</td>\n", homeManDownScoringString, visitorManDownScoringString];
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
    
    if (self.isExportingForBoys) {
        // Penalties
        NSNumber *homePenalties = [[NSNumber alloc] initWithLong:[self.eventCounter totalPenaltiesForHomeTeam]];
        NSNumber *visitorPenalties = [[NSNumber alloc] initWithLong:[self.eventCounter totalPenaltiesForVisitingTeam]];
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Penalties</td><td>%@</td>\n", homePenalties, visitorPenalties];
        [penaltySection appendString:@"</tr>\n"];
        
        // Penalty Time
        NSInteger homePenaltySeconds = [self.eventCounter totalPenaltyTimeForHomeTeam];
        NSInteger visitorPenaltySeconds = [self.eventCounter totalPenaltyTimeForVisitingTeam];
        
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
        NSInteger homeFouls = [self.eventCounter totalFoulsForHomeTeam];
        NSInteger visitorFouls = [self.eventCounter totalFoulsForVisitingTeam];
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Fouls</td><td>%@</td>\n", @(homeFouls), @(visitorFouls)];
        [penaltySection appendString:@"</tr>\n"];
        
        // 8-meter awarded
        NSInteger home8m = [self.eventCounter countHomeTeamWithEvents:INSOEventCode8mFreePosition];
        NSInteger visitor8m = [self.eventCounter countVisitingTeamWithEvents:INSOEventCode8mFreePosition];
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>8m (Free Position)</td><td>%@</td>\n", @(home8m), @(visitor8m)];
        [penaltySection appendString:@"</tr>\n"];
        
        // 8-meter shots and goals
        NSNumber *homeFPS = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamFreePositionWithEvents:INSOEventCodeShot]];
        NSNumber *visitorFPS = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamFreePositionWithEvents:INSOEventCodeShot]];
        
        NSNumber *homeFPSOG = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamFreePositionWithEvents:INSOEventCodeShotOnGoal]];
        NSNumber *visitorFPSOG = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamFreePositionWithEvents:INSOEventCodeShotOnGoal]];
        
        NSNumber *homeFPGoal = [[NSNumber alloc] initWithLong:[self.eventCounter countHomeTeamFreePositionWithEvents:INSOEventCodeGoal]];
        NSNumber *visitorFPGoal = [[NSNumber alloc] initWithLong:[self.eventCounter countVisitingTeamFreePositionWithEvents:INSOEventCodeGoal]];
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@/%@/%@</td><td>8m (Free Position)<br />Shots/SOG/Goals</td><td>%@/%@/%@</td>\n", homeFPS, homeFPSOG, homeFPGoal, visitorFPS, visitorFPSOG,visitorFPGoal];
        [penaltySection appendString:@"</tr>\n"];
        
        // Green cards
        NSInteger homeGreenCards = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeGreenCard];
        NSInteger visitorGreenCards = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeGreenCard];
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Green Cards</td><td>%@</td>\n", @(homeGreenCards), @(visitorGreenCards)];
        [penaltySection appendString:@"</tr>\n"];
        
        // Yellow cards
        NSInteger homeYellowCards = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeYellowCard];
        NSInteger visitorYellowCards = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeYellowCard];
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Yellow Cards</td><td>%@</td>\n", @(homeYellowCards), @(visitorYellowCards)];
        [penaltySection appendString:@"</tr>\n"];
        
        // Red cards
        NSInteger homeRedCards = [self.eventCounter countHomeTeamWithEvents:INSOEventCodeRedCard];
        NSInteger visitorRedCards = [self.eventCounter countVisitingTeamWithEvents:INSOEventCodeRedCard];
        
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

- (NSArray *)boysHeaderRowForPlayerStats
{
    NSMutableArray* header = [NSMutableArray new];
    
    // First the player number
    [header addObject:@"Player"];
    
    // Now the event titles
    // Really should localize this...sigh
    Event *event;
    
    // Groundballs
    if ([self.game didRecordEvent:INSOEventCodeGroundball]) {
    event = [Event eventForCode:INSOEventCodeGroundball inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    }
    
    // Faceoff attempts
    if ([self.game didRecordEvent:INSOEventCodeFaceoffWon] && [self.game didRecordEvent:INSOEventCodeFaceoffLost]) {
    [header addObject:@"Faceoffs"];
    }
    
    // Faceoffs won
    if ([self.game didRecordEvent:INSOEventCodeFaceoffWon] && [self.game didRecordEvent:INSOEventCodeFaceoffLost]) {
    event = [Event eventForCode:INSOEventCodeFaceoffWon inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    }
    
    // Faceoff %
    if ([self.game didRecordEvent:INSOEventCodeFaceoffWon] && [self.game didRecordEvent:INSOEventCodeFaceoffLost]) {
        [header addObject:@"Faceoff Pct."];
    }
    
    // Turnovers
    if ([self.game didRecordEvent:INSOEventCodeTurnover]) {
        event = [Event eventForCode:INSOEventCodeTurnover inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Caused turnover
    if ([self.game didRecordEvent:INSOEventCodeCausedTurnover]) {
        event = [Event eventForCode:INSOEventCodeCausedTurnover inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Interceptions
    if ([self.game didRecordEvent:INSOEventCodeInterception]) {
    event = [Event eventForCode:INSOEventCodeInterception inManagedObjectContext:self.game.managedObjectContext];
    if (event) {
        [header addObject:event.title];
    }
    event = nil;
    }
    
    // Takeaways
    if ([self.game didRecordEvent:INSOEventCodeTakeaway]) {
        event = [Event eventForCode:INSOEventCodeTakeaway inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Unforced Errors
    if ([self.game didRecordEvent:INSOEventCodeUnforcedError]) {
        event = [Event eventForCode:INSOEventCodeUnforcedError inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Shots
    if ([self.game didRecordEvent:INSOEventCodeShot]) {
        event = [Event eventForCode:INSOEventCodeShot inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Goals
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        event = [Event eventForCode:INSOEventCodeGoal inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Assists
    if ([self.game didRecordEvent:INSOEventCodeAssist]) {
        event = [Event eventForCode:INSOEventCodeAssist inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Points
    if ([self.game didRecordEvent:INSOEventCodeAssist] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        [header addObject:@"Points"];
    }
    
    // Shooting %
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        [header addObject:@"Shooting Pct."];
    }
    
    // SOG
    if ([self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        event = [Event eventForCode:INSOEventCodeShotOnGoal inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Misses
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        [header addObject:@"Misses"];
    }
    
    // Shooting accuracy
    if ([self.game didRecordEvent:INSOEventCodeShotOnGoal] && [self.game didRecordEvent:INSOEventCodeShot]) {
        [header addObject:@"Shooting Accuracy"];
    }
    
    // Saves
    if ([self.game didRecordEvent:INSOEventCodeSave]) {
        event = [Event eventForCode:INSOEventCodeSave inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Goals allowed
    if ([self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        event = [Event eventForCode:INSOEventCodeGoalAllowed inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Save %
    if ([self.game didRecordEvent:INSOEventCodeSave] && [self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        [header addObject:@"Save Pct."];
    }
    
    // Penalties
    if (self.shouldExportPenalties && self.isExportingForBoys) {
        [header addObject:@"Penalties"];
        [header addObject:@"Penalty time"];
    }
    
    return header;
}

- (NSArray *)girlsHeaderRowForPlayerStats
{
    NSMutableArray* header = [NSMutableArray new];
    
    // First the player number
    [header addObject:@"Player"];
    
    // Now the event titles
    // Really should localize this...sigh
    Event *event;
    
    // Groundballs
    if ([self.game didRecordEvent:INSOEventCodeGroundball]) {
        event = [Event eventForCode:INSOEventCodeGroundball inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Draws taken
    if ([self.game didRecordEvent:INSOEventCodeDrawTaken]) {
        event = [Event eventForCode:INSOEventCodeDrawTaken inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Draw possession
    if ([self.game didRecordEvent:INSOEventCodeDrawPossession]) {
        event = [Event eventForCode:INSOEventCodeDrawPossession inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Draw control
    if ([self.game didRecordEvent:INSOEventCodeDrawControl]) {
        event = [Event eventForCode:INSOEventCodeDrawControl inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Draw control percent
    [header addObject:@"Draw Control Pct."];
    
    // Caused turnover
    if ([self.game didRecordEvent:INSOEventCodeCausedTurnover]) {
        event = [Event eventForCode:INSOEventCodeCausedTurnover inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Interceptions
    if ([self.game didRecordEvent:INSOEventCodeInterception]) {
        event = [Event eventForCode:INSOEventCodeInterception inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Takeaways
    if ([self.game didRecordEvent:INSOEventCodeTakeaway]) {
        event = [Event eventForCode:INSOEventCodeTakeaway inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Unforced Errors
    if ([self.game didRecordEvent:INSOEventCodeUnforcedError]) {
        event = [Event eventForCode:INSOEventCodeUnforcedError inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Shots
    if ([self.game didRecordEvent:INSOEventCodeShot]) {
        event = [Event eventForCode:INSOEventCodeShot inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Goals
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        event = [Event eventForCode:INSOEventCodeGoal inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Assists
    if ([self.game didRecordEvent:INSOEventCodeAssist]) {
        event = [Event eventForCode:INSOEventCodeAssist inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Shooting %
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        [header addObject:@"Shooting Pct."];
    }
    
    // SOG
    if ([self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        event = [Event eventForCode:INSOEventCodeShotOnGoal inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Misses
    if ([self.game didRecordEvent:INSOEventCodeShot] && [self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        [header addObject:@"Misses"];
    }
    
    // Shooting accuracy
    if ([self.game didRecordEvent:INSOEventCodeShotOnGoal] && [self.game didRecordEvent:INSOEventCodeShot]) {
        [header addObject:@"Shooting Accuracy"];
    }
    
    // Free postion awarded
    if ([self.game didRecordEvent:INSOEventCode8mFreePosition]) {
        event = [Event eventForCode:INSOEventCode8mFreePosition inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Free position shot
    if ([self.game didRecordEvent:INSOEventCodeShot]) {
        [header addObject:@"Free Position Shots"];
    }
    
    // Free position goal
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        [header addObject:@"Free Position Goals"];
    }
    
    // Saves
    if ([self.game didRecordEvent:INSOEventCodeSave]) {
        event = [Event eventForCode:INSOEventCodeSave inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Goals allowed
    if ([self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        event = [Event eventForCode:INSOEventCodeGoalAllowed inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Save %
    if ([self.game didRecordEvent:INSOEventCodeSave] && [self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        [header addObject:@"Save Pct."];
    }
    
    // Fouls (major and minor)
    if ([self.game didRecordEvent:INSOEventCodeMajorFoul] || [self.game didRecordEvent:INSOEventCodeMinorFoul]) {
        [header addObject:@"Fouls"];
    }
    
    // Yellow cards
    if ([self.game didRecordEvent:INSOEventCodeYellowCard]) {
        event = [Event eventForCode:INSOEventCodeYellowCard inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    // Red cards
    if ([self.game didRecordEvent:INSOEventCodeRedCard]) {
        event = [Event eventForCode:INSOEventCodeRedCard inManagedObjectContext:self.game.managedObjectContext];
        if (event) {
            [header addObject:event.title];
        }
        event = nil;
    }
    
    return header;
}


- (NSArray*)boysDataRowForPlayer:(RosterPlayer*)rosterPlayer
{
    NSMutableArray* dataRow = [NSMutableArray new];
    
    // First goes the player
    [dataRow addObject:rosterPlayer.number];
    
    // Groundballs
    if ([self.game didRecordEvent:INSOEventCodeGroundball]) {
        [dataRow addObject: [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeGroundball for:rosterPlayer]]];
    }
    
    // Faceoff attempts
    NSNumber *faceoffsWon;
    NSNumber *faceoffsLost;
    NSNumber *faceoffAttempts;
    
    if ([self.game didRecordEvent:INSOEventCodeFaceoffWon] && [self.game didRecordEvent:INSOEventCodeFaceoffLost]) {
        faceoffsWon =[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeFaceoffWon for:rosterPlayer]];
        faceoffsLost = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeFaceoffLost for:rosterPlayer]];
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
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeTurnover for:rosterPlayer]]];
    }
    
    // Caused turnover
    if ([self.game didRecordEvent:INSOEventCodeCausedTurnover]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeCausedTurnover for:rosterPlayer]]];
    }
    
    // Interceptions
    if ([self.game didRecordEvent:INSOEventCodeInterception]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeInterception for:rosterPlayer]]];
    }
    
    // Takeaways
    if ([self.game didRecordEvent:INSOEventCodeTakeaway]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeTakeaway for:rosterPlayer]]];
    }
    
    // Unforced Errors
    if ([self.game didRecordEvent:INSOEventCodeUnforcedError]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeUnforcedError for:rosterPlayer]]];
    }
    
    // Shots
    NSNumber *shots;
    if ([self.game didRecordEvent:INSOEventCodeShot]) {
        shots = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeShot for:rosterPlayer]];
        [dataRow addObject:shots];
    }
    
    // Goals
    NSNumber *goals;
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        goals = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeGoal for:rosterPlayer]];
        [dataRow addObject:goals];
    }
    
    // Assists
    NSNumber *assists;
    if ([self.game didRecordEvent:INSOEventCodeAssist]) {
        assists = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeAssist for:rosterPlayer]];
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
        sog = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeShotOnGoal for:rosterPlayer]];
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
        saves = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeSave for:rosterPlayer]];
        [dataRow addObject:saves];
    }
    
    // Goals allowed
    NSNumber *goalsAllowed;
    if ([self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        goalsAllowed = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeGoalAllowed for:rosterPlayer]];
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
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter totalBoysPenaltiesFor:rosterPlayer]]];
        
        double totalPenaltyTime = [[[NSNumber alloc] initWithLong: [self.eventCounter totalPenaltyTimeFor:rosterPlayer]] doubleValue];
        
        NSDateComponentsFormatter* penaltyTimeFormatter = [[NSDateComponentsFormatter alloc] init];
        penaltyTimeFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropLeading;
        penaltyTimeFormatter.allowedUnits = (NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
        
        [dataRow addObject:[penaltyTimeFormatter stringFromTimeInterval:totalPenaltyTime]];
    }
    
    return dataRow;
}

- (NSArray*)girlsDataRowForPlayer:(RosterPlayer*)rosterPlayer
{
    NSMutableArray* dataRow = [NSMutableArray new];
    
    // First the player number
    [dataRow addObject:rosterPlayer.number];
    
    // Groundballs
    if ([self.game didRecordEvent:INSOEventCodeGroundball]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeGroundball for:rosterPlayer]]];
    }
    
    // Draw stuff
    NSNumber *drawsTaken;
    NSNumber *drawPossession;
    
    // Draw taken
    if ([self.game didRecordEvent:INSOEventCodeDrawTaken]) {
        drawsTaken = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeDrawTaken for:rosterPlayer]];
        [dataRow addObject:drawsTaken];
    }
    
    // Draw possession
    if ([self.game didRecordEvent:INSOEventCodeDrawPossession]) {
        drawPossession = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeDrawPossession for:rosterPlayer]];
        [dataRow addObject:drawPossession];
    }
    
    // Draw control
    if ([self.game didRecordEvent:INSOEventCodeDrawControl]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeDrawControl for:rosterPlayer]]];
    }
    
    // Draw control percent (actually report draw possession / draws taken)
    NSInteger drawsTakenInt = [drawsTaken integerValue];
    NSInteger drawPossessionInt = [drawPossession integerValue];
    CGFloat drawControlPercent = 0.0;
    if (drawsTakenInt > 0) {
        drawControlPercent = (CGFloat)drawPossessionInt / drawsTakenInt;
        [dataRow addObject:[self.percentFormatter stringFromNumber:@(drawControlPercent)]];
    } else {
        [dataRow addObject:@""];
    }
    
    // Caused turnover
    if ([self.game didRecordEvent:INSOEventCodeCausedTurnover]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeCausedTurnover for:rosterPlayer]]];
    }
    
    // Interceptions
    if ([self.game didRecordEvent:INSOEventCodeInterception]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeInterception for:rosterPlayer]]];
    }
    
    // Takeaways
    if ([self.game didRecordEvent:INSOEventCodeTakeaway]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeTakeaway for:rosterPlayer]]];
    }
    
    // Unforced errors
    if ([self.game didRecordEvent:INSOEventCodeUnforcedError]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeUnforcedError for:rosterPlayer]]];
    }
    
    // Shots
    NSNumber *shots;
    if ([self.game didRecordEvent:INSOEventCodeShot]) {
        shots = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeShot for:rosterPlayer]];
        [dataRow addObject:shots];
    }
    
    // Goals
    NSNumber *goals;
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        goals = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeGoal for:rosterPlayer]];
        [dataRow addObject:goals];
    }
    
    // Assists
    if ([self.game didRecordEvent:INSOEventCodeAssist]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeAssist for:rosterPlayer]]];
    }
    
    // Shooting %
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
        sog = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeShotOnGoal for:rosterPlayer]];
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
    
    // Free postion awarded
    if ([self.game didRecordEvent:INSOEventCode8mFreePosition]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCode8mFreePosition for:rosterPlayer]]];
    }
    
    // Free position shot
    if ([self.game didRecordEvent:INSOEventCodeShot]) {
        NSNumber *freePositionShot = [[NSNumber alloc] initWithLong: [self.eventCounter countFreePositionWithEvents:INSOEventCodeShot for:rosterPlayer]];
        [dataRow addObject:freePositionShot];
    }
    
    // Free position goal
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        NSNumber *freePositionGoal = [[NSNumber alloc] initWithLong: [self.eventCounter countFreePositionWithEvents:INSOEventCodeGoal for:rosterPlayer]];
        [dataRow addObject:freePositionGoal];
    }
    
    // Saves
    NSNumber *saves;
    if ([self.game didRecordEvent:INSOEventCodeSave]) {
        saves = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeSave for:rosterPlayer]];
        [dataRow addObject:saves];
    }
    
    // Goals allowed
    NSNumber *goalsAllowed;
    if ([self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        goalsAllowed = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeGoalAllowed for:rosterPlayer]];
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
    
    // Fouls (major and minor)
    if ([self.game didRecordEvent:INSOEventCodeMajorFoul] || [self.game didRecordEvent:INSOEventCodeMinorFoul]) {
        NSInteger totalFouls = 0;
        NSNumber *majorFouls = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeMajorFoul for:rosterPlayer]];
        NSNumber *minorFouls = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeMinorFoul for:rosterPlayer]];
        totalFouls = [majorFouls integerValue] + [minorFouls integerValue];
        [dataRow addObject:@(totalFouls)];
    }
    
    // Yellow cards
    if ([self.game didRecordEvent:INSOEventCodeYellowCard]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeYellowCard for:rosterPlayer]]];
    }
    
    // Red cards
    if ([self.game didRecordEvent:INSOEventCodeRedCard]) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:INSOEventCodeRedCard for:rosterPlayer]]];
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
    
    // Now a count of every event for that number
    for (Event* event in self.maxPrepsBoysEvents) {
        NSNumber* eventCount = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:event.eventCodeValue for:rosterPlayer]];
        [dataRow addObject:eventCount];
    }
    
    // now add faceoff attempts if we recorded faceoffs won.
    if ([self.maxPrepsBoysEvents containsObject:[Event eventForCode:INSOEventCodeFaceoffWon inManagedObjectContext:self.game.managedObjectContext]]) {
        // Only report faceoff attempts if we've actually collected faceoffs.
        NSInteger faceoffsWon = [self.eventCounter countWithEvents:INSOEventCodeFaceoffWon for:rosterPlayer];
        NSInteger faceoffsLost = [self.eventCounter countWithEvents:INSOEventCodeFaceoffLost for:rosterPlayer];
        NSNumber* faceoffAttempts = [NSNumber numberWithInteger:(faceoffsWon + faceoffsLost)];
        [dataRow addObject:faceoffAttempts];
    }
    
    // And now the penalties
    if (self.shouldExportPenalties) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter totalBoysPenaltiesFor:rosterPlayer]]];
        
        NSInteger totalPenaltyTime = [self.eventCounter totalPenaltyTimeFor:rosterPlayer];
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
    
    // Now a count of every event for that number
    for (Event* event in self.maxPrepsGirlsEvents) {
        NSNumber* eventCount = [[NSNumber alloc] initWithLong: [self.eventCounter countWithEvents:event.eventCodeValue for:rosterPlayer]];
        [dataRow addObject:eventCount];
    }
    
    // And now the penalties
    if (self.shouldExportPenalties) {
        [dataRow addObject:[[NSNumber alloc] initWithLong: [self.eventCounter totalGirlsPenaltiesFor:rosterPlayer]]];
    }
    
    return dataRow;
}

@end
