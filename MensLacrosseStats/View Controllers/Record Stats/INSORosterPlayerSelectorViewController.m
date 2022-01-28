//
//  INSORosterPlayerSelectorViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/18/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//


#import "MensLacrosseStatsAppDelegate.h"

#import "INSORosterPlayerSelectorViewController.h"
#import "INSOPlayerCollectionViewCell.h"
#import "INSOGameEventSelectorTableViewController.h"
#import "INSOEventListEditorViewController.h"

#import "Game.h"
#import "GameEvent.h"
#import "Event.h"
#import "RosterPlayer.h"

// Constants
static NSString * const INSORosterPlayerCellReuseIdentifier = @"RosterPlayerCell";
static NSString * const INSOTeamPlayerCellReuseIdentifier   = @"TeamPlayerCell";

static NSString * const INSOShowEventListEditorSegueIdentifier = @"ShowEventListEditorSegue";
static NSString * const INSOShowEventSelectorSegueIdentifier = @"ShowEventSelectorSegue"; 

static const CGFloat INSODefaultPlayerCellSize = 50.0;

@interface INSORosterPlayerSelectorViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate>
// IBOutlets
@property (nonatomic, weak) IBOutlet UICollectionView* playersCollectionView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* playerCollectionHeightConstraint;

// IBAction
- (IBAction)doneAddingEvent:(UIStoryboardSegue*)sender;

// Private properties
@property (nonatomic) NSArray* rosterArray;
@property (nonatomic) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic) NSManagedObjectContext* managedObjectContext;
@property (nonatomic) CGFloat cellWidth;

// Private methods

@end

@implementation INSORosterPlayerSelectorViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cellWidth = INSODefaultPlayerCellSize;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    // We no longer transition to orientation, we transition to size. So use this instead.
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Once we transition to size,
    // invalidate the content size and invalidate the layout.
    // This will redraw the cells of the proper size.
    [self.playersCollectionView invalidateIntrinsicContentSize];
    [self.playersCollectionView.collectionViewLayout invalidateLayout];
}

- (void)viewDidLayoutSubviews
{
    [self layoutPlayerCollection];
    
    [self resizePlayerCollection];
}

#pragma mark - IBActions
- (void)doneAddingEvent:(UIStoryboardSegue *)sender
{
    [self.navigationController popToViewController:self animated:YES]; 
}

#pragma mark - Private Properties
- (NSArray*)rosterArray
{
    if (!_rosterArray) {
        NSMutableArray* temp = [NSMutableArray new];
        [temp addObjectsFromArray:[self.game.players allObjects]];
        [temp sortUsingComparator:^NSComparisonResult(RosterPlayer*  _Nonnull rosterPlayer1, RosterPlayer*  _Nonnull rosterPlayer2) {
            return [rosterPlayer1.number compare:rosterPlayer2.number];
        }];
        _rosterArray = temp;
    }
    return _rosterArray;
}

- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        MensLacrosseStatsAppDelegate* appDelegate = (MensLacrosseStatsAppDelegate *)[[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    
    return _managedObjectContext;
}

- (NSFetchedResultsController*)fetchedResultsController
{
    if (!_fetchedResultsController) {
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:[GameEvent entityName]];
        [request setFetchBatchSize:50];
        
        NSSortDescriptor* sortByTimestamp = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
        [request setSortDescriptors:@[sortByTimestamp]];
        
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@", self.game];
        [request setPredicate:predicate];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request  managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsController.delegate = self;
        
        NSError* error = nil;
        if (![_fetchedResultsController performFetch:&error]) {
            // Error fetching games
            NSLog(@"Error fetching game events: %@", error.localizedDescription);
        }
    }
    return _fetchedResultsController;
}

#pragma mark - Private Methods
- (void)configureRosterPlayerCell:(INSOPlayerCollectionViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    RosterPlayer* rosterPlayer = self.rosterArray[indexPath.row];
    if (rosterPlayer.isTeamValue) {
        // Which team player?
        if (rosterPlayer.numberValue == INSOTeamWatchingPlayerNumber) {
            cell.playerNumberLabel.text = self.game.teamWatching;
        } else {
            if ([self.game.teamWatching isEqualToString:self.game.homeTeam]) {
                cell.playerNumberLabel.text = self.game.visitingTeam;
            } else {
                cell.playerNumberLabel.text = self.game.homeTeam; 
            }
        }
    } else {
        cell.playerNumberLabel.text = [NSString stringWithFormat:@"%@", rosterPlayer.number];
    }
}

- (void)layoutPlayerCollection
{
    CGFloat initialCellWidth = INSODefaultPlayerCellSize;
    CGFloat interItemSpacing = 0.0;
    CGFloat collectionViewWidth = 0.0;
    NSInteger cellsPerRow = 0;
    CGFloat remainingSpace = 0.0;
    
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.playersCollectionView.collectionViewLayout;
    
    collectionViewWidth = self.playersCollectionView.frame.size.width - layout.sectionInset.left - layout.sectionInset.right - 1;
    
    cellsPerRow = (int)collectionViewWidth / (int)initialCellWidth;
    remainingSpace = collectionViewWidth - (cellsPerRow * initialCellWidth);
    
    if (cellsPerRow > 1) {
        interItemSpacing = remainingSpace / (cellsPerRow - 1);
    }
    
    self.cellWidth = initialCellWidth;
    layout.minimumInteritemSpacing = interItemSpacing;
    layout.minimumLineSpacing = interItemSpacing;
    
    self.playersCollectionView.collectionViewLayout = layout;
}

- (void)resizePlayerCollection
{
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.playersCollectionView.collectionViewLayout;
    
    // Minimum number of rows is 2 for the two team players
    NSInteger rows = 2;

    // Now figure out how many additional rows we may be showing.
    CGFloat collectionViewWidth = self.playersCollectionView.frame.size.width - layout.sectionInset.left - layout.sectionInset.right - 1;
    NSInteger cellsPerRow = (int)collectionViewWidth / (int)self.cellWidth;
    NSInteger playerCount = ([self.rosterArray count] >= 2 ? [self.rosterArray count] - 2 : [self.rosterArray count]);
    rows += ceil(playerCount / (float)cellsPerRow);
    
    CGFloat collectionViewHeight = (rows * self.cellWidth) + (layout.minimumLineSpacing * (rows - 1)) + layout.sectionInset.top + layout.sectionInset.bottom;
    
    CGFloat viewHeight = self.view.frame.size.height;
    CGFloat maxHeight = viewHeight / 2.0;
    if (collectionViewHeight > maxHeight) {
        collectionViewHeight = maxHeight;
    }
    self.playerCollectionHeightConstraint.constant = collectionViewHeight;
    
    [UIView animateWithDuration:0.2 animations:^{
        [self.playersCollectionView.collectionViewLayout invalidateLayout];
    }];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:INSOShowEventListEditorSegueIdentifier]) {
        [self prepareForShowEventListEditorSegue:segue sender:sender];
    }
    if ([segue.identifier isEqualToString:INSOShowEventSelectorSegueIdentifier]) {
        [self prepareForShowEventSelectorSegue:segue sender:sender];
    }
}

- (void)prepareForShowEventListEditorSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    INSOEventListEditorViewController* dest = segue.destinationViewController;
    dest.game = self.game;
}

- (void)prepareForShowEventSelectorSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    UICollectionViewCell* cell = (UICollectionViewCell*)sender;
    NSIndexPath* indexPath = [self.playersCollectionView indexPathForCell:cell];
    RosterPlayer* player = self.rosterArray[indexPath.row];
    INSOGameEventSelectorTableViewController* dest = segue.destinationViewController;
    dest.rosterPlayer = player;
}

#pragma mark - Delegate
#pragma mark - UICollectionView Delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.rosterArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell
    INSOPlayerCollectionViewCell *cell = (INSOPlayerCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:INSORosterPlayerCellReuseIdentifier forIndexPath:indexPath];

    [self configureRosterPlayerCell:cell atIndexPath:indexPath];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = self.cellWidth;
    CGFloat width = self.cellWidth;
    
    RosterPlayer* player = self.rosterArray[indexPath.row];
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)collectionView.collectionViewLayout;
    if (player.isTeamValue) {
        width = collectionView.frame.size.width - layout.sectionInset.left - layout.sectionInset.right;
    }
            
    return CGSizeMake(width, height);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:INSOShowEventSelectorSegueIdentifier sender:[collectionView cellForItemAtIndexPath:indexPath]];
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.managedObjectContext processPendingChanges];
}

@end
