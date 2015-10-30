//
//  INSORosterPlayerSelectorViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/18/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "UIColor+INSOScorebookColor.h"

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
@property (nonatomic, weak) IBOutlet UIBarButtonItem* undoButton;

// IBAction
- (IBAction)doneAddingEvent:(UIStoryboardSegue*)sender;
- (IBAction)tappedUndo:(id)sender;

// Private properties
@property (nonatomic) NSArray* rosterArray;
@property (nonatomic) NSFetchedResultsController* fetchedResultsController;
@property (nonatomic) NSManagedObjectContext* managedObjectContext; 

// Private methods

@end

@implementation INSORosterPlayerSelectorViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];    
}

- (void)viewWillAppear:(BOOL)animated
{
    self.undoButton.enabled = [[self.fetchedResultsController fetchedObjects] count] > 0;
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

#pragma mark - IBActions
- (void)doneAddingEvent:(UIStoryboardSegue *)sender
{
    [self.navigationController popToViewController:self animated:YES]; 
}

- (void)tappedUndo:(id)sender
{
    GameEvent* lastGameEvent = [[self.fetchedResultsController fetchedObjects] firstObject];
    
    NSString* title = NSLocalizedString(@"Undo Last Event", nil);
    
    NSString* message;
    NSString* messageFormatString;
    if (lastGameEvent.player.isTeamValue) {
        messageFormatString = NSLocalizedString(@"Undo the %@ event?", nil);
        message = [NSString stringWithFormat:messageFormatString, [lastGameEvent.event.title lowercaseString]];
    } else {
        messageFormatString = NSLocalizedString(@"Undo the %@ event by #%@?", nil);
        message = [NSString stringWithFormat:messageFormatString, [lastGameEvent.event.title lowercaseString], lastGameEvent.player.number];
    }
    
    UIAlertController* undoAlert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* undoAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Undo", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.managedObjectContext deleteObject:lastGameEvent];
    }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    [undoAlert addAction:cancelAction];
    [undoAlert addAction:undoAction];
    
    [self presentViewController:undoAlert animated:YES completion:nil];
    
    undoAlert.view.tintColor = [UIColor scorebookBlue];
    
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
        MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
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
    cell.playerNumberLabel.text = [NSString stringWithFormat:@"%@", rosterPlayer.number];
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
    RosterPlayer* player = self.rosterArray[indexPath.row];
    if (player.isTeamValue) {
        UICollectionViewCell* teamPlayerCell = [collectionView dequeueReusableCellWithReuseIdentifier:INSOTeamPlayerCellReuseIdentifier forIndexPath:indexPath];
        return teamPlayerCell;
    } else {
        INSOPlayerCollectionViewCell *cell;
        cell = (INSOPlayerCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:INSORosterPlayerCellReuseIdentifier forIndexPath:indexPath];
        [self configureRosterPlayerCell:cell atIndexPath:indexPath];
        return cell;
    }
    
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:INSOShowEventSelectorSegueIdentifier sender:[collectionView cellForItemAtIndexPath:indexPath]];
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.managedObjectContext processPendingChanges];
    self.undoButton.enabled = [[self.fetchedResultsController fetchedObjects] count] > 0;
}

@end
