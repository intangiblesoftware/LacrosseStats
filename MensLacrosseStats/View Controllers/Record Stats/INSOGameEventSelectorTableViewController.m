//
//  INSOGameEventSelectorTableViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/19/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOMensLacrosseStatsEnum.h"
#import "INSOMensLacrosseStatsConstants.h"

#import "MensLacrosseStatsAppDelegate.h"

#import "INSOGameEventSelectorTableViewController.h"
#import "INSOPenaltyTimeViewController.h"
#import "INSOShotResultViewController.h"
#import "INSOFaceoffWonViewController.h"
#import "INSODrawResultViewController.h"

#import "RosterPlayer.h"
#import "GameEvent.h"
#import "Event.h"
#import "EventCategory.h"
#import "Game.h"

static NSString * const INSOGameEventCellIdentifier        = @"GameEventCell";
static NSString * const INSODoneAddingEventSegueIdentifier = @"DoneAddingEventSegue";
static NSString * const INSOSetPenaltyTimeSegueIdentifier  = @"SetPenaltyTimeSegue";
static NSString * const INSOShotResultSegueIdentifier      = @"ShotResultSegue";
static NSString * const INSOFaceoffWonSegueIdentifier      = @"FaceoffWonSegue";
static NSString * const INSODrawResultSegueIdentifier      = @"DrawResultSegue";

@interface INSOGameEventSelectorTableViewController ()

// IBOutlets
@property (nonatomic, weak) IBOutlet UIBarButtonItem * doneButton;

// IBActions
- (IBAction)done:(id)sender;

// Private Properties
@property (nonatomic) NSIndexPath * selectedIndexPath;
@property (nonatomic) NSManagedObjectContext * managedObjectContext;
@property (nonatomic) NSArray* eventArray;

- (BOOL) shouldShowFaceoffWonResultView;
- (BOOL) shouldShowShotResultView;
- (BOOL) shouldShowGoalResultView;

@end

@implementation INSOGameEventSelectorTableViewController
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
    
    // If it's an expulsion foul
    if (event.categoryCodeValue == INSOCategoryCodeExpulsionFouls) {
        // Set penalty time
        gameEvent.penaltyTimeValue = INSOExplusionPenaltyTime;
    }
    
    // If it's a shot on goal, we also need to create a shot event
    if (event.eventCodeValue == INSOEventCodeShotOnGoal) {
        if ([self shouldCreateEvent:INSOEventCodeShot]) {
            [self createEvent:INSOEventCodeShot forPlayer:self.rosterPlayer];
        }
    }
    
    // If it's a lost faceoff, need to give the other guys a win
    if (event.eventCodeValue == INSOEventCodeFaceoffLost) {
        if ([self shouldCreateEvent:INSOEventCodeFaceoffWon]) {
            RosterPlayer *player;
            if (self.rosterPlayer.numberValue == INSOOtherTeamPlayerNumber) {
                // Save by other guys. Faceoff won for watching.
                player = [self.rosterPlayer.game playerWithNumber:@(INSOTeamWatchingPlayerNumber)];
            } else {
                // Save by watching. Faceoff won for other guys.
                player = [self.rosterPlayer.game playerWithNumber:@(INSOOtherTeamPlayerNumber)];
            }
            [self createEvent:INSOEventCodeFaceoffWon forPlayer:player];
        }
    }
    
    // Goal allowed - shot, shot on goal and goal for the other team
    if (event.eventCodeValue == INSOEventCodeGoalAllowed) {
        RosterPlayer *player;
        if (self.rosterPlayer.numberValue == INSOOtherTeamPlayerNumber) {
            // Goal allowed by other guys. Goal for watching.
            player = [self.rosterPlayer.game playerWithNumber:@(INSOTeamWatchingPlayerNumber)];
        } else {
            // Goal allowed by watching. Goal for other guys.
            player = [self.rosterPlayer.game playerWithNumber:@(INSOOtherTeamPlayerNumber)];
        }
        if ([self shouldCreateEvent:INSOEventCodeShot]) {
            [self createEvent:INSOEventCodeShot forPlayer:player];
        }
        if ([self shouldCreateEvent:INSOEventCodeShotOnGoal]) {
            [self createEvent:INSOEventCodeShotOnGoal forPlayer:player];
        }
        if ([self shouldCreateEvent:INSOEventCodeGoal]) {
            [self createEvent:INSOEventCodeGoal forPlayer:player];
        }
    }
    
    // If it's a save event, need to create shot and shot on goal for the other guys
    if (event.eventCodeValue == INSOEventCodeSave) {
        if ([self shouldCreateEvent:INSOEventCodeShot]) {
            RosterPlayer *player;
            if (self.rosterPlayer.numberValue == INSOOtherTeamPlayerNumber) {
                // Save by other guys. Shot and sog for watching.
                player = [self.rosterPlayer.game playerWithNumber:@(INSOTeamWatchingPlayerNumber)];
            } else {
                // Save by watching. Shot and SOG for other guys.
                player = [self.rosterPlayer.game playerWithNumber:@(INSOOtherTeamPlayerNumber)];
            }
            [self createEvent:INSOEventCodeShot forPlayer:player];
        }
        
        if ([self shouldCreateEvent:INSOEventCodeShotOnGoal]) {
            RosterPlayer *player;
            if (self.rosterPlayer.numberValue == INSOOtherTeamPlayerNumber) {
                // Save by other guys. Shot and sog for watching.
                player = [self.rosterPlayer.game playerWithNumber:@(INSOTeamWatchingPlayerNumber)];
            } else {
                // Save by watching. Shot and SOG for other guys.
                player = [self.rosterPlayer.game playerWithNumber:@(INSOOtherTeamPlayerNumber)];
            }
            [self createEvent:INSOEventCodeShotOnGoal forPlayer:player];
        }
    }
    
    // If it's a failed clear, also record a turnover
    if (event.eventCodeValue == INSOEventCodeClearFailed) {
        if ([self shouldCreateEvent:INSOEventCodeTurnover]) {
            RosterPlayer *player;
            if (self.rosterPlayer.numberValue == INSOOtherTeamPlayerNumber) {
                player = [self.rosterPlayer.game playerWithNumber:@(INSOOtherTeamPlayerNumber)];
            } else {
                player = [self.rosterPlayer.game playerWithNumber:@(INSOTeamWatchingPlayerNumber)];
            }
            [self createEvent:INSOEventCodeTurnover forPlayer:player];
        }
    }
    
    // If it's a caused turnover, give the other guys a turnover
    if (event.eventCodeValue == INSOEventCodeCausedTurnover) {
        if ([self shouldCreateEvent:INSOEventCodeTurnover]) {
            RosterPlayer *player;
            if (self.rosterPlayer.numberValue == INSOOtherTeamPlayerNumber) {
                player = [self.rosterPlayer.game playerWithNumber:@(INSOTeamWatchingPlayerNumber)];
            } else {
                player = [self.rosterPlayer.game playerWithNumber:@(INSOOtherTeamPlayerNumber)];
            }
            [self createEvent:INSOEventCodeTurnover forPlayer:player];
        }
    }
    
    // Interception - record turnover for other team.
    if (event.eventCodeValue == INSOEventCodeInterception) {
        if ([self shouldCreateEvent:INSOEventCodeTurnover]) {
            RosterPlayer *player;
            if (self.rosterPlayer.numberValue == INSOOtherTeamPlayerNumber) {
                player = [self.rosterPlayer.game playerWithNumber:@(INSOTeamWatchingPlayerNumber)];
            } else {
                player = [self.rosterPlayer.game playerWithNumber:@(INSOOtherTeamPlayerNumber)];
            }
            [self createEvent:INSOEventCodeTurnover forPlayer:player];
        }
    }
    
    // Take away - record turnover for other team.
    if (event.eventCodeValue == INSOEventCodeTakeaway) {
        if ([self shouldCreateEvent:INSOEventCodeTurnover]) {
            RosterPlayer *player;
            if (self.rosterPlayer.numberValue == INSOOtherTeamPlayerNumber) {
                player = [self.rosterPlayer.game playerWithNumber:@(INSOTeamWatchingPlayerNumber)];
            } else {
                player = [self.rosterPlayer.game playerWithNumber:@(INSOOtherTeamPlayerNumber)];
            }
            [self createEvent:INSOEventCodeTurnover forPlayer:player];
        }
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
        MensLacrosseStatsAppDelegate* appDelegate = (MensLacrosseStatsAppDelegate *)[[UIApplication sharedApplication] delegate];
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
        } else if (event.eventCodeValue == INSOEventCodeFaceoffWon) {
            if ([self shouldShowFaceoffWonResultView]) {
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
    } else if (event.categoryCodeValue == INSOCategoryCodeExpulsionFouls) {
        // Expulsion fouls don't go anywhere
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (event.categoryCodeValue == INSOCategoryCodePersonalFouls || event.categoryCodeValue == INSOCategoryCodeTechnicalFouls) {
        // All other fouls and we gotta seque
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

- (BOOL)shouldCreateEvent:(INSOEventCode)eventCode
{
    Event *event = [Event eventForCode:eventCode inManagedObjectContext:self.managedObjectContext];
    return [self.rosterPlayer.game.eventsToRecord containsObject:event];
}

- (void)createEvent:(INSOEventCode)eventCode forPlayer:(RosterPlayer *)player
{
    GameEvent *gameEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    gameEvent.timestamp = [NSDate date];
    gameEvent.event = [Event eventForCode:eventCode inManagedObjectContext:self.managedObjectContext];
    gameEvent.game = player.game;
    gameEvent.player = player;
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
    
    if ([segue.identifier isEqualToString:INSOFaceoffWonSegueIdentifier]) {
        [self prepareForFaceoffWonSegue:segue sender:sender];
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
        
        // if its a foul event, just push the time view controller
        if (selectedEvent.categoryCodeValue == INSOCategoryCodePersonalFouls || selectedEvent.categoryCodeValue == INSOCategoryCodeTechnicalFouls) {
            
            [self performSegueWithIdentifier:INSOSetPenaltyTimeSegueIdentifier sender:indexPath];
            
            // Clean up the event selector in case we come back to it.
            self.selectedIndexPath = nil;
            oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
            self.doneButton.enabled = NO;
        } else {
            // Shots or goals go to shot result selector
            if (selectedEvent.eventCodeValue == INSOEventCodeShot && [self shouldShowShotResultView]) {
                self.selectedIndexPath = nil;
                [self performSegueWithIdentifier:INSOShotResultSegueIdentifier sender:indexPath];
            } else if (selectedEvent.eventCodeValue == INSOEventCodeGoal && [self shouldShowGoalResultView]) {
                self.selectedIndexPath = nil;
                [self performSegueWithIdentifier:INSOShotResultSegueIdentifier sender:indexPath];
            } else if (selectedEvent.eventCodeValue == INSOEventCodeFaceoffWon && [self shouldShowFaceoffWonResultView]) {
                // Need to go to ground-ball event selector
                self.selectedIndexPath = nil; 
                [self performSegueWithIdentifier:INSOFaceoffWonSegueIdentifier sender:indexPath];
            } else if (selectedEvent.eventCodeValue == INSOEventCodeDrawTaken && [self shouldShowDrawResultView]) {
                // Need to go to draw result view
                self.selectedIndexPath = nil;
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
