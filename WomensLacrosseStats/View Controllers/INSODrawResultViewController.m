//
//  INSODrawResultViewController.m
//  LacrosseStats
//
//  Created by James Dabrowski on 2/6/16.
//  Copyright © 2016 Intangible Software. All rights reserved.
//

#import "INSODrawResultViewController.h"

#import "WomensAppDelegate.h"
#import "INSOPlayerCollectionViewCell.h"

#import "RosterPlayer.h"
#import "Game.h"
#import "GameEvent.h"
#import "Event.h"

static NSString * const PlayerCellIdentifier = @"PlayerCell";

static NSString * const INSODoneAddingEventSegueIdentifier = @"DoneAddingEventSegue";

static const CGFloat INSODefaultPlayerCellSize = 50.0;

@interface INSODrawResultViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
// IBOutlets
@property (nonatomic, weak) IBOutlet UIBarButtonItem* doneButton;
@property (nonatomic, weak) IBOutlet UISwitch* wonDrawControlSwitch;
@property (nonatomic, weak) IBOutlet UILabel* instructionLabel;
@property (nonatomic, weak) IBOutlet UICollectionView* playerCollection;

// IBActions
- (IBAction)done:(id)sender;
- (IBAction)toggleDrawControl:(id)sender; 

// Private Properties
@property (nonatomic) NSArray* rosterArray;
@property (nonatomic) NSIndexPath* selectedIndexPath;
@property (nonatomic) NSManagedObjectContext* managedObjectContext;
@property (nonatomic) CGFloat cellWidth;
@property (nonatomic) BOOL canRecordDrawControl; 

// Private Methods
- (void)configureRosterPlayerCell:(INSOPlayerCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation INSODrawResultViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cellWidth = INSODefaultPlayerCellSize;
    
    Event* drawControlEvent = [Event eventForCode:INSOEventCodeDrawControl inManagedObjectContext:self.managedObjectContext];
    self.canRecordDrawControl = [self.center.game.eventsToRecord containsObject:drawControlEvent];

    [self configureView];
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
    [self createDrawTakenEvent];
    
    if (self.wonDrawControlSwitch.isOn) {
        [self createDrawControlEvent];
        [self createDrawPossessionEvent];
    }
    
    
    // Now save all this
    NSError* error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving the faceoff won and groundball events: %@, %@", error, error.userInfo);
    }
    
    [self performSegueWithIdentifier:INSODoneAddingEventSegueIdentifier sender:nil];
}

- (void)toggleDrawControl:(id)sender
{
    [self configureView];
}

#pragma mark - Private Properties
- (NSArray*)rosterArray
{
    if (!_rosterArray) {
        // Get all the players from the roster
        NSSortDescriptor* sortByNumber = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
        NSMutableArray* roster = [[NSMutableArray alloc] initWithArray:[self.center.game.players sortedArrayUsingDescriptors:@[sortByNumber]]];
        
        _rosterArray = roster;
    }
    return _rosterArray;
}

- (NSManagedObjectContext*)managedObjectContext
{
    // Just want to use the game's moc and want an easier ref to it.
    if (!_managedObjectContext) {
        WomensAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    
    return _managedObjectContext;
}

#pragma mark - Private Methods
- (void)configureView
{
    NSString* instructionString;
    if (self.center && !self.center.isTeamValue) {
        instructionString = [NSString stringWithFormat:@"#%@ won draw possession. Select the player that won draw control.", self.center.number];
    } else {
        instructionString = [NSString stringWithFormat:@"Select the player that won draw control."];
    }
    self.instructionLabel.text = instructionString;
    
    CGFloat transparency = 0.0;
    if (self.wonDrawControlSwitch.isOn && self.canRecordDrawControl) {
        transparency = 1.0;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.instructionLabel.alpha = transparency;
        self.playerCollection.alpha = transparency;
    }];
    
    self.doneButton.enabled = [self shouldEnableDoneButton];
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

- (GameEvent*)createDrawTakenEvent
{
    GameEvent* drawTakenEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    
    drawTakenEvent.timestamp = [NSDate date];
    drawTakenEvent.event = [Event eventForCode:INSOEventCodeDrawTaken inManagedObjectContext:self.managedObjectContext];
    drawTakenEvent.game = self.center.game;
    drawTakenEvent.player = self.center;
    
    return drawTakenEvent;
}

- (GameEvent*)createDrawControlEvent
{
    GameEvent* drawControlEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    
    drawControlEvent.timestamp = [NSDate date];
    drawControlEvent.event = [Event eventForCode:INSOEventCodeDrawControl inManagedObjectContext:self.managedObjectContext];
    
    RosterPlayer* drawControlPlayer = self.center;
    if (self.selectedIndexPath) {
        drawControlPlayer = self.rosterArray[self.selectedIndexPath.row];
    }
    drawControlEvent.game = drawControlPlayer.game;
    drawControlEvent.player = drawControlPlayer;
    
    return drawControlEvent;
}

- (GameEvent*)createDrawPossessionEvent
{
    GameEvent* drawPossessionEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    
    drawPossessionEvent.timestamp = [NSDate date];
    drawPossessionEvent.event = [Event eventForCode:INSOEventCodeDrawPossession inManagedObjectContext:self.managedObjectContext];
    drawPossessionEvent.game = self.center.game;
    drawPossessionEvent.player = self.center;
    
    return drawPossessionEvent;
}

- (BOOL)shouldEnableDoneButton
{
    if (self.wonDrawControlSwitch.isOn && self.canRecordDrawControl) {
        return self.selectedIndexPath != nil;
    } else {
        return YES;
    }
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
    
    self.doneButton.enabled = [self shouldEnableDoneButton]; 
    
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
