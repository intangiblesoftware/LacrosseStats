//
//  INSOEmailStatsFileGenerator.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 11/27/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOEmailStatsFileGenerator.h"
#import "INSOGameEventCounter.h"
#import "INSOMensLacrosseStatsConstants.h"
#import "INSOMensLacrosseStatsEnum.h"

#import "Game.h"
#import "Event.h"
#import "EventCategory.h"
#import "RosterPlayer.h"

@interface INSOEmailStatsFileGenerator ()

@property (nonatomic) BOOL shouldExportPenalties;

@property (nonatomic) NSArray* headerArray;
@property (nonatomic) NSArray* statsArray;

@property (nonatomic) NSArray* allEvents;
@property (nonatomic) NSArray* recordedEvents;
@property (nonatomic) NSArray* maxPrepsEvents;
@property (nonatomic) NSArray* playersArray;

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
        // Need to be able to sort by eventTitle a couple of times
        NSSortDescriptor* sortByTitle = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];

        // First create the array of event codes for events recorded in the game
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"categoryCode == %@", @(INSOCategoryCodeGameAction)];
        NSSet* recordedStats = [_game.eventsToRecord filteredSetUsingPredicate:predicate];
        _recordedEvents = [recordedStats sortedArrayUsingDescriptors:@[sortByTitle]];
        
        // Now create the array of event codes for all events
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[Event entityName]];
        fetchRequest.sortDescriptors = @[sortByTitle];
        fetchRequest.predicate = predicate;
        NSError* error = nil;
        _allEvents = [_game.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if (error) {
            NSLog(@"Error fetching all game events: %@", error.localizedDescription);
        }
        
        // And now player numbers
        NSSortDescriptor* sortByNumber = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
        _playersArray = [_game.players sortedArrayUsingDescriptors:@[sortByNumber]];
        
        // Now figure out if we should export penalties
        NSPredicate* penaltyPredicate = [NSPredicate predicateWithFormat:@"categoryCode != %@", @(INSOCategoryCodeGameAction)];
        NSSet* penaltyEvents = [_game.eventsToRecord filteredSetUsingPredicate:penaltyPredicate];
        _shouldExportPenalties = [penaltyEvents count] > 0;
    }
    
    return self;
}

#pragma mark - Public interface
- (void)createGameStatsDataFileForAllStats:(completion)completion
{
    NSMutableArray* gameStatsArray = [NSMutableArray new];
    
    // Do a header row
    NSArray* headerRow = [self headerRowForAllStats];
    [gameStatsArray addObject:[headerRow componentsJoinedByString:@","]];
    
    // Now a row for every player
    for (RosterPlayer* rosterPlayer in self.playersArray) {
        NSArray* dataRow = [self dataRowForAllStatsForPlayer:rosterPlayer];
        [gameStatsArray addObject:[dataRow componentsJoinedByString:@","]];
    }
    
    // Now convert entire array to a string
    NSString* gameStatsString = [gameStatsArray componentsJoinedByString:@"\n"];
    
    // Now call the completion block
    NSData* statData = [gameStatsString dataUsingEncoding:NSUTF8StringEncoding];
    completion(statData);
}

- (void)createGameStatsDataFileForRecordedStats:(completion)completion
{
    NSMutableArray* gameStatsArray = [NSMutableArray new];
    
    // Do a header row
    NSArray* headerRow = [self headerRowForCollectedStats];
    [gameStatsArray addObject:[headerRow componentsJoinedByString:@","]];
    
    // Now a row for every player
    for (RosterPlayer* rosterPlayer in self.playersArray) {
        NSArray* dataRow = [self dataRowForCollectedStatsForPlayer:rosterPlayer];
        [gameStatsArray addObject:[dataRow componentsJoinedByString:@","]];
    }
    
    // Now convert entire array to a string
    NSString* gameStatsString = [gameStatsArray componentsJoinedByString:@"\n"];
    
    // Now call the completion block
    NSData* statData = [gameStatsString dataUsingEncoding:NSUTF8StringEncoding];
    completion(statData);
}

- (void)createMaxPrepsGameStatsFile:(completion)completion
{
    NSMutableArray* gameStatsArray = [NSMutableArray new];
    
    // First line is company ID
    [gameStatsArray addObject:INSOMaxPrepsCompanyID];
    
    // Then comes the header (maxPreps style!)
    NSArray* headerRow = [self maxPrepsHeaderRow];
    [gameStatsArray addObject:[headerRow componentsJoinedByString:@"|"]];
    
    // Now data rows for each person in the game (but not the team player!)
    for (RosterPlayer* rosterPlayer in self.playersArray) {
        if (!rosterPlayer.isTeamValue) {
            NSArray* dataRow = [self maxPrepsDataRowForPlayer:rosterPlayer];
            [gameStatsArray addObject:[dataRow componentsJoinedByString:@"|"]];
        }
    }

    // Now convert entire array to string
    NSString* maxPrepsStatsString = [gameStatsArray componentsJoinedByString:@"\n"];
    
    // Now call the completion block
    NSData* maxPrepsData = [maxPrepsStatsString dataUsingEncoding:NSUTF8StringEncoding];
    completion(maxPrepsData);
}

#pragma mark - Private Properties
- (NSArray*)maxPrepsEvents
{
    if (!_maxPrepsEvents) {
        NSMutableSet* maxPrepsEventSet = [NSMutableSet new];
        
        Event* event;
        
        // goals
        event = [Event eventForCode:INSOEventCodeGoal inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsEventSet addObject:event];
        
        // assists
        event = [Event eventForCode:INSOEventCodeAssist inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsEventSet addObject:event];
        
        // shots on goal
        event = [Event eventForCode:INSOEventCodeShotOnGoal inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsEventSet addObject:event];
        
        // groundballs
        event = [Event eventForCode:INSOEventCodeGroundball inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsEventSet addObject:event];

        // interceptions
        event = [Event eventForCode:INSOEventCodeInterception inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsEventSet addObject:event];
        
        // faceoffs won
        event = [Event eventForCode:INSOEventCodeFaceoffWon inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsEventSet addObject:event];
        
        // goals against
        event = [Event eventForCode:INSOEventCodeGoalAllowed inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsEventSet addObject:event];
        
        // saves
        event = [Event eventForCode:INSOEventCodeSave inManagedObjectContext:self.game.managedObjectContext];
        [maxPrepsEventSet addObject:event];
        
        // Now get the intersection
        [maxPrepsEventSet intersectSet:self.game.eventsToRecord];
        
        _maxPrepsEvents = [maxPrepsEventSet allObjects];
    }
    
    return _maxPrepsEvents;
}

#pragma mark - Private methods
- (NSArray*)headerRowForAllStats
{
    NSMutableArray* header = [NSMutableArray new];
    
    // First the player number
    [header addObject:@"Number"];
    
    // Now the event titles
    for (Event* event in self.allEvents) {
        [header addObject:event.title];
    }
    
    // Now the penalty titles
    if (self.shouldExportPenalties) {
        [header addObject:@"Penalties"];
        [header addObject:@"Penalty time"];
    }
    
    return header;
}

- (NSArray*)headerRowForCollectedStats
{
    NSMutableArray* header = [NSMutableArray new];

    // First the player number
    [header addObject:@"Number"];

    // Now the event titles
    for (Event* event in self.recordedEvents) {
        [header addObject:event.title];
    }
    
    // Now the penalty titles
    if (self.shouldExportPenalties) {
        [header addObject:@"Penalties"];
        [header addObject:@"Penalty time"];
    }
    
    return header;
}

- (NSArray*)dataRowForAllStatsForPlayer:(RosterPlayer*)rosterPlayer
{
    NSMutableArray* dataRow = [NSMutableArray new];
    
    // First goes the player
    if (rosterPlayer.isTeamValue) {
        [dataRow addObject:@"Team"];
    } else {
        [dataRow addObject:rosterPlayer.number];
    }
    
    // Now we need an event counter
    INSOGameEventCounter* eventCounter = [[INSOGameEventCounter alloc] initWithGame:self.game];
    
    // Now a count of every event for that number
    for (Event* event in self.allEvents) {
        NSNumber* eventCount = [eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        [dataRow addObject:eventCount];
    }
    
    // And now the penalties
    if (self.shouldExportPenalties) {
        [dataRow addObject:[eventCounter totalPenaltiesForRosterPlayer:rosterPlayer]];
        
        double totalPenaltyTime = [[eventCounter totalPenaltyTimeforRosterPlayer:rosterPlayer] doubleValue];
        
        NSDateComponentsFormatter* penaltyTimeFormatter = [[NSDateComponentsFormatter alloc] init];
        penaltyTimeFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropLeading;
        penaltyTimeFormatter.allowedUnits = (NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
        
        [dataRow addObject:[penaltyTimeFormatter stringFromTimeInterval:totalPenaltyTime]];
    }
    
    return dataRow;
}

- (NSArray*)dataRowForCollectedStatsForPlayer:(RosterPlayer*)rosterPlayer
{
    NSMutableArray* dataRow = [NSMutableArray new];
    
    // First goes the player
    if (rosterPlayer.isTeamValue) {
        [dataRow addObject:@"Team"];
    } else {
        [dataRow addObject:rosterPlayer.number];
    }
    
    // Now we need an event counter
    INSOGameEventCounter* eventCounter = [[INSOGameEventCounter alloc] initWithGame:self.game];
    
    // Now a count of every event for that number
    for (Event* event in self.recordedEvents) {
        NSNumber* eventCount = [eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        [dataRow addObject:eventCount];
    }
    
    // And now the penalties
    if (self.shouldExportPenalties) {
        [dataRow addObject:[eventCounter totalPenaltiesForRosterPlayer:rosterPlayer]];
        
        double totalPenaltyTime = [[eventCounter totalPenaltyTimeforRosterPlayer:rosterPlayer] doubleValue];
        
        NSDateComponentsFormatter* penaltyTimeFormatter = [[NSDateComponentsFormatter alloc] init];
        penaltyTimeFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropLeading;
        penaltyTimeFormatter.allowedUnits = (NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
        
        [dataRow addObject:[penaltyTimeFormatter stringFromTimeInterval:totalPenaltyTime]];
    }
        
    return dataRow;
}

- (NSArray*)maxPrepsHeaderRow
{
    NSMutableArray* header = [NSMutableArray new];
    
    // First the player number
    [header addObject:@"Jersey"];
    
    // Now the event titles for the events we've collected
    for (Event* event in self.maxPrepsEvents) {
        [header addObject:event.maxPrepsTitle];
    }
    
    // Now faceoffs.
    if ([self.maxPrepsEvents containsObject:[Event eventForCode:INSOEventCodeFaceoffWon inManagedObjectContext:self.game.managedObjectContext]]) {
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

- (NSArray*)maxPrepsDataRowForPlayer:(RosterPlayer*)rosterPlayer
{
    NSMutableArray* dataRow = [NSMutableArray new];
    
    // First goes the player
    [dataRow addObject:rosterPlayer.number];
    
    // Now we need an event counter
    INSOGameEventCounter* eventCounter = [[INSOGameEventCounter alloc] initWithGame:self.game];
    
    // Now a count of every event for that number
    for (Event* event in self.maxPrepsEvents) {
        NSNumber* eventCount = [eventCounter eventCount:event.eventCodeValue forRosterPlayer:rosterPlayer];
        [dataRow addObject:eventCount];
    }
    
    // now add faceoff attempts if we recorded faceoffs won.
    if ([self.maxPrepsEvents containsObject:[Event eventForCode:INSOEventCodeFaceoffWon inManagedObjectContext:self.game.managedObjectContext]]) {
        // Only report faceoff attempts if we've actually collected faceoffs.
        NSInteger faceoffsWon = [[eventCounter eventCount:INSOEventCodeFaceoffWon forRosterPlayer:rosterPlayer] integerValue];
        NSInteger faceoffsLost = [[eventCounter eventCount:INSOEventCodeFaceoffLost forRosterPlayer:rosterPlayer] integerValue];
        NSNumber* faceoffAttempts = [NSNumber numberWithInteger:(faceoffsWon + faceoffsLost)];
        [dataRow addObject:faceoffAttempts];
    }
    
    // And now the penalties
    if (self.shouldExportPenalties) {
        [dataRow addObject:[eventCounter totalPenaltiesForRosterPlayer:rosterPlayer]];
        
        NSInteger totalPenaltyTime = [[eventCounter totalPenaltyTimeforRosterPlayer:rosterPlayer] integerValue];
        NSInteger penaltyMinutes = totalPenaltyTime / 60;
        NSInteger penaltySeconds = totalPenaltyTime % 60;
        
        [dataRow addObject:[NSNumber numberWithInteger:penaltyMinutes]];
        [dataRow addObject:[NSNumber numberWithInteger:penaltySeconds]];
    }
    
    return dataRow;
}

@end
