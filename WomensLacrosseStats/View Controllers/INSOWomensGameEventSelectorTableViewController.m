//
//  INSOWomensGameEventSelectorTableViewController.m
//
//  Created by James Dabrowski on 10/19/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOMensLacrosseStatsEnum.h"
#import "INSOMensLacrosseStatsConstants.h"

#import "WomensAppDelegate.h"

#import "INSOWomensGameEventSelectorTableViewController.h"
#import "INSOPenaltyTimeViewController.h"
#import "INSOShotResultViewController.h"
#import "INSOFaceoffWonViewController.h"
#import "INSODrawResultViewController.h"
#import "INSOMajorFoulResultViewController.h"

#import "RosterPlayer.h"
#import "GameEvent.h"
#import "Event.h"
#import "EventCategory.h"
#import "Game.h"

static NSString * const INSOGameEventCellIdentifier        = @"GameEventCell";
static NSString * const INSODoneAddingEventSegueIdentifier = @"DoneAddingEventSegue";
static NSString * const INSOSetPenaltyTimeSegueIdentifier  = @"SetPenaltyTimeSegue";
static NSString * const INSOShotResultSegueIdentifier      = @"ShotResultSegue";
static NSString * const INSODrawResultSegueIdentifier      = @"DrawResultSegue";
static NSString * const INSOMajorFoulResultSegueIdentifier = @"MajorFoulResultSegue"; 

@interface INSOWomensGameEventSelectorTableViewController ()

// IBOutlets
@property (nonatomic, weak) IBOutlet UIBarButtonItem * doneButton;

// IBActions
- (IBAction)done:(id)sender;

// Private Properties
@property (nonatomic) NSIndexPath * selectedIndexPath;
@property (nonatomic) NSManagedObjectContext * managedObjectContext;
@property (nonatomic) NSArray* eventArray;

- (BOOL) shouldShowShotResultView;
- (BOOL) shouldShowGoalResultView;

@end

@implementation INSOWomensGameEventSelectorTableViewController
#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set up the navigation bar
    if (self.rosterPlayer.isTeamValue) {
        self.navigationItem.title = NSLocalizedString(@"Action", nil);
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
    Event* event = self.eventArray[self.selectedIndexPath.section][self.selectedIndexPath.row];
    gameEvent.event = event;
    gameEvent.game = self.rosterPlayer.game;
    gameEvent.player = self.rosterPlayer;
    
    // If it's a shot on goal, we also need to create a shot event
    if (event.eventCodeValue == INSOEventCodeShotOnGoal) {
        [self createShotEvent];
    }
    
    // Save the MOC
    NSError* error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving the new game event: %@, %@", error, error.userInfo);
    }
    
    // Pop to top
    [self performSegueWithIdentifier:INSODoneAddingEventSegueIdentifier sender:event];
}


#pragma mark - Private Properties
- (NSManagedObjectContext*)managedObjectContext
{
    // Just want to use the game's moc and want an easier ref to it.
    if (!_managedObjectContext) {
        WomensAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    
    return _managedObjectContext;
}

- (NSArray*)eventArray
{
    if (!_eventArray) {
        _eventArray = [self buildEventArray];
    }
    return _eventArray;
}

#pragma mark - Private Methods
- (void)configureGameEventCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    //Event* event = (Event*)[self.fetchedResultsController objectAtIndexPath:indexPath];
    Event* event = self.eventArray[indexPath.section][indexPath.row];
    
    // Set the title
    cell.textLabel.text = event.title;
    
    // Set the accessory to none
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    // Re-set it depending on condition
    if (event.categoryCodeValue == INSOCategoryCodeGameAction) {
        // here it depends on the row and whether we're also recording other things
        if (event.eventCodeValue == INSOEventCodeShot) {
            if ([self shouldShowShotResultView]) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else {
                if ([indexPath isEqual:self.selectedIndexPath]) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
            }
        } else if (event.eventCodeValue == INSOEventCodeGoal) {
            if ([self shouldShowGoalResultView]) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else {
                if ([indexPath isEqual:self.selectedIndexPath]) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
            }
        } else if (event.eventCodeValue == INSOEventCodeDrawTaken) {
            if ([self shouldShowDrawResultView]) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else {
                if ([indexPath isEqual:self.selectedIndexPath]) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
            }
        }
    } else if (event.categoryCodeValue == INSOCategoryCodePersonalFouls) {
        // Depends on the foul
        if (event.eventCodeValue == INSOEventCode8mFreePositionShot || event.eventCodeValue == INSOEventCodeYellowCard) {
            // Major fouls, green and yellow cards all go somewhere else
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            if ([indexPath isEqual:self.selectedIndexPath]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
    } else if (event.categoryCodeValue == INSOCategoryCodeExpulsionFouls) {
        // Red cards go to penalty time selector as well
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}

- (NSArray*)buildEventArray
{
    NSMutableArray* events = [NSMutableArray new];
    
    // Now put all events into sub-arrays
    NSMutableArray* actionEvents        = [NSMutableArray new];
    NSMutableArray* personalFoulEvents  = [NSMutableArray new];
    NSMutableArray* technicalFoulEvents = [NSMutableArray new];
    NSMutableArray* expulsionFoulEvents = [NSMutableArray new];
    
    // I need to find a better way to do this.
    // This is brittle and will not last.
    for (Event* event in self.rosterPlayer.game.eventsToRecord) {
        if (event.categoryCodeValue == INSOCategoryCodeGameAction) {
            [actionEvents addObject:event];
        } else if (event.categoryCodeValue == INSOCategoryCodePersonalFouls) {
            [personalFoulEvents addObject:event];
        } else if (event.categoryCodeValue == INSOCategoryCodeTechnicalFouls) {
            [technicalFoulEvents addObject:event];
        } else if (event.categoryCodeValue == INSOCategoryCodeExpulsionFouls) {
            [expulsionFoulEvents addObject:event];
        }
    }
    
    // Now sort each sub-array
    [actionEvents sortUsingComparator:^NSComparisonResult(Event*  _Nonnull event1, Event*  _Nonnull event2) {
        return [event1.title compare:event2.title];
    }];
    
    [personalFoulEvents sortUsingComparator:^NSComparisonResult(Event*  _Nonnull event1, Event*  _Nonnull event2) {
        return [event1.title compare:event2.title];
    }];
    
    [technicalFoulEvents sortUsingComparator:^NSComparisonResult(Event*  _Nonnull event1, Event*  _Nonnull event2) {
        return [event1.title compare:event2.title];
    }];
    
    [expulsionFoulEvents sortUsingComparator:^NSComparisonResult(Event*  _Nonnull event1, Event*  _Nonnull event2) {
        return [event1.title compare:event2.title];
    }];
    
    // Now add sub-arrays to main array
    if ([actionEvents count] > 0) {
        [events addObject:actionEvents];
    }
    
    if ([personalFoulEvents count] > 0) {
        [events addObject:personalFoulEvents];
    }
    
    if ([technicalFoulEvents count] > 0) {
        [events addObject:technicalFoulEvents];
    }
    
    if ([expulsionFoulEvents count] > 0) {
        [events addObject:expulsionFoulEvents];
    }
    
    return events;
}

- (BOOL)shouldShowFaceoffWonResultView
{
    Event* groundballEvent = [Event eventForCode:INSOEventCodeGroundball inManagedObjectContext:self.managedObjectContext];
    return [self.rosterPlayer.game.eventsToRecord containsObject:groundballEvent];
}

- (BOOL)shouldShowDrawResultView
{
    Event* drawPossessionEvent = [Event eventForCode:INSOEventCodeDrawPossession inManagedObjectContext:self.managedObjectContext];
    return [self.rosterPlayer.game.eventsToRecord containsObject:drawPossessionEvent];
}

- (BOOL)shouldShowGoalResultView
{
    // Show the goal result if they are recording either EMOs or assists.
    Event* extraManEvent = [Event eventForCode:INSOEventCodeEMO inManagedObjectContext:self.managedObjectContext];
    Event* assistEvent = [Event eventForCode:INSOEventCodeAssist inManagedObjectContext:self.managedObjectContext];
    
    return ([self.rosterPlayer.game.eventsToRecord containsObject:extraManEvent] || [self.rosterPlayer.game.eventsToRecord containsObject:assistEvent]);
}

- (BOOL)shouldShowShotResultView
{
    // Show the shot result view if the are doing any of the following:
    // save, goals, or assists
    Event* saveEvent = [Event eventForCode:INSOEventCodeSave inManagedObjectContext:self.managedObjectContext];
    Event* extraManEvent = [Event eventForCode:INSOEventCodeEMO inManagedObjectContext:self.managedObjectContext];
    Event* assistEvent = [Event eventForCode:INSOEventCodeAssist inManagedObjectContext:self.managedObjectContext];
    
    return ([self.rosterPlayer.game.eventsToRecord containsObject:extraManEvent] ||
            [self.rosterPlayer.game.eventsToRecord containsObject:assistEvent]   ||
            [self.rosterPlayer.game.eventsToRecord containsObject:saveEvent]);
}

- (void)createShotEvent
{
    // Create the appropriate game event
    GameEvent* gameEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    
    // Set its properties
    gameEvent.timestamp = [NSDate date];
    
    // Set its relations
    gameEvent.event = [Event eventForCode:INSOEventCodeShot inManagedObjectContext:self.managedObjectContext];
    gameEvent.game = self.rosterPlayer.game;
    gameEvent.player = self.rosterPlayer;
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:INSOSetPenaltyTimeSegueIdentifier]) {
        [self prepareForSetPenaltyTimeSegue:segue sender:sender];
    }
    
    if ([segue.identifier isEqualToString:INSOShotResultSegueIdentifier]) {
        [self prepareForShotResultSegue:segue sender:sender];
    }
    
    if ([segue.identifier isEqualToString:INSODrawResultSegueIdentifier]) {
        [self prepareForDrawResultSegue:segue sender:sender]; 
    }
}

- (void)prepareForSetPenaltyTimeSegue:(UIStoryboardSegue*)segue sender:(NSIndexPath*)indexPath
{
    // Need to send along roster player and the event code
    INSOPenaltyTimeViewController* dest = segue.destinationViewController;
    dest.rosterPlayer = self.rosterPlayer;
    dest.event = self.eventArray[indexPath.section][indexPath.row];
}

- (void)prepareForShotResultSegue:(UIStoryboardSegue*)segue sender:(NSIndexPath*)indexPath
{
    INSOShotResultViewController* dest = segue.destinationViewController;
    dest.rosterPlayer = self.rosterPlayer;
    
    Event* selectedEvent = self.eventArray[indexPath.section][indexPath.row];
    if (selectedEvent.eventCodeValue == INSOEventCodeGoal) {
        dest.initialResultSegment = INSOGoalResultGoal;
    } else {
        dest.initialResultSegment = INSOGoalResultNone;
    }
    
    dest.is8mShot = (selectedEvent.eventCodeValue == INSOEventCode8mFreePositionShot);
}

- (void)prepareForFaceoffWonSegue:(UIStoryboardSegue*)segue sender:(NSIndexPath*)indexPath
{
    INSOFaceoffWonViewController* dest = segue.destinationViewController;
    dest.faceoffWinner = self.rosterPlayer; 
}

- (void)prepareForDrawResultSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath *)indexPath
{
    INSODrawResultViewController *dest = segue.destinationViewController;
    dest.center = self.rosterPlayer;
}

#pragma mark - Delegation
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.eventArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.eventArray[section] count];
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
    Event* event = [self.eventArray[section] firstObject];
    return event.category.title;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set up old and new selection
    UITableViewCell* oldSelectedCell = [tableView cellForRowAtIndexPath:self.selectedIndexPath];
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
        
        Event* selectedEvent = self.eventArray[indexPath.section][indexPath.row];
        
        // Fouls are complicated
        if (selectedEvent.categoryCodeValue == INSOCategoryCodePersonalFouls) {
            if (selectedEvent.eventCodeValue == INSOEventCode8mFreePositionShot) {
                self.selectedIndexPath = nil;
                oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
                self.doneButton.enabled = NO;
                
                [self performSegueWithIdentifier:INSOShotResultSegueIdentifier sender:indexPath];
            } else if (selectedEvent.eventCodeValue == INSOEventCodeYellowCard) {
                self.selectedIndexPath = nil;
                oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
                self.doneButton.enabled = NO;
                
                [self performSegueWithIdentifier:INSOSetPenaltyTimeSegueIdentifier sender:indexPath];
            } else {
                // Set the checkmarks
                oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
                newSelectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                // Enable the done button
                self.doneButton.enabled = YES;
            }
        } else if (selectedEvent.categoryCodeValue == INSOCategoryCodeExpulsionFouls) {
            // Go to penalty time selector
            [self performSegueWithIdentifier:INSOSetPenaltyTimeSegueIdentifier sender:indexPath];
            
            // Clean up the event selector in case we come back to it.
            self.selectedIndexPath = nil;
            oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
            self.doneButton.enabled = NO;
        } else {
            // Shots or goals go to shot result selector
            if (selectedEvent.eventCodeValue == INSOEventCodeShot && [self shouldShowShotResultView]) {
                self.selectedIndexPath = nil;
                oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
                self.doneButton.enabled = NO;

                [self performSegueWithIdentifier:INSOShotResultSegueIdentifier sender:indexPath];
            } else if (selectedEvent.eventCodeValue == INSOEventCodeGoal && [self shouldShowGoalResultView]) {
                self.selectedIndexPath = nil;
                oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
                self.doneButton.enabled = NO;

                [self performSegueWithIdentifier:INSOShotResultSegueIdentifier sender:indexPath];
            } else if (selectedEvent.eventCodeValue == INSOEventCodeDrawTaken && [self shouldShowDrawResultView]) {
                // Need to go to draw result view
                self.selectedIndexPath = nil;
                oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
                self.doneButton.enabled = NO;

                [self performSegueWithIdentifier:INSODrawResultSegueIdentifier sender:indexPath];
            } else {
                // Set the checkmarks
                oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
                newSelectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                // Enable the done button
                self.doneButton.enabled = YES;
            }
        }
    }
    
    // Finally, unselect the cell
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
