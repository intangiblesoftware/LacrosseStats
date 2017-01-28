//
//  INSOGameTableViewController.m
//  ScorebookLite
//
//  Created by James Dabrowski on 9/24/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

@import CoreData;

#import "INSOProductManager.h"
#import "MensLacrosseStatsAppDelegate.h"

#import "INSOGameTableViewController.h"
#import "INSOGameTableViewCell.h"
#import "INSOGameDetailViewController.h"

#import "Game.h"
#import "Event.h"
#import "RosterPlayer.h"

static NSString * const INSOGameCellIdentifier = @"GameCell";
static NSString * const INSOShowGameDetailSegueIdentifier = @"ShowGameDetailSegue";
static NSString * const INSOShowPurchaseModalSegueIdentifier = @"ShowPurchaseModalSegue";

@interface INSOGameTableViewController () <NSFetchedResultsControllerDelegate, INSOProductManagerDelegate>
// IBOutlets
@property (nonatomic, weak) IBOutlet UIBarButtonItem* addButton;

// IBActions
- (IBAction)addGame:(id)sender;

// Private Properties
@property (nonatomic) NSFetchedResultsController* gamesFRC;
@property (nonatomic) NSManagedObjectContext* managedObjectContext;

// Private Methods
- (void)configureTableView;
- (void)configureGameCell:(INSOGameTableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;

- (void)prepareForShowGameDetailSegue:(UIStoryboardSegue*)segue sender:(INSOGameTableViewCell*)cell;

@end

@implementation INSOGameTableViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.addButton.enabled = NO; 
    
    [INSOProductManager sharedManager].delegate = self;
    [[INSOProductManager sharedManager] refreshProduct];
    
    [self configureTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [INSOProductManager sharedManager].delegate = nil;
}

#pragma mark - IBActions
- (void)addGame:(id)sender
{
    if ([[INSOProductManager sharedManager] productIsPurchased] && ![[INSOProductManager sharedManager] productPurchaseExpired]) {
        // If the app is purchased, just create a new game. No hoo-hoo.
        [self createNewGame];
    } else {
        // Now we gotta see how many games there are.
        // If there is one already, don't let 'em create a new one.
        // Instead, show the buy me! modal.
        NSInteger numberOfGames = [[[self.gamesFRC sections] objectAtIndex:0] numberOfObjects];
        if (numberOfGames >= 1) {
            [self performSegueWithIdentifier:INSOShowPurchaseModalSegueIdentifier sender:self];
        } else {
            [self createNewGame]; 
        }
    }
}

#pragma mark - Private Properties
- (NSFetchedResultsController*)gamesFRC
{
    if (!_gamesFRC) {
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:[Game entityName]];
        [request setFetchBatchSize:50];
        
        NSSortDescriptor* sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"gameDateTime" ascending:NO];
        [request setSortDescriptors:@[sortByDate]];
        
        _gamesFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:request  managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        _gamesFRC.delegate = self;
        
        NSError* error = nil;
        if (![_gamesFRC performFetch:&error]) {
            // Error fetching games
            NSLog(@"Error fetching games: %@", error.localizedDescription);
        }
    }
    
    return _gamesFRC;
}
                     
- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        MensLacrosseStatsAppDelegate* appDelegate = (MensLacrosseStatsAppDelegate *)[[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

#pragma mark - Private Methods
- (void)configureTableView
{
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.alwaysBounceVertical = NO;
    self.tableView.estimatedRowHeight = 189.0;
}

- (void)configureGameCell:(INSOGameTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Game* game = [self.gamesFRC objectAtIndexPath:indexPath];

    NSString* dateFormat = [NSDateFormatter dateFormatFromTemplate:@"Mdyy" options:0 locale:[NSLocale currentLocale]];
    NSString* timeFormat = [NSDateFormatter dateFormatFromTemplate:@"hmma" options:0 locale:[NSLocale currentLocale]];
    NSString* dateTimeFormat = [NSString stringWithFormat:@"%@' at '%@", dateFormat, timeFormat];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateTimeFormat];
    cell.gameDateTimeLabel.text = [formatter stringFromDate:game.gameDateTime];
    
    cell.homeTeamLabel.text = game.homeTeam;
    cell.homeScoreLabel.text = [NSString stringWithFormat:@"%@", game.homeScore];
    
    cell.visitingTeamLabel.text = game.visitingTeam;
    cell.visitingScoreLabel.text = [NSString stringWithFormat:@"%@", game.visitorScore];
    
    cell.locationLabel.text = game.location;
}

- (NSDate*)newGameStartDateTime
{
    NSDate* currentDate = [NSDate date];
    NSDateComponents* components = [[NSCalendar currentCalendar] components: (NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:currentDate];
    NSInteger minutes = components.minute;
    float minuteUnit = ceil((float) minutes / 30.0);
    minutes = minuteUnit * 30;
    [components setMinute:minutes];
    return [[NSCalendar currentCalendar] dateFromComponents:components];
}

- (void)createNewGame
{
    // Create a game with now as the game date time
    Game* newGame = [Game insertInManagedObjectContext:self.managedObjectContext];
    newGame.gameDateTime = [self newGameStartDateTime];
    
    // Team to record
    newGame.teamWatching = newGame.homeTeam;
    
    // Set up events to record
    NSArray* defaultEvents = [Event fetchDefaultEvents:self.managedObjectContext];
    NSSet* eventSet = [NSSet setWithArray:defaultEvents];
    [newGame addEventsToRecord:eventSet];
    
    // Give the game 2 team players
    RosterPlayer* teamPlayer = [RosterPlayer insertInManagedObjectContext:self.managedObjectContext];
    teamPlayer.numberValue = INSOTeamWatchingPlayerNumber;
    teamPlayer.isTeamValue = YES;
    [newGame addPlayersObject:teamPlayer];
    
    RosterPlayer *otherTeamPlayer = [RosterPlayer insertInManagedObjectContext:self.managedObjectContext];
    otherTeamPlayer.numberValue = INSOOtherTeamPlayerNumber;
    otherTeamPlayer.isTeamValue = YES;
    [newGame addPlayersObject:otherTeamPlayer];
    
    NSError* error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving MOC after creating new game: %@", error.localizedDescription);
    }
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:INSOShowGameDetailSegueIdentifier]) {
        [self prepareForShowGameDetailSegue:segue sender:sender];
    }
    
    if ([segue.identifier isEqualToString:INSOShowPurchaseModalSegueIdentifier]) {
        [self prepareForShowPurchaseModalSegue:segue sender:sender];
    }
}

- (void)prepareForShowGameDetailSegue:(UIStoryboardSegue *)segue sender:(INSOGameTableViewCell *)cell
{
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    Game* selectedGame = [self.gamesFRC objectAtIndexPath:indexPath];
    INSOGameDetailViewController* dest = segue.destinationViewController;
    dest.game = selectedGame; 
}

- (void)prepareForShowPurchaseModalSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    // Nothing to do here, yet.
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self.gamesFRC sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    INSOGameTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:INSOGameCellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    [self configureGameCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Game* game = [self.gamesFRC objectAtIndexPath:indexPath];
        [self.managedObjectContext deleteObject:game];
    }
    
    NSError* error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving MOC after deleting game: %@", error.localizedDescription);
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 189.0;
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        case NSFetchedResultsChangeMove:
            [self.tableView reloadData]; 
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark - INSOProductManagerDelegate
- (void)didRefreshProduct
{
    self.addButton.enabled = YES;
}

@end
