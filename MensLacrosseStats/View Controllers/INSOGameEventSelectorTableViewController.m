//
//  INSOGameEventSelectorTableViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/19/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "MensLacrosseStatsAppDelegate.h"

#import "INSOGameEventSelectorTableViewController.h"
//#import "INSOPenaltyTimeViewController.h"
//#import "INSOShotResultViewController.h"

#import "RosterPlayer.h"
#import "GameEvent.h"
#import "Event.h"
#import "EventCategory.h"
#import "Game.h"

static NSString * const INSOGameEventCellIdentifier = @"GameEventCell";

typedef NS_ENUM(NSUInteger, INSOEventSelectorSectionIndex) {
    INSOEventSelectorSectionIndexGameActions,
    INSOEventSelectorSectionIndexPersonalFouls,
    INSOEventSelectorSectionIndexTechnicalFouls,
    INSOEventSelectorSectionIndexExpulsionFouls
};

@interface INSOGameEventSelectorTableViewController ()

// IBOutlets
@property (nonatomic, weak) IBOutlet UIBarButtonItem * doneButton;

// IBActions
- (IBAction)done:(id)sender;

// Private Properties
@property (nonatomic) NSIndexPath * selectedIndexPath;
@property (nonatomic) NSManagedObjectContext * managedObjectContext;
@property (nonatomic) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic) NSArray* eventArray;

// Private Methods
- (void)configureGameEventCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;

// Navigation
- (void)prepareForSetPenaltyTimeSegue:(UIStoryboardSegue*)segue sender:(NSIndexPath*)indexPath;
- (void)prepareForShotResultSegue:(UIStoryboardSegue*)segue sender:(NSIndexPath*)indexPath;

// Delegation

@end

@implementation INSOGameEventSelectorTableViewController
#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set up the navigation bar
    if (self.rosterPlayer.isTeamValue) {
        self.navigationItem.title = @"Action";
    } else {
        self.navigationItem.title = [NSString stringWithFormat:@"%@", self.rosterPlayer.number];
    }
    self.doneButton.enabled = NO;
    
}


#pragma mark - IBActions
- (void)done:(id)sender
{
    // Create the appropriate game event
    GameEvent* gameEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    
    // Set its properties
    gameEvent.timestamp = [NSDate date];
    
    // Set its relations
    gameEvent.event = [self.fetchedResultsController objectAtIndexPath:self.selectedIndexPath];
    gameEvent.game = self.rosterPlayer.game;
    gameEvent.player = self.rosterPlayer;
    
    /*
    // If it's an expulsion foul
    if ([gameEvent isExpulsionEvent]) {
        // Set penalty duration
        gameEvent.penaltyDurationValue = 3600;
        
        // Expel the player
        gameEvent.rosterPlayer.playingStatusValue = INSOPlayingStatusExpelled;
    }
     */

    /*
    // If it's a faceoff
    if (gameEvent.event.codeValue == EventCodeFaceoffWon) {
        // Create a faceoff lost event for the other team
        // Create a new gameEvent
        GameEvent* faceoffLostEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
        
        // Set its properties
        faceoffLostEvent.periodValue = gameEvent.periodValue;
        faceoffLostEvent.timeRemainingValue = gameEvent.timeRemainingValue;
        faceoffLostEvent.timestamp = [NSDate date];
        
        // Set its relations
        faceoffLostEvent.event = [Event eventForCode:EventCodeFaceoffLost  inManagedObjectContext:self.managedObjectContext];
        faceoffLostEvent.game = gameEvent.game;
        
        // Somehow need to set the opposing roster player
        Team* team = gameEvent.rosterPlayer.roster.team;
        if ([gameEvent.game.homeTeam isEqual:team]) {
            Roster* roster = [Roster rosterForTeam:gameEvent.game.visitingTeam inGame:gameEvent.game inManagedObjectContext:gameEvent.managedObjectContext];
            faceoffLostEvent.rosterPlayer = roster.teamPlayer;
        } else {
            Roster* roster = [Roster rosterForTeam:gameEvent.game.homeTeam inGame:gameEvent.game inManagedObjectContext:gameEvent.managedObjectContext];
            faceoffLostEvent.rosterPlayer = roster.teamPlayer;
        }
        
        // Make sure the two are linked
        faceoffLostEvent.parentEvent = gameEvent;
        
    } else if (gameEvent.event.codeValue == EventCodeFaceoffLost) {
        // Create a faceoff won event for the other team
        // Create a new gameEvent
        GameEvent* faceoffWonEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
        
        // Set its properties
        faceoffWonEvent.periodValue = gameEvent.periodValue;
        faceoffWonEvent.timeRemainingValue = gameEvent.timeRemainingValue;
        faceoffWonEvent.timestamp = [NSDate date];
        
        // Set its relations
        faceoffWonEvent.event = [Event eventForCode:EventCodeFaceoffWon inManagedObjectContext:self.managedObjectContext];
        faceoffWonEvent.game = gameEvent.game;
        
        // Somehow need to set the opposing roster player
        Team* team = gameEvent.rosterPlayer.roster.team;
        if ([gameEvent.game.homeTeam isEqual:team]) {
            Roster* roster = [Roster rosterForTeam:gameEvent.game.visitingTeam inGame:gameEvent.game inManagedObjectContext:gameEvent.managedObjectContext];
            faceoffWonEvent.rosterPlayer = roster.teamPlayer;
        } else {
            Roster* roster = [Roster rosterForTeam:gameEvent.game.homeTeam inGame:gameEvent.game inManagedObjectContext:gameEvent.managedObjectContext];
            faceoffWonEvent.rosterPlayer = roster.teamPlayer;
        }
        
        // Make sure the two are linked
        faceoffWonEvent.parentEvent = gameEvent;
    }
     */
    
    /*
    // If its a caused turnover, need to credit other team with a turnover
    if (gameEvent.event.codeValue == EventCodeCausedTurnover) {
        // Create a new gameEvent
        GameEvent* turnoverEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
        
        // Set its properties
        turnoverEvent.periodValue = gameEvent.periodValue;
        turnoverEvent.timeRemainingValue = gameEvent.timeRemainingValue;
        turnoverEvent.timestamp = [NSDate date];
        
        // Set its relations
        turnoverEvent.event = [Event eventForCode:EventCodeTurnover inManagedObjectContext:self.managedObjectContext];
        turnoverEvent.game = gameEvent.game;
        
        // Somehow need to set the opposing roster player
        Team* team = gameEvent.rosterPlayer.roster.team;
        if ([gameEvent.game.homeTeam isEqual:team]) {
            Roster* roster = [Roster rosterForTeam:gameEvent.game.visitingTeam inGame:gameEvent.game inManagedObjectContext:gameEvent.managedObjectContext];
            turnoverEvent.rosterPlayer = roster.teamPlayer;
        } else {
            Roster* roster = [Roster rosterForTeam:gameEvent.game.homeTeam inGame:gameEvent.game inManagedObjectContext:gameEvent.managedObjectContext];
            turnoverEvent.rosterPlayer = roster.teamPlayer;
        }
        
        // Make sure the two are linked
        turnoverEvent.parentEvent = gameEvent;
    }
     */
    
    // Save the MOC
    NSError* error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving the new game event: %@, %@", error, error.userInfo);
    }
    
    // Pop to top
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - Private Properties
- (NSManagedObjectContext*)managedObjectContext
{
    // Just want to use the game's moc and want an easier ref to it.
    if (!_managedObjectContext) {
        MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    
    return _managedObjectContext;
}

- (NSArray*)eventArray
{
    if (!_eventArray) {
        _eventArray = [self.rosterPlayer.game.eventsToRecord allObjects];
    }
    return _eventArray;
}

- (NSFetchedResultsController*)fetchedResultsController
{
    if (!_fetchedResultsController) {
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[Event entityName]];
        
        [fetchRequest setFetchBatchSize:50];
        
        NSSortDescriptor* sortByCategory = [NSSortDescriptor sortDescriptorWithKey:@"categorySortOrder" ascending:YES];
        NSSortDescriptor* sortByTitle = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        [fetchRequest setSortDescriptors:@[sortByCategory, sortByTitle]];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"category.Title" cacheName:nil];
        
        NSError *error = nil;
        if (![_fetchedResultsController performFetch:&error]) {
            NSLog(@"Error fetching up games %@, %@", error, [error userInfo]);
        }
    }
    
    return _fetchedResultsController;
}



#pragma mark - Private Methods
- (void)configureGameEventCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    //Event* event = (Event*)[self.fetchedResultsController objectAtIndexPath:indexPath];
    Event* event = self.eventArray[indexPath.row]; 
    
    // Set the title
    cell.textLabel.text = event.title;
    
    // Set the accessory to none
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    /*
    // Re-set it depending on condition
    if (indexPath.section == INSOEventSelectorSectionIndexGameActions) {
        // here it depends on the row
        EventCode code = event.codeValue;
        if (code == EventCodeShot || code == EventCodeGoal) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if ([indexPath isEqual:self.selectedIndexPath]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else if (indexPath.section == INSOEventSelectorSectionIndexExpulsionFouls) {
        // Expulsion fouls don't go anywhere
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (indexPath.section == INSOEventSelectorSectionIndexPersonalFouls || indexPath.section == INSOEventSelectorSectionIndexTechnicalFouls) {
        // All other fouls and we gotta seque
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
     */
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SetPenaltyTimeSegue"]) {
        [self prepareForSetPenaltyTimeSegue:segue sender:sender];
    }
    
    if ([segue.identifier isEqualToString:@"ShotResultSegue"]) {
        [self prepareForShotResultSegue:segue sender:sender];
    }
}

- (void)prepareForSetPenaltyTimeSegue:(UIStoryboardSegue*)segue sender:(NSIndexPath*)indexPath
{
    /*
    // Need to send along roster player and the event code
    INSOPenaltyTimeViewController* dest = segue.destinationViewController;
    dest.rosterPlayer = self.rosterPlayer;
    dest.event = (Event*)[self.fetchedResultsController objectAtIndexPath:indexPath];
    dest.period = self.period;
    dest.timeRemaining = self.timeRemaining;
     */
}

- (void)prepareForShotResultSegue:(UIStoryboardSegue*)segue sender:(NSIndexPath*)indexPath
{
    /*
    INSOShotResultViewController* dest = segue.destinationViewController;
    dest.rosterPlayer = self.rosterPlayer;
    dest.period = self.period;
    dest.timeRemaining = self.timeRemaining;
    
    Event* selectedEvent = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (selectedEvent.codeValue == EventCodeGoal) {
        dest.initialResultSegment = INSOGoalResultGoal;
    } else {
        dest.initialResultSegment = INSOGoalResultNone;
    }
     */
}

#pragma mark - Delegation
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    //return [self.fetchedResultsController.sections count];
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
    return [self.eventArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:INSOGameEventCellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    [self configureGameEventCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
//    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
//    return [sectionInfo name];
    Event* event = [self.eventArray firstObject];
    return event.category.title;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set up old and new selection
    //UITableViewCell* oldSelectedCell = [tableView cellForRowAtIndexPath:self.selectedIndexPath];
    UITableViewCell* newSelectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if ([self.selectedIndexPath isEqual:indexPath]) {
        // Selecting same cell as last time
        if (newSelectedCell.accessoryType == UITableViewCellAccessoryNone) {
            // Re-selecting old selection
            newSelectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.doneButton.enabled = YES;
        } else {
            // De-selecting old selection
            newSelectedCell.accessoryType = UITableViewCellAccessoryNone;
            self.doneButton.enabled = NO;
        }
    } else {
        // Selecting new cell
        self.selectedIndexPath = indexPath;
        
        /*
        // if its a foul event, just push the time view controller
        if (indexPath.section == INSOEventSelectorSectionIndexPersonalFouls || indexPath.section == INSOEventSelectorSectionIndexTechnicalFouls) {
            
            [self performSegueWithIdentifier:@"SetPenaltyTimeSegue" sender:indexPath];
            
            // Clean up the event selector in case we come back to it.
            self.selectedIndexPath = nil;
            oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
            self.doneButton.enabled = NO;
        } else {
            // Set the selected index
            Event* event = (Event*)[self.fetchedResultsController objectAtIndexPath:indexPath];
            EventCode eventCode = event.codeValue;
            
            // Shots or goals go to shot result selector
            if (eventCode == EventCodeShot || eventCode == EventCodeGoal) {
                [self performSegueWithIdentifier:@"ShotResultSegue" sender:indexPath];
                
                // Clean up the event selector in case we come back to it.
                self.selectedIndexPath = nil;
                oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
                self.doneButton.enabled = NO;
            } else {
                // Set the checkmarks
                oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
                newSelectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                // Enable the done button
                self.navigationItem.rightBarButtonItem.enabled = YES;
            }
        }
         */
    }
    
    // Finally, unselect the cell
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
