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

static const CGFloat INSODefaultPlayerCellSize = 50.0;

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
@property (nonatomic) CGFloat cellWidth;

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
    
    self.cellWidth = INSODefaultPlayerCellSize;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self layoutAssistCollection]; 
}

#pragma mark - IBActions
- (void)done:(id)sender
{
    // Create the necessary events
    [self createFaceoffWonEvent];
    
    if (self.selectedIndexPath) {
        [self createGroundballEvent];
    }
    
    [self createFaceoffLostEvent];
    
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
        if (self.faceoffWinner.numberValue == INSOOtherTeamPlayerNumber) {
            // The other team won the face off, so only show the other team player
            _rosterArray = @[[self.faceoffWinner.game playerWithNumber:@(INSOOtherTeamPlayerNumber)]];
        } else {
            NSSortDescriptor* sortByNumber = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
            NSMutableArray* roster = [[NSMutableArray alloc] initWithArray:[self.faceoffWinner.game.players sortedArrayUsingDescriptors:@[sortByNumber]]];
            RosterPlayer *otherTeamPlayer = [self.faceoffWinner.game playerWithNumber:@(INSOOtherTeamPlayerNumber)];
            [roster removeObject:otherTeamPlayer];
            _rosterArray = roster;
        }        
    }
    return _rosterArray;
}

- (NSManagedObjectContext*)managedObjectContext
{
    // Just want to use the game's moc and want an easier ref to it.
    if (!_managedObjectContext) {
        MensLacrosseStatsAppDelegate* appDelegate = (MensLacrosseStatsAppDelegate *)[[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    
    return _managedObjectContext;
}

#pragma mark - Private Methods
- (void)configureRosterPlayerCell:(INSOPlayerCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    RosterPlayer * rosterPlayer = self.rosterArray[indexPath.row];
    if (rosterPlayer.isTeamValue) {
        // Which team player?
        if (rosterPlayer.numberValue == INSOTeamWatchingPlayerNumber) {
            cell.playerNumberLabel.text = rosterPlayer.game.teamWatching;
        } else {
            if ([rosterPlayer.game.teamWatching isEqualToString:rosterPlayer.game.homeTeam]) {
                cell.playerNumberLabel.text = rosterPlayer.game.visitingTeam;
            } else {
                cell.playerNumberLabel.text = rosterPlayer.game.homeTeam;
            }
        }
    } else {
        cell.playerNumberLabel.text = [NSString stringWithFormat:@"%@", rosterPlayer.number];
    }
    
    if ([indexPath isEqual:self.selectedIndexPath]) {
        [self.playerCollection selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        cell.selected = YES;
    } else {
        [self.playerCollection deselectItemAtIndexPath:indexPath animated:YES];
        cell.selected = NO;
    }
}

- (void)layoutAssistCollection
{
    CGFloat initialCellWidth = INSODefaultPlayerCellSize;
    CGFloat interItemSpacing = 0.0;
    CGFloat collectionViewWidth = 0.0;
    NSInteger cellsPerRow = 0;
    CGFloat remainingSpace = 0.0;
    
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.playerCollection.collectionViewLayout;
    
    collectionViewWidth = self.playerCollection.frame.size.width - layout.sectionInset.left - layout.sectionInset.right - 1;
    
    cellsPerRow = (int)collectionViewWidth / (int)initialCellWidth;
    remainingSpace = collectionViewWidth - (cellsPerRow * initialCellWidth);
    
    if (cellsPerRow > 1) {
        interItemSpacing = remainingSpace / (cellsPerRow - 1);
    }
    
    self.cellWidth = initialCellWidth;
    layout.minimumInteritemSpacing = interItemSpacing;
    layout.minimumLineSpacing = interItemSpacing;
    
    self.playerCollection.collectionViewLayout = layout;
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

- (GameEvent *)createFaceoffLostEvent
{
    GameEvent *faceoffLostEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    
    faceoffLostEvent.timestamp = [NSDate date];
    faceoffLostEvent.event = [Event eventForCode:INSOEventCodeFaceoffLost inManagedObjectContext:self.managedObjectContext];
    faceoffLostEvent.game = self.faceoffWinner.game;
    
    RosterPlayer *player;
    if (self.faceoffWinner.numberValue == INSOOtherTeamPlayerNumber) {
        // Faceoff loss for team watching
        player = [self.faceoffWinner.game playerWithNumber:@(INSOTeamWatchingPlayerNumber)];
    } else {
        // Faceoff loss for other team
        player = [self.faceoffWinner.game playerWithNumber:@(INSOOtherTeamPlayerNumber)];
    }
    faceoffLostEvent.player = player;
    
    return faceoffLostEvent;
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
    CGFloat height = self.cellWidth;
    CGFloat width = self.cellWidth;
    
    RosterPlayer* player = self.rosterArray[indexPath.row];
    if (player.isTeamValue) {
        UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)collectionView.collectionViewLayout;
        width = collectionView.frame.size.width - layout.sectionInset.left - layout.sectionInset.right;
    }
    
    return CGSizeMake(width, height);
}

@end
