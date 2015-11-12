//
//  INSOShotResultViewController.m
//  Scorebook
//
//  Created by Jim Dabrowski on 3/26/15.
//  Copyright (c) 2015 IntangibleSoftware. All rights reserved.
//

#import "UIColor+INSOScorebookColor.h"

#import "MensLacrosseStatsAppDelegate.h"

#import "INSOMensLacrosseStatsConstants.h"

#import "INSOShotResultViewController.h"
#import "INSOPlayerCollectionViewCell.h"

#import "RosterPlayer.h"
#import "Event.h"
#import "GameEvent.h"
#import "Game.h"

static NSString * const PlayerCellIdentifier = @"PlayerCell";
static NSString * const INSODoneAddingEventSegueIdentifier = @"DoneAddingEventSegue";

static const CGFloat INSODefaultPlayerCellSize = 50.0;

@interface INSOShotResultViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

// IBOutlets
@property (nonatomic, weak) IBOutlet UIBarButtonItem    * doneButton;
@property (nonatomic, weak) IBOutlet UISegmentedControl * shotResultSegment;
@property (nonatomic, weak) IBOutlet UISwitch           * extraManSwitch;
@property (nonatomic, weak) IBOutlet UICollectionView   * assistCollection;
@property (nonatomic, weak) IBOutlet UILabel            * assistTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel            * extraManLabel; 

// IBActions
- (IBAction)done:(id)sender;
- (IBAction)didChangeResult:(id)sender;

// Private Properties
@property (nonatomic) NSArray* rosterArray;
@property (nonatomic) NSIndexPath* selectedIndexPath;
@property (nonatomic) NSManagedObjectContext* managedObjectContext;
@property (nonatomic) NSSet* eventsToRecord;

// Private Methods
- (BOOL)shouldEnableDoneButton;
- (void)configureRosterPlayerCell:(INSOPlayerCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

- (GameEvent*)createShotEvent;
- (GameEvent*)createGoalEvent;
- (GameEvent*)createShotOnGoalEvent;
- (GameEvent*)createAssistEvent;

@end

@implementation INSOShotResultViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.shotResultSegment.selectedSegmentIndex = self.initialResultSegment;

    // I want to make sure all are hidden to start
    self.extraManLabel.alpha = 0.0;
    self.extraManSwitch.alpha = 0.0;
    self.assistTitleLabel.alpha = 0.0;
    self.assistCollection.alpha = 0.0;

    [self configureView];
    
    self.doneButton.enabled = [self shouldEnableDoneButton];
}


#pragma mark - IBActions
- (void)done:(id)sender
{
    // Create the necessary events
    if (self.shotResultSegment.selectedSegmentIndex == INSOGoalResultMiss) {
        [self createShotEvent];
    } else if (self.shotResultSegment.selectedSegmentIndex == INSOGoalResultSave) {
        [self createShotEvent];
        [self createShotOnGoalEvent];
        
    } else if (self.shotResultSegment.selectedSegmentIndex == INSOGoalResultGoal) {
        [self createShotEvent];
        [self createShotOnGoalEvent];
        [self createGoalEvent];
        
        // Now need to see if there is an assist
        if (self.selectedIndexPath) {
            // We have an assist
            [self createAssistEvent];
        }
    }
    
    // Now save all this
    NSError* error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving the shot, goal, assist events: %@, %@", error, error.userInfo);
    }
    
    [self performSegueWithIdentifier:INSODoneAddingEventSegueIdentifier sender:nil];
}

- (void)didChangeResult:(id)sender
{
    self.doneButton.enabled = [self shouldEnableDoneButton];
    
    // Show or hide the assist roster as needed
    self.rosterArray = nil;
    [self.assistCollection reloadData];
    [self configureView];
}

#pragma mark - Private Properties
- (NSArray*)rosterArray
{
    if (!_rosterArray) {
        // Get all the players from the roster
        NSSortDescriptor* sortByNumber = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
        NSMutableArray* roster = [[NSMutableArray alloc] initWithArray:[self.rosterPlayer.game.players sortedArrayUsingDescriptors:@[sortByNumber]]];
        
        // Remove the player who shot, but not if it's the team player
        if (!self.rosterPlayer.isTeamValue) {
            [roster removeObjectIdenticalTo:self.rosterPlayer];
        }
        
        _rosterArray = roster;
    }
    return _rosterArray;
}

- (NSManagedObjectContext*)managedObjectContext
{
    // Just want to use the game's moc and want an easier ref to it.
    if (!_managedObjectContext) {
        MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    
    return _managedObjectContext;
}

- (NSSet*)eventsToRecord
{
    if (!_eventsToRecord) {
        _eventsToRecord = self.rosterPlayer.game.eventsToRecord;
    }
    return _eventsToRecord;
}

#pragma mark - Private Methods
- (void)configureView
{
    // Disable those segments we can't go to
    [self.shotResultSegment setEnabled:[self canRecordMiss] forSegmentAtIndex:INSOGoalResultMiss];
    [self.shotResultSegment setEnabled:[self canRecordSave] forSegmentAtIndex:INSOGoalResultSave];
    [self.shotResultSegment setEnabled:[self canRecordGoal] forSegmentAtIndex:INSOGoalResultGoal];
    
    // Show or hide rest of view depending on circumstances
    [UIView animateWithDuration:0.25 animations:^{
        self.shotResultSegment.alpha = 1.0;
        self.extraManLabel.alpha = [self extraManAlpha];
        self.extraManSwitch.alpha = [self extraManAlpha];
        self.assistTitleLabel.alpha = [self assistAlpha];
        self.assistCollection.alpha = [self assistAlpha];
    }];
}

- (CGFloat)assistAlpha
{
    CGFloat alpha = 0.0;
    if ([self canRecordAssist]) {
        alpha = 1.0;
    }
    return alpha;
}

- (CGFloat)extraManAlpha
{
    CGFloat alpha = 0.0;
    if ([self canRecordEMO]) {
        alpha = 1.0;
    }
    return alpha;
}

- (BOOL)canRecordMiss
{
    BOOL canRecord = YES;
    if (self.initialResultSegment == INSOGoalResultGoal) {
        canRecord = NO;
    }
    return canRecord;
}

- (BOOL)canRecordSave
{
    BOOL canRecord = YES;
    if (self.initialResultSegment == INSOGoalResultGoal) {
        canRecord = NO;
    }
    if (![self gameEventsContainsEvent:INSOEventCodeSave]) {
        canRecord = NO;
    }
    return canRecord;
}

- (BOOL)canRecordGoal
{
    return [self gameEventsContainsEvent:INSOEventCodeGoal];
}

- (BOOL)canRecordEMO
{
    BOOL canRecord = YES;
    
    // If the result isn't a goal, we can't record an EMO goal now can we.
    if (self.shotResultSegment.selectedSegmentIndex != INSOGoalResultGoal) {
        canRecord = NO;
    }
    
    // Nor can we record it if they aren't recording EMOs.
    if (![self gameEventsContainsEvent:INSOEventCodeEMO]) {
        canRecord = NO;
    }
    
    return canRecord;
}

- (BOOL)canRecordAssist
{
    BOOL canRecord = YES;
    
    // If the result isn't a goal, we can't record an assist now can we.
    if (self.shotResultSegment.selectedSegmentIndex != INSOGoalResultGoal) {
        canRecord = NO;
    }
    
    // Nor can we record it if we aren't recording assists
    if (![self gameEventsContainsEvent:INSOEventCodeAssist]) {
        canRecord = NO;
    }
    
    return canRecord;
}

- (BOOL)shouldEnableDoneButton
{
    // Enable if any button is selected
    return self.shotResultSegment.selectedSegmentIndex != INSOGoalResultNone;
}

- (void)configureRosterPlayerCell:(INSOPlayerCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    RosterPlayer * rosterPlayer = self.rosterArray[indexPath.row];
    if (rosterPlayer.isTeamValue) {
        cell.playerNumberLabel.text = NSLocalizedString(@"Team Player", nil);
    } else {
        cell.playerNumberLabel.text = [NSString stringWithFormat:@"%@", rosterPlayer.number];
    }
    
    if ([indexPath isEqual:self.selectedIndexPath]) {
        [self.assistCollection selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        cell.selected = YES;
    } else {
        [self.assistCollection deselectItemAtIndexPath:indexPath animated:YES];
        cell.selected = NO;
    }
}

- (GameEvent*)createShotEvent
{
    // Just bail right away if we aren't recording shots.
    if (![self gameEventsContainsEvent:INSOEventCodeShot]) {
        return nil;
    }
    
    // Create the shot game event
    GameEvent* shotEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    
    // Set its properties
    shotEvent.timestamp = [NSDate date];
    
    // Set its relations
    shotEvent.event = [Event eventForCode:INSOEventCodeShot inManagedObjectContext:self.managedObjectContext];
    shotEvent.game = self.rosterPlayer.game;
    shotEvent.player = self.rosterPlayer;
    
    return shotEvent;
}

- (GameEvent*)createGoalEvent
{
    // Just bail right away if we aren't recording goals.
    if (![self gameEventsContainsEvent:INSOEventCodeGoal]) {
        return nil;
    }
    
    // Create the goal game event
    GameEvent* goalEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    
    // Set its properties
    goalEvent.timestamp = [NSDate date];
    
    // Set its relations
    goalEvent.event = [Event eventForCode:INSOEventCodeGoal inManagedObjectContext:self.managedObjectContext];
    goalEvent.game = self.rosterPlayer.game;
    goalEvent.player = self.rosterPlayer;
    goalEvent.isExtraManGoalValue = self.extraManSwitch.isOn;
    
    return goalEvent;
}

- (GameEvent*)createShotOnGoalEvent
{
    // Just bail right away if we aren't recording shots on goal.
    if (![self gameEventsContainsEvent:INSOEventCodeShotOnGoal]) {
        return nil;
    }

    GameEvent* shotOnGoalEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    
    shotOnGoalEvent.timestamp = [NSDate date];
    shotOnGoalEvent.event = [Event eventForCode:INSOEventCodeShotOnGoal inManagedObjectContext:self.managedObjectContext];
    shotOnGoalEvent.game = self.rosterPlayer.game;
    shotOnGoalEvent.player = self.rosterPlayer;
    
    return shotOnGoalEvent;
}

- (GameEvent*)createAssistEvent
{
    // Just bail right away if we aren't recording assists.
    if (![self gameEventsContainsEvent:INSOEventCodeAssist]) {
        return nil;
    }

    GameEvent* assistEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    
    assistEvent.timestamp = [NSDate date];
    assistEvent.event = [Event eventForCode:INSOEventCodeAssist inManagedObjectContext:self.managedObjectContext];
    assistEvent.game = self.rosterPlayer.game;
    
    if (self.selectedIndexPath) {
        RosterPlayer* assistingPlayer = self.rosterArray[self.selectedIndexPath.row];
        assistEvent.player = assistingPlayer;
    }
    
    return assistEvent;
}

- (BOOL)gameEventsContainsEvent:(INSOEventCode)eventCode
{
    NSSet* gameEvents = self.rosterPlayer.game.eventsToRecord;
    NSSet* matchingEvents = [gameEvents objectsPassingTest:^BOOL(Event*  _Nonnull event, BOOL * _Nonnull stop) {
        return event.eventCodeValue == eventCode;
    }];
    return [matchingEvents count] > 0;
}

#pragma mark - Delegates
#pragma mark UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.rosterArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell
    INSOPlayerCollectionViewCell *cell = (INSOPlayerCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:PlayerCellIdentifier forIndexPath:indexPath];
    [self configureRosterPlayerCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Hold on to the selected indexpath
    if ([indexPath isEqual:self.selectedIndexPath]) {
        self.selectedIndexPath = nil;
    } else {
        self.selectedIndexPath = indexPath;
    }
    
    // Reload the collectionview
    [collectionView reloadData];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = INSODefaultPlayerCellSize;
    CGFloat width = INSODefaultPlayerCellSize;
    
    RosterPlayer* player = self.rosterArray[indexPath.row];
    if (player.isTeamValue) {
        UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)collectionView.collectionViewLayout;
        width = collectionView.frame.size.width - layout.sectionInset.left - layout.sectionInset.right;
    }
    
    return CGSizeMake(width, height);
}

@end
