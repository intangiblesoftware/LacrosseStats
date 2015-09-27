//
//  INSOGameTableViewController.m
//  ScorebookLite
//
//  Created by James Dabrowski on 9/24/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

@import CoreData;

#import "AppDelegate.h"

#import "INSOGameTableViewController.h"
#import "INSOGameTableViewCell.h"

#import "Game.h"


static NSString* const INSOGameCellIdentifier = @"GameCell";

@interface INSOGameTableViewController () <NSFetchedResultsControllerDelegate>
// IBOutlets

// IBActions
- (IBAction)addGame:(id)sender;

// Private Properties
@property (nonatomic) NSFetchedResultsController* gamesFRC;
@property (nonatomic) NSManagedObjectContext* managedObjectContext;

// Private Methods
- (void)configureTableView;
- (void)configureGameCell:(INSOGameTableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;

@end

@implementation INSOGameTableViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions
- (void)addGame:(id)sender
{
    // Create a game with default values and now as the game date time
    Game* newGame = [Game insertInManagedObjectContext:self.managedObjectContext];
    newGame.gameDateTime = [NSDate date];
    
    NSError* error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving MOC after creating new game: %@", error.localizedDescription);
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
        AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
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

    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"M/d/yyyy' at 'h:mm a"];
    cell.gameDateTimeLabel.text = [formatter stringFromDate:game.gameDateTime];
    
    cell.homeTeamLabel.text = game.homeTeam;
    cell.homeScoreLabel.text = [NSString stringWithFormat:@"%@", game.homeScore];
    
    cell.visitingTeamLabel.text = game.visitingTeam;
    cell.visitingScoreLabel.text = [NSString stringWithFormat:@"%@", game.visitorScore];
    
    cell.locationLabel.text = game.location;
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
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
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
