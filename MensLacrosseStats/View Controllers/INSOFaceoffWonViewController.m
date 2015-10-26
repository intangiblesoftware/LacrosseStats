//
//  INSOFaceoffWonViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/25/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "MensLacrosseStatsAppDelegate.h"

#import "INSOFaceoffWonViewController.h"
#import "INSOPlayerCollectionViewCell.h"

#import "RosterPlayer.h"
#import "Game.h"
#import "GameEvent.h"
#import "Event.h"

static NSString * const PlayerCellIdentifier = @"PlayerCell";
static NSString * const INSODoneAddingEventSegueIdentifier = @"DoneAddingEventSegue";

@interface INSOFaceoffWonViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
// IBOutlets
@property (nonatomic, weak) IBOutlet UILabel* instructionLabel;
@property (nonatomic, weak) IBOutlet UICollectionView* playerCollection;

// IBActions
- (IBAction)done:(id)sender;

// Private Properties
@property (nonatomic) NSArray* rosterArray;
@property (nonatomic) NSIndexPath* selectedIndexPath;
@property (nonatomic) NSManagedObjectContext* managedObjectContext;

// Private Methods
- (void)configureRosterPlayerCell:(INSOPlayerCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation INSOFaceoffWonViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString* instructionString;
    if (self.faceoffWinner && !self.faceoffWinner.isTeamValue) {
        instructionString = [NSString stringWithFormat:@"%@ won the faceoff. Select the player that won the groundball (if any).", self.faceoffWinner.number];
    } else {
        instructionString = [NSString stringWithFormat:@"Select the player that won the groundball (if any)."];
    }
    self.instructionLabel.text = instructionString;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions
- (void)done:(id)sender
{
    // Create the necessary events
    [self createFaceoffWonEvent];
    
    if (self.selectedIndexPath) {
        [self createGroundballEvent];
    }
    
    // Now save all this
    NSError* error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving the faceoff won and groundball events: %@, %@", error, error.userInfo);
    }
    
    [self performSegueWithIdentifier:INSODoneAddingEventSegueIdentifier sender:nil];
}

#pragma mark - Private Properties
- (NSArray*)rosterArray
{
    if (!_rosterArray) {
        // Get all the players from the roster
        NSSortDescriptor* sortByNumber = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
        NSMutableArray* roster = [[NSMutableArray alloc] initWithArray:[self.faceoffWinner.game.players sortedArrayUsingDescriptors:@[sortByNumber]]];
        
        // Remove the current player and the team player
        [roster removeObjectIdenticalTo:self.faceoffWinner.game.teamPlayer];
        
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

#pragma mark - Private Methods
- (void)configureRosterPlayerCell:(INSOPlayerCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    RosterPlayer * rosterPlayer = self.rosterArray[indexPath.row];
    cell.playerNumberLabel.text = [NSString stringWithFormat:@"%@", rosterPlayer.number];
    
    if ([indexPath isEqual:self.selectedIndexPath]) {
        [self.playerCollection selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        cell.selected = YES;
    } else {
        [self.playerCollection deselectItemAtIndexPath:indexPath animated:YES];
        cell.selected = NO;
    }
}

- (GameEvent*)createFaceoffWonEvent
{
    GameEvent* faceoffWonEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    
    faceoffWonEvent.timestamp = [NSDate date];
    faceoffWonEvent.event = [Event eventForCode:INSOEventCodeFaceoffWon inManagedObjectContext:self.managedObjectContext];
    faceoffWonEvent.game = self.faceoffWinner.game;
    faceoffWonEvent.player = self.faceoffWinner;
    
    return faceoffWonEvent;
}

- (GameEvent*)createGroundballEvent
{
    GameEvent* groundballEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    
    groundballEvent.timestamp = [NSDate date];
    groundballEvent.event = [Event eventForCode:INSOEventCodeGroundball inManagedObjectContext:self.managedObjectContext];
    groundballEvent.game = self.faceoffWinner.game;
    
    if (self.selectedIndexPath) {
        RosterPlayer* groundballWinner = self.rosterArray[self.selectedIndexPath.row];
        groundballEvent.player = groundballWinner;
    }
    
    return groundballEvent;
}

#pragma mark - Delegates
#pragma mark UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.rosterArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    INSOPlayerCollectionViewCell *cell = (INSOPlayerCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:PlayerCellIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    [self configureRosterPlayerCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>
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


@end
