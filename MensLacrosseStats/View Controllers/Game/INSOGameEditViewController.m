//
//  INSOGameEditViewController.m
//  ScorebookLite
//
//  Created by James Dabrowski on 9/26/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//


#import "AppDelegate.h"

#import "LacrosseStats-Swift.h"

#import "INSOGameEditViewController.h"
#import "LacrosseStatsConstants.h"

#import "Game.h"
#import "RosterPlayer.h"
#import "EventCategory.h"
#import "Event.h"


typedef NS_ENUM(NSUInteger, INSOPlayerStatSegment) {
    INSOPlayerStatSegmentPlayer,
    INSOPlayerStatSegmentStats
};

typedef NS_ENUM(NSUInteger, INSOTeamToRecordSegmentIndex) {
    INSOTeamToRecordSegmentIndexHomeTeam,
    INSOTeamToRecordSegmentIndexVisitingTeam
};

static NSString * const INSOPlayerCellIdentifier = @"PlayerCell";
static NSString * const INSOStatCellIdentifier = @"StatCell";
static NSString * const INSOHeaderViewIdentifier = @"HeaderView";

static const CGFloat INSODefaultPlayerCellSize = 50.0;

@interface INSOGameEditViewController () <UINavigationBarDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
// IBOutlet
@property (nonatomic, weak) IBOutlet UIBarButtonItem* cancelButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem* doneButton;

@property (nonatomic, weak) IBOutlet UITextField* gameDateTimeField;
@property (nonatomic, weak) IBOutlet UITextField* homeTeamField;
@property (nonatomic, weak) IBOutlet UITextField* visitingTeamField;
@property (nonatomic, weak) IBOutlet UISegmentedControl* teamToRecordSegmentedControl;
@property (nonatomic, weak) IBOutlet UITextField* locationField;

@property (nonatomic, weak) IBOutlet UISegmentedControl* playerStatSegmentedControl;

@property (nonatomic, weak) IBOutlet UICollectionView* playerStatCollectionView;

@property (nonatomic) CGFloat cellWidth;

// IBActions
- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)switchPlayerStatSegment:(id)sender;
- (IBAction)switchTeamRecordingStatsFor:(id)sender;

// Private Properties
@property (nonatomic) UIToolbar* datePickerToolbar;
@property (nonatomic) UIDatePicker* datePicker;
@property (nonatomic) NSManagedObjectContext* managedObjectContext;
@property (nonatomic) NSArray* playersArray;
@property (nonatomic) NSMutableSet* selectedStats;
@property (nonatomic) NSFetchedResultsController* eventsFRC;

// Private Methods
- (void)configureView;

- (void)configurePlayerCell:(INSOPlayerCollectionViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;
- (void)configureStatCell:(INSOStatCollectionViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;

- (BOOL)shouldEnableDoneButton;
- (void)dateChanged;
- (void)doneSettingDate;

- (NSString*)gameDateAsString;

- (void)addPlayerToGameWithNumber:(NSNumber*)number;
- (void)removePlayerFromGameWithNumber:(NSNumber*)number;


@end

@implementation INSOGameEditViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.playerStatCollectionView.allowsMultipleSelection = YES;
//    [self.playerStatCollectionView registerClass:INSOPlayerCollectionViewCell forCellWithReuseIdentifier:INSOPlayerCellIdentifier]
    
    [self configureView];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    // We no longer transition to orientation, we transition to size. So use this instead.
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Once we transition to size,
    // invalidate the content size and invalidate the layout.
    // This will redraw the cells of the proper size.
    [self.playerStatCollectionView invalidateIntrinsicContentSize];
    [self.playerStatCollectionView.collectionViewLayout invalidateLayout];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self layoutPlayerStatCollection];
}

#pragma mark - IBActions
- (void)cancel:(id)sender
{
    // Discard any changes that may have been made.
    if ([self.game hasChanges]) {
        [self.managedObjectContext rollback];
    }
    
    // And go away.
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)done:(id)sender
{
    // Put away keyboard if necessary.
    [self.view endEditing:YES];
    
    // Just save the changes that have already been made.
    NSError* error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving changes to game: %@", error.localizedDescription);
    }

    // Now dismiss
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)switchPlayerStatSegment:(id)sender
{
    [self.playerStatCollectionView reloadData]; 
}

- (void)switchTeamRecordingStatsFor:(id)sender
{
    self.game.teamWatching = [self.teamToRecordSegmentedControl titleForSegmentAtIndex:self.teamToRecordSegmentedControl.selectedSegmentIndex];
}

#pragma mark - Private Properties
- (UIToolbar*)datePickerToolbar
{
    if (!_datePickerToolbar) {
        _datePickerToolbar = [[UIToolbar alloc] init];
        
        UIBarButtonItem* spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneSettingDate)];
        
        _datePickerToolbar.items = @[spacer, doneButton];
        
        // Again, getting it working and looking right. Should make the tint color specific to the build target. 
        if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:INSOMensIdentifier]) {
            _datePickerToolbar.tintColor = [UIColor scorebookBlue];
        } else {
            _datePickerToolbar.tintColor = [UIColor scorebookTeal];
        }

        [_datePickerToolbar sizeToFit];
    }
    return _datePickerToolbar;
}
- (UIDatePicker*)datePicker
{
    if (!_datePicker) {
        _datePicker = [[UIDatePicker alloc] init];
        if (@available(iOS 13.4, *)) {
            // Since we can set the style of the date picker in ios 13+, gonna keep it old-school for now. 
            _datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
        }
        _datePicker.datePickerMode = UIDatePickerModeDateAndTime;
        _datePicker.minuteInterval = 15;
        _datePicker.date = self.game.gameDateTime;
        [_datePicker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];
    }
    return _datePicker;
}

- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

- (NSArray*)playersArray
{
    if (!_playersArray) {
        NSMutableArray* tempArray = [NSMutableArray new];
        for (NSInteger playerNumber = 0; playerNumber < 100; playerNumber++) {
            [tempArray addObject:[NSNumber numberWithInteger:playerNumber]];
        }
        _playersArray = tempArray;
    }
    return _playersArray; 
}

- (NSFetchedResultsController*)eventsFRC
{
    if (!_eventsFRC) {
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[Event entityName]];
        
        [fetchRequest setFetchBatchSize:20];
        
        NSSortDescriptor* sortByCategory = [NSSortDescriptor sortDescriptorWithKey:@"categoryCode" ascending:YES];
        NSSortDescriptor* sortByTitle = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        [fetchRequest setSortDescriptors:@[sortByCategory, sortByTitle]];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"eventCode != %@", @(INSOEventCode8mFreePositionShot)];
        fetchRequest.predicate = predicate;
        
        _eventsFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"category.categoryCode" cacheName:nil];
        
        NSError *error = nil;
        if (![_eventsFRC performFetch:&error]) {
            NSLog(@"Error fetching up games %@, %@", error, [error userInfo]);
        }
    }
    
    return _eventsFRC;
}

#pragma mark - Private Methods
- (void)configureView
{
    self.gameDateTimeField.text = [self gameDateAsString];
    self.gameDateTimeField.inputView = self.datePicker;
    self.gameDateTimeField.inputAccessoryView = self.datePickerToolbar;
    
    self.homeTeamField.text = self.game.homeTeam;
    self.visitingTeamField.text = self.game.visitingTeam;
    
    [self.teamToRecordSegmentedControl setTitle:self.game.homeTeam forSegmentAtIndex:INSOTeamToRecordSegmentIndexHomeTeam];
    [self.teamToRecordSegmentedControl setTitle:self.game.visitingTeam forSegmentAtIndex:INSOTeamToRecordSegmentIndexVisitingTeam];
    if ([self.game.homeTeam isEqualToString:self.game.teamWatching]) {
        [self.teamToRecordSegmentedControl setSelectedSegmentIndex:INSOTeamToRecordSegmentIndexHomeTeam];
    } else {
        [self.teamToRecordSegmentedControl setSelectedSegmentIndex:INSOTeamToRecordSegmentIndexVisitingTeam]; 
    }
    
    self.locationField.text = self.game.location;
    
    self.doneButton.enabled = [self shouldEnableDoneButton]; 
}

- (void)configurePlayerCell:(INSOPlayerCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSNumber* playerNumber = self.playersArray[indexPath.row];
    
    cell.playerNumberLabel.text = [NSString stringWithFormat:@"%@", playerNumber];

    if ([self.game rosterContainsPlayerWithNumber:playerNumber]) {
        RosterPlayer* player = [self.game playerWithNumber:playerNumber];
        if (!player.isDeleted) {
            cell.selected = YES;
            [self.playerStatCollectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
    }
}

- (void)configureStatCell:(INSOStatCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Event* event = [self.eventsFRC objectAtIndexPath:indexPath];
    cell.statNameLabel.text = event.title;
    
    if ([self.game.eventsToRecord containsObject:event]) {
        cell.selected = YES;
        [self.playerStatCollectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}

- (BOOL)shouldEnableDoneButton
{
    NSString* homeString = [self.homeTeamField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString* visitingString = [self.visitingTeamField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    return ([homeString length] > 0) && ([visitingString length] > 0);
}

- (void)dateChanged
{
    // Update the label and the game
    self.game.gameDateTime = self.datePicker.date;
    self.gameDateTimeField.text = [self gameDateAsString];
}

- (NSString*)gameDateAsString
{
    NSString* dateFormat = [NSDateFormatter dateFormatFromTemplate:@"Mdyy" options:0 locale:[NSLocale currentLocale]];
    NSString* timeFormat = [NSDateFormatter dateFormatFromTemplate:@"hmma" options:0 locale:[NSLocale currentLocale]];
    NSString* dateTimeFormat = [NSString stringWithFormat:@"%@' at '%@", dateFormat, timeFormat];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateTimeFormat];
    return [formatter stringFromDate:self.game.gameDateTime];
}

- (void)doneSettingDate
{
    [self.homeTeamField becomeFirstResponder]; 
}

- (void)addPlayerToGameWithNumber:(NSNumber *)number
{
    RosterPlayer* rosterPlayer = [RosterPlayer rosterPlayerWithNumber:number inManagedObjectContext:self.managedObjectContext];
    [self.game addPlayersObject:rosterPlayer];
}

- (void)removePlayerFromGameWithNumber:(NSNumber *)number
{
    // Gotta be a bit more careful here.
    RosterPlayer* playerToDelete = [self.game playerWithNumber:number];
    [self.game.teamPlayer addEvents:playerToDelete.events];
    
    [self.managedObjectContext deleteObject:playerToDelete];
}

- (void)layoutPlayerStatCollection
{
    CGFloat initialCellWidth = INSODefaultPlayerCellSize;
    CGFloat interItemSpacing = 0.0;
    CGFloat collectionViewWidth = 0.0;
    NSInteger cellsPerRow = 0;
    CGFloat remainingSpace = 0.0;
    
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.playerStatCollectionView.collectionViewLayout;
    
    collectionViewWidth = self.playerStatCollectionView.frame.size.width - layout.sectionInset.left - layout.sectionInset.right - 1;
    
    cellsPerRow = (int)collectionViewWidth / (int)initialCellWidth;
    remainingSpace = collectionViewWidth - (cellsPerRow * initialCellWidth);
    
    if (cellsPerRow > 1) {
        interItemSpacing = remainingSpace / (cellsPerRow - 1);
    }
    
    self.cellWidth = initialCellWidth;
    layout.minimumInteritemSpacing = interItemSpacing;
    layout.minimumLineSpacing = interItemSpacing;
    
    self.playerStatCollectionView.collectionViewLayout = layout;
}

- (NSString*)titleForSectionName:(NSString*)sectionName
{
    INSOCategoryCode categoryCode = [sectionName intValue];
    NSString* title = nil;
    
    switch (categoryCode) {
        case INSOCategoryCodeGameAction:
            title = @"Game Actions";
            break;
        case INSOCategoryCodePersonalFouls:
            if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:INSOMensIdentifier]) {
                title = @"Personal Fouls";
            } else {
                title = @"Fouls";
            }
            break;
        case INSOCategoryCodeTechnicalFouls:
            title = @"Technical Fouls";
            break;
        case INSOCategoryCodeExpulsionFouls:
            title = @"Expulsion Fouls";
            break;
        default:
            title = @"";
            break;
    }

    return title;
}

#pragma mark - Delegate Methods
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached; 
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField endEditing:YES];
    
    self.doneButton.enabled = [self shouldEnableDoneButton];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([textField isEqual:self.gameDateTimeField]) {
        // Set in object when picker changed.
        [self.homeTeamField becomeFirstResponder];
    } else if ([textField isEqual:self.homeTeamField]) {
        self.game.homeTeam = [self.homeTeamField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.teamToRecordSegmentedControl setTitle:self.game.homeTeam forSegmentAtIndex:INSOTeamToRecordSegmentIndexHomeTeam];
        if (self.teamToRecordSegmentedControl.selectedSegmentIndex == INSOTeamToRecordSegmentIndexHomeTeam) {
            self.game.teamWatching = self.game.homeTeam;
        }
        [self.visitingTeamField becomeFirstResponder];
    } else if ([textField isEqual:self.visitingTeamField]) {
        self.game.visitingTeam = [self.visitingTeamField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.teamToRecordSegmentedControl setTitle:self.game.visitingTeam forSegmentAtIndex:INSOTeamToRecordSegmentIndexVisitingTeam];
        if (self.teamToRecordSegmentedControl.selectedSegmentIndex == INSOTeamToRecordSegmentIndexVisitingTeam) {
            self.game.teamWatching = self.game.visitingTeam; 
        }
        [self.locationField becomeFirstResponder];
    } else if ([textField isEqual:self.locationField]) {
        self.game.location = [self.locationField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [textField resignFirstResponder];
    }
}

#pragma mark - UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (self.playerStatSegmentedControl.selectedSegmentIndex == INSOPlayerStatSegmentPlayer) {
        return 1;
    } else {
        return [self.eventsFRC.sections count];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.playerStatSegmentedControl.selectedSegmentIndex == INSOPlayerStatSegmentPlayer) {
        return [self.playersArray count];
    } else {
        return [[[self.eventsFRC sections] objectAtIndex:section] numberOfObjects];
    }
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.playerStatSegmentedControl.selectedSegmentIndex == INSOPlayerStatSegmentPlayer) {
        INSOPlayerCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:INSOPlayerCellIdentifier forIndexPath:indexPath];
        [self configurePlayerCell:cell atIndexPath:indexPath];
        return cell;
    } else {
        INSOStatCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:INSOStatCellIdentifier forIndexPath:indexPath];
        [self configureStatCell:cell atIndexPath:indexPath];
        return cell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.playerStatSegmentedControl.selectedSegmentIndex == INSOPlayerStatSegmentPlayer) {
        NSNumber* number = self.playersArray[indexPath.row];
        
        if (![self.game rosterContainsPlayerWithNumber:number]) {
            [self addPlayerToGameWithNumber:number];
        }
    } else {
        Event* event = [self.eventsFRC objectAtIndexPath:indexPath];
        event.isDefalutValue = YES;
        [self.game addEventsToRecordObject:event];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.playerStatSegmentedControl.selectedSegmentIndex == INSOPlayerStatSegmentPlayer) {
        NSNumber* number = self.playersArray[indexPath.row];
        
        if ([self.game rosterContainsPlayerWithNumber:number]) {
            [self removePlayerFromGameWithNumber:number];
        }
    } else {
        Event* event = [self.eventsFRC objectAtIndexPath:indexPath];
        event.isDefalutValue = NO; 
        [self.game removeEventsToRecordObject:event];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = self.cellWidth;
    CGFloat width = self.cellWidth;

    if (self.playerStatSegmentedControl.selectedSegmentIndex == INSOPlayerStatSegmentStats) {
        CGFloat collectionWidth = collectionView.frame.size.width;
        UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)collectionViewLayout;
        collectionWidth -= (flowLayout.sectionInset.left + flowLayout.sectionInset.right);
        width = collectionWidth;
    }
    
    return CGSizeMake(width, height);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    
    if (self.playerStatSegmentedControl.selectedSegmentIndex == INSOPlayerStatSegmentPlayer) {
        return CGSizeZero;
    } else {
        return CGSizeMake(collectionView.bounds.size.width, 30);
    }
}

- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    INSOHeaderCollectionReusableView* header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:INSOHeaderViewIdentifier forIndexPath:indexPath];
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.eventsFRC sections] objectAtIndex:indexPath.section];
    

    // Configure the header
    header.leftTitleLabel.text = [self titleForSectionName:sectionInfo.name];
    
    return header;
}

@end
