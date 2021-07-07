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

@property (nonatomic) INSOGameEventCounter *eventCounter;

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
  
// Need to figure out which product we're using
//        if ([[[INSOProductManager sharedManager] appProductName] isEqualToString:INSOMensProductName]) {
            _isExportingForBoys = YES;
//        } else {
//            _isExportingForBoys = NO;
//        }
        
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
        _eventCounter = [[INSOGameEventCounter alloc] initWithGame:_game];
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
        NSNumber *homeGroundBalls = [self.eventCounter eventCountForHomeTeam:INSOEventCodeGroundball];
        NSNumber *visitorGroundBalls = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeGroundball];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Groundballs</td><td>%@</td>\n", homeGroundBalls, visitorGroundBalls];
        [fieldingSection appendString:@"</tr>\n"];
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
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@/%@ %@</td><td>Faceoffs</td><td>%@/%@ %@</td>\n", @(homeFaceoffsWon), @(homeFaceoffs), homeFaceoffPctString, @(visitorFaceoffsWon), @(visitorFaceoffs), visitorFaceoffPctString];
        [fieldingSection appendString:@"</tr>\n"];
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
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@/%@ %@</td><td>Draw Control</td><td>%@/%@ %@</td>\n", @(homeDrawControl), @(homeDrawsTaken), homeDrawControlPctString, @(visitorDrawControl), @(visitorDrawsTaken), visitorDrawControlPctString];
        [fieldingSection appendString:@"</tr>\n"];
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
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@/%@ %@</td><td>Clears</td><td>%@/%@ %@</td>\n", @(homeClearSuccessful), @(homeClears), homeClearPctString, @(visitorClearSuccessful), @(visitorClears), visitorClearPctString];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Interceptions
    if ([self.game didRecordEvent:INSOEventCodeInterception]) {
        NSNumber *homeInterceptions = [self.eventCounter eventCountForHomeTeam:INSOEventCodeInterception];
        NSNumber *visitorInterceptions = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeInterception];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Interceptions</td><td>%@</td>\n", homeInterceptions, visitorInterceptions];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Takeaways
    if ([self.game didRecordEvent:INSOEventCodeTakeaway]) {
        NSNumber *homeTakeaways = [self.eventCounter eventCountForHomeTeam:INSOEventCodeTakeaway];
        NSNumber *visitorTakeaways = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeTakeaway];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Takeaways</td><td>%@</td>\n", homeTakeaways, visitorTakeaways];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Turnovers
    if ([self.game didRecordEvent:INSOEventCodeTurnover]) {
        NSNumber *homeTurnovers = [self.eventCounter eventCountForHomeTeam:INSOEventCodeTurnover];
        NSNumber *visitorTurnovers = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeTurnover];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Turnovers</td><td>%@</td>\n", homeTurnovers, visitorTurnovers];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Caused Turnovers
    if ([self.game didRecordEvent:INSOEventCodeCausedTurnover]) {
        NSNumber *homeCausedTurnovers = [self.eventCounter eventCountForHomeTeam:INSOEventCodeCausedTurnover];
        NSNumber *visitorCausedTurnovers = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeCausedTurnover];
        
        [fieldingSection appendString:@"<tr>\n"];
        [fieldingSection appendFormat:@"<td>%@</td><td>Caused Turnovers</td><td>%@</td>\n", homeCausedTurnovers, visitorCausedTurnovers];
        [fieldingSection appendString:@"</tr>\n"];
    }
    
    // Unforced Errors
    if ([self.game didRecordEvent:INSOEventCodeUnforcedError]) {
        NSNumber *homeUnforcedErrors = [self.eventCounter eventCountForHomeTeam:INSOEventCodeUnforcedError];
        NSNumber *visitorUnforcedErrors = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeUnforcedError];
        
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
        NSNumber *homeShots = [self.eventCounter eventCountForHomeTeam:INSOEventCodeShot];
        NSNumber *visitorShots = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeShot];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Shots</td><td>%@</td>\n", homeShots, visitorShots];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Goals
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        NSNumber *homeGoals = [self.eventCounter eventCountForHomeTeam:INSOEventCodeGoal];
        NSNumber *visitorGoals = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeGoal];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Goals</td><td>%@</td>\n", homeGoals, visitorGoals];
        [scoringSection appendString:@"</tr>\n"];
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
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Shooting Percent<br/>(Goals / Shots)</td><td>%@</td>\n", homeShootingPctString, visitorShootingPctString];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    
    // Shots on goal
    if ([self.game didRecordEvent:INSOEventCodeShotOnGoal]) {
        NSNumber *homeSOG = [self.eventCounter eventCountForHomeTeam:INSOEventCodeShotOnGoal];
        NSNumber *visitorSOG = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeShotOnGoal];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Shots on Goal</td><td>%@</td>\n", homeSOG, visitorSOG];
        [scoringSection appendString:@"</tr>\n"];
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
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Misses</td><td>%@</td>\n", @(homeMisses), @(visitorMisses)];
        [scoringSection appendString:@"</tr>\n"];
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
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Shooting Accuracy<br/>(Shots on Goal / Shots)</td><td>%@</td>\n", homeAccuracyString, visitorAccuracyString];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Assists
    if ([self.game didRecordEvent:INSOEventCodeAssist]) {
        NSNumber *homeAssists = [self.eventCounter eventCountForHomeTeam:INSOEventCodeAssist];
        NSNumber *visitorAssists = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeAssist];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Assists</td><td>%@</td>\n", homeAssists, visitorAssists];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Saves
    if ([self.game didRecordEvent:INSOEventCodeSave]) {
        NSNumber *homeSaves = [self.eventCounter eventCountForHomeTeam:INSOEventCodeSave];
        NSNumber *visitorSaves = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeSave];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Saves</td><td>%@</td>\n", homeSaves, visitorSaves];
        [scoringSection appendString:@"</tr>\n"];
    }
    
    // Goals allowed
    if ([self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        NSNumber *homeGoalsAllowed = [self.eventCounter eventCountForHomeTeam:INSOEventCodeGoalAllowed];
        NSNumber *visitorGoalsAllowed = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeGoalAllowed];
        
        [scoringSection appendString:@"<tr>\n"];
        [scoringSection appendFormat:@"<td>%@</td><td>Goals Allowed</td><td>%@</td>\n", homeGoalsAllowed, visitorGoalsAllowed];
        [scoringSection appendString:@"</tr>\n"];
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
        NSNumber *homeEMO = [self.eventCounter eventCountForHomeTeam:INSOEventCodeEMO];
        NSNumber *visitorEMO = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeEMO];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>EMO</td><td>%@</td>\n", homeEMO, visitorEMO];
        [emoSection appendString:@"</tr>\n"];
    }
    
    // EMO goals
    if ([self.game didRecordEvent:INSOEventCodeEMO] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger homeEMOGoals = [[self.eventCounter extraManGoalsForHomeTeam] integerValue];
        NSInteger visitorEMOGoals = [[self.eventCounter extraManGoalsForVisitingTeam] integerValue];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>EMO Goals</td><td>%@</td>\n", @(homeEMOGoals), @(visitorEMOGoals)];
        [emoSection appendString:@"</tr>\n"];
        
        // Just do the emo scoring here while we're at it.
        // EMO scoring = emo goals / emo
        NSInteger homeEMO = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeEMO] integerValue];
        NSInteger visitorEMO = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeEMO] integerValue];
        
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
        NSNumber *homeManUp = [self.eventCounter eventCountForHomeTeam:INSOEventCodeManUp];
        NSNumber *visitorManUp = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeManUp];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>Man-up</td><td>%@</td>\n", homeManUp, visitorManUp];
        [emoSection appendString:@"</tr>\n"];
    }
    
    // Man-up scoring
    if ([self.game didRecordEvent:INSOEventCodeManUp] && [self.game didRecordEvent:INSOEventCodeGoal]) {
        NSInteger homeManUpGoals = [[self.eventCounter extraManGoalsForHomeTeam] integerValue];
        NSInteger visitorManUpGoals = [[self.eventCounter extraManGoalsForVisitingTeam] integerValue];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>Man-up Goals</td><td>%@</td>\n", @(homeManUpGoals), @(visitorManUpGoals)];
        [emoSection appendString:@"</tr>\n"];
        
        // Just do the emo scoring here while we're at it.
        // EMO scoring = emo goals / emo
        NSInteger homeManUp = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeManUp] integerValue];
        NSInteger visitorManUp = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeManUp] integerValue];
        
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
        NSNumber *homeManDown = [self.eventCounter eventCountForHomeTeam:INSOEventCodeManDown];
        NSNumber *visitorManDown = [self.eventCounter eventCountForVisitingTeam:INSOEventCodeManDown];
        
        [emoSection appendString:@"<tr>\n"];
        [emoSection appendFormat:@"<td>%@</td><td>Man-down</td><td>%@</td>\n", homeManDown, visitorManDown];
        [emoSection appendString:@"</tr>\n"];
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
        NSNumber *homePenalties = [self.eventCounter totalPenaltiesForHomeTeam];
        NSNumber *visitorPenalties = [self.eventCounter totalPenaltiesForVisitingTeam];
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Penalties</td><td>%@</td>\n", homePenalties, visitorPenalties];
        [penaltySection appendString:@"</tr>\n"];
        
        // Penalty Time
        NSInteger homePenaltySeconds = [[self.eventCounter totalPenaltyTimeForHomeTeam] integerValue];
        NSInteger visitorPenaltySeconds = [[self.eventCounter totalPenaltyTimeForVisitingTeam] integerValue];
        
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
        NSInteger homeFouls = [[self.eventCounter totalFoulsForHomeTeam] integerValue];
        NSInteger visitorFouls = [[self.eventCounter totalFoulsForVisitingTeam] integerValue];
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Fouls</td><td>%@</td>\n", @(homeFouls), @(visitorFouls)];
        [penaltySection appendString:@"</tr>\n"];
        
        // 8-meter awarded
        NSInteger home8m = [[self.eventCounter eventCountForHomeTeam:INSOEventCode8mFreePosition] integerValue];
        NSInteger visitor8m = [[self.eventCounter eventCountForVisitingTeam:INSOEventCode8mFreePosition] integerValue];
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>8m (Free Position)</td><td>%@</td>\n", @(home8m), @(visitor8m)];
        [penaltySection appendString:@"</tr>\n"];
        
        // 8-meter shots and goals
        NSNumber *homeFPS = [self.eventCounter freePositionEventCountForHomeTeam:INSOEventCodeShot];
        NSNumber *visitorFPS = [self.eventCounter freePositionEventCountForVisitingTeam:INSOEventCodeShot];
        
        NSNumber *homeFPSOG = [self.eventCounter freePositionEventCountForHomeTeam:INSOEventCodeShotOnGoal];
        NSNumber *visitorFPSOG = [self.eventCounter freePositionEventCountForVisitingTeam:INSOEventCodeShotOnGoal];
        
        NSNumber *homeFPGoal = [self.eventCounter freePositionEventCountForHomeTeam:INSOEventCodeGoal];
        NSNumber *visitorFPGoal = [self.eventCounter freePositionEventCountForVisitingTeam:INSOEventCodeGoal];
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@/%@/%@</td><td>8m (Free Position)<br />Shots/SOG/Goals</td><td>%@/%@/%@</td>\n", homeFPS, homeFPSOG, homeFPGoal, visitorFPS, visitorFPSOG,visitorFPGoal];
        [penaltySection appendString:@"</tr>\n"];
        
        // Green cards
        NSInteger homeGreenCards = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeGreenCard] integerValue];
        NSInteger visitorGreenCards = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeGreenCard] integerValue];
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Green Cards</td><td>%@</td>\n", @(homeGreenCards), @(visitorGreenCards)];
        [penaltySection appendString:@"</tr>\n"];
        
        // Yellow cards
        NSInteger homeYellowCards = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeYellowCard] integerValue];
        NSInteger visitorYellowCards = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeYellowCard] integerValue];
        
        [penaltySection appendString:@"<tr>\n"];
        [penaltySection appendFormat:@"<td>%@</td><td>Yellow Cards</td><td>%@</td>\n", @(homeYellowCards), @(visitorYellowCards)];
        [penaltySection appendString:@"</tr>\n"];
        
        // Red cards
        NSInteger homeRedCards = [[self.eventCounter eventCountForHomeTeam:INSOEventCodeRedCard] integerValue];
        NSInteger visitorRedCards = [[self.eventCounter eventCountForVisitingTeam:INSOEventCodeRedCard] integerValue];
        
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
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeGroundball forRosterPlayer:rosterPlayer]];
    }
    
    // Faceoff attempts
    NSNumber *faceoffsWon;
    NSNumber *faceoffsLost;
    NSNumber *faceoffAttempts;
    
    if ([self.game didRecordEvent:INSOEventCodeFaceoffWon] && [self.game didRecordEvent:INSOEventCodeFaceoffLost]) {
        faceoffsWon = [self.eventCounter eventCount:INSOEventCodeFaceoffWon forRosterPlayer:rosterPlayer];
        faceoffsLost = [self.eventCounter eventCount:INSOEventCodeFaceoffLost forRosterPlayer:rosterPlayer];
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
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeTurnover forRosterPlayer:rosterPlayer]];
    }
    
    // Caused turnover
    if ([self.game didRecordEvent:INSOEventCodeCausedTurnover]) {
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeCausedTurnover forRosterPlayer:rosterPlayer]];
    }
    
    // Interceptions
    if ([self.game didRecordEvent:INSOEventCodeInterception]) {
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeInterception forRosterPlayer:rosterPlayer]];
    }
    
    // Takeaways
    if ([self.game didRecordEvent:INSOEventCodeTakeaway]) {
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeTakeaway forRosterPlayer:rosterPlayer]];
    }
    
    // Unforced Errors
    if ([self.game didRecordEvent:INSOEventCodeUnforcedError]) {
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeUnforcedError forRosterPlayer:rosterPlayer]];
    }
    
    // Shots
    NSNumber *shots;
    if ([self.game didRecordEvent:INSOEventCodeShot]) {
        shots = [self.eventCounter eventCount:INSOEventCodeShot forRosterPlayer:rosterPlayer];
        [dataRow addObject:shots];
    }
    
    // Goals
    NSNumber *goals;
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        goals = [self.eventCounter eventCount:INSOEventCodeGoal forRosterPlayer:rosterPlayer];
        [dataRow addObject:goals];
    }
    
    // Assists
    NSNumber *assists;
    if ([self.game didRecordEvent:INSOEventCodeAssist]) {
        assists = [self.eventCounter eventCount:INSOEventCodeAssist forRosterPlayer:rosterPlayer];
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
        sog = [self.eventCounter eventCount:INSOEventCodeShotOnGoal forRosterPlayer:rosterPlayer];
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
        saves = [self.eventCounter eventCount:INSOEventCodeSave forRosterPlayer:rosterPlayer];
        [dataRow addObject:saves];
    }
    
    // Goals allowed
    NSNumber *goalsAllowed;
    if ([self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        goalsAllowed = [self.eventCounter eventCount:INSOEventCodeGoalAllowed forRosterPlayer:rosterPlayer];
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
        [dataRow addObject:[self.eventCounter totalPenaltiesForBoysRosterPlayer:rosterPlayer]];
        
        double totalPenaltyTime = [[self.eventCounter totalPenaltyTimeforRosterPlayer:rosterPlayer] doubleValue];
        
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
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeGroundball forRosterPlayer:rosterPlayer]];
    }
    
    // Draw stuff
    NSNumber *drawsTaken;
    NSNumber *drawPossession;
    
    // Draw taken
    if ([self.game didRecordEvent:INSOEventCodeDrawTaken]) {
        drawsTaken = [self.eventCounter eventCount:INSOEventCodeDrawTaken forRosterPlayer:rosterPlayer];
        [dataRow addObject:drawsTaken];
    }
    
    // Draw possession
    if ([self.game didRecordEvent:INSOEventCodeDrawPossession]) {
        drawPossession = [self.eventCounter eventCount:INSOEventCodeDrawPossession forRosterPlayer:rosterPlayer];
        [dataRow addObject:drawPossession];
    }
    
    // Draw control
    if ([self.game didRecordEvent:INSOEventCodeDrawControl]) {
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeDrawControl forRosterPlayer:rosterPlayer]];
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
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeCausedTurnover forRosterPlayer:rosterPlayer]];
    }
    
    // Interceptions
    if ([self.game didRecordEvent:INSOEventCodeInterception]) {
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeInterception forRosterPlayer:rosterPlayer]];
    }
    
    // Takeaways
    if ([self.game didRecordEvent:INSOEventCodeTakeaway]) {
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeTakeaway forRosterPlayer:rosterPlayer]];
    }
    
    // Unforced errors
    if ([self.game didRecordEvent:INSOEventCodeUnforcedError]) {
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeUnforcedError forRosterPlayer:rosterPlayer]];
    }
    
    // Shots
    NSNumber *shots;
    if ([self.game didRecordEvent:INSOEventCodeShot]) {
        shots = [self.eventCounter eventCount:INSOEventCodeShot forRosterPlayer:rosterPlayer];
        [dataRow addObject:shots];
    }
    
    // Goals
    NSNumber *goals;
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        goals = [self.eventCounter eventCount:INSOEventCodeGoal forRosterPlayer:rosterPlayer];
        [dataRow addObject:goals];
    }
    
    // Assists
    if ([self.game didRecordEvent:INSOEventCodeAssist]) {
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeAssist forRosterPlayer:rosterPlayer]];
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
        sog = [self.eventCounter eventCount:INSOEventCodeShotOnGoal forRosterPlayer:rosterPlayer];
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
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCode8mFreePosition forRosterPlayer:rosterPlayer]];
    }
    
    // Free position shot
    if ([self.game didRecordEvent:INSOEventCodeShot]) {
        NSNumber *freePositionShot = [self.eventCounter freePositionEventCount:INSOEventCodeShot forRosterPlayer:rosterPlayer];
        [dataRow addObject:freePositionShot];
    }
    
    // Free position goal
    if ([self.game didRecordEvent:INSOEventCodeGoal]) {
        NSNumber *freePositionGoal = [self.eventCounter freePositionEventCount:INSOEventCodeGoal forRosterPlayer:rosterPlayer];
        [dataRow addObject:freePositionGoal];
    }
    
    // Saves
    NSNumber *saves;
    if ([self.game didRecordEvent:INSOEventCodeSave]) {
        saves = [self.eventCounter eventCount:INSOEventCodeSave forRosterPlayer:rosterPlayer];
        [dataRow addObject:saves];
    }
    
    // Goals allowed
    NSNumber *goalsAllowed;
    if ([self.game didRecordEvent:INSOEventCodeGoalAllowed]) {
        goalsAllowed = [self.eventCounter eventCount:INSOEventCodeGoalAllowed forRosterPlayer:rosterPlayer];
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
        NSNumber *majorFouls = [self.eventCounter eventCount:INSOEventCodeMajorFoul forRosterPlayer:rosterPlayer];
        NSNumber *minorFouls = [self.eventCounter eventCount:INSOEventCodeMinorFoul forRosterPlayer:rosterPlayer];
        totalFouls = [majorFouls integerValue] + [minorFouls integerValue];
        [dataRow addObject:@(totalFouls)];
    }
    
    // Yellow cards
    if ([self.game didRecordEvent:INSOEventCodeYellowCard]) {
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeYellowCard forRosterPlayer:rosterPlayer]];
    }
    
    // Red cards
    if ([self.game didRecordEvent:INSOEventCodeRedCard]) {
        [dataRow addObject:[self.eventCounter eventCount:INSOEventCodeRedCard forRosterPlayer:rosterPlayer]];
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
        NSNumber* eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        [dataRow addObject:eventCount];
    }
    
    // now add faceoff attempts if we recorded faceoffs won.
    if ([self.maxPrepsBoysEvents containsObject:[Event eventForCode:INSOEventCodeFaceoffWon inManagedObjectContext:self.game.managedObjectContext]]) {
        // Only report faceoff attempts if we've actually collected faceoffs.
        NSInteger faceoffsWon = [[self.eventCounter eventCount:INSOEventCodeFaceoffWon forRosterPlayer:rosterPlayer] integerValue];
        NSInteger faceoffsLost = [[self.eventCounter eventCount:INSOEventCodeFaceoffLost forRosterPlayer:rosterPlayer] integerValue];
        NSNumber* faceoffAttempts = [NSNumber numberWithInteger:(faceoffsWon + faceoffsLost)];
        [dataRow addObject:faceoffAttempts];
    }
    
    // And now the penalties
    if (self.shouldExportPenalties) {
        [dataRow addObject:[self.eventCounter totalPenaltiesForBoysRosterPlayer:rosterPlayer]];
        
        NSInteger totalPenaltyTime = [[self.eventCounter totalPenaltyTimeforRosterPlayer:rosterPlayer] integerValue];
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
        NSNumber* eventCount = [self.eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        [dataRow addObject:eventCount];
    }
    
    // And now the penalties
    if (self.shouldExportPenalties) {
        [dataRow addObject:[self.eventCounter totalPenaltiesForGirlsRosterPlayer:rosterPlayer]];
    }
    
    return dataRow;
}

@end
