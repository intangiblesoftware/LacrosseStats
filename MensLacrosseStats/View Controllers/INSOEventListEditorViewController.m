//
//  INSOEventListEditorViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/21/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

@import CoreData;

#import "Game.h"
#import "GameEvent.h"
#import "Event.h"
#import "RosterPlayer.h"

#import "MensLacrosseStatsAppDelegate.h"

#import "INSOEventListEditorViewController.h"

@interface INSOEventListEditorViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UINavigationBarDelegate>

// IBOutlets
@property (nonatomic, weak) IBOutlet UITableView* eventTable;

// IBActions
- (IBAction)done:(id)sender;

// Private Properties
@property (nonatomic) NSFetchedResultsController* gameEventsFRC;
@property (nonatomic) NSManagedObjectContext* managedObjectContext;

@end

@implementation INSOEventListEditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.eventTable setEditing:YES animated:YES];
    self.eventTable.alwaysBounceVertical = NO;
    self.eventTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSFetchedResultsController*)gameEventsFRC
{
    if (!_gameEventsFRC) {
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:[GameEvent entityName]];
        [request setFetchBatchSize:50];
        
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@", self.game];
        request.predicate = predicate; 
        
        NSSortDescriptor* sortByTimestamp = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
        [request setSortDescriptors:@[sortByTimestamp]];
        
        _gameEventsFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        _gameEventsFRC.delegate = self;
        
        NSError* error = nil;
        if (![_gameEventsFRC performFetch:&error]) {
            // Error fetching games
            NSLog(@"Error fetching games: %@", error.localizedDescription);
        }
    }
    
    return _gameEventsFRC;
}

- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

#pragma mark - IBActions
- (void)done:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil]; 
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self.gameEventsFRC sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    GameEvent* gameEvent = [self.gameEventsFRC objectAtIndexPath:indexPath];
    if (gameEvent.player.isTeamValue) {
        cell.textLabel.text = gameEvent.event.title;
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"#%@ %@", gameEvent.player.number, gameEvent.event.title];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        GameEvent* event = [self.gameEventsFRC objectAtIndexPath:indexPath];
        [self.managedObjectContext deleteObject:event];
    }
    
    NSError* error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving MOC after deleting game event: %@", error.localizedDescription);
    }
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.eventTable beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.eventTable insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.eventTable deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.eventTable reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        case NSFetchedResultsChangeMove:
            [self.eventTable reloadData];
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.eventTable endUpdates];
}

#pragma mark - Navigation Bar Delegate
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached; 
}

@end
