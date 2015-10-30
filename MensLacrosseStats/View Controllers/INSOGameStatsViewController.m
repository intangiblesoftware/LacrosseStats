//
//  INSOGameStatsViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 10/29/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "MensLacrosseStatsAppDelegate.h"

#import "INSOGameStatsViewController.h"
#import "INSOMensLacrosseStatsConstants.h"
#import "INSOGameStatTableViewCell.h"

#import "Game.h"
#import "EventCategory.h"
#import "Event.h"

static NSString * const INSOGameStatsCellIdentifier = @"GameStatsCell";

@interface INSOGameStatsViewController () <UITableViewDataSource, UITableViewDelegate>
// IBOutlets
@property (nonatomic, weak) IBOutlet UITableView* statsTable;

// Private Properties
@property (nonatomic) NSManagedObjectContext* managedObjectContext;
@property (nonatomic) NSFetchedResultsController* eventsFRC;

@end

@implementation INSOGameStatsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Private Properties
- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

- (NSFetchedResultsController*)eventsFRC
{
    if (!_eventsFRC) {
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[Event entityName]];
        
        [fetchRequest setFetchBatchSize:20];
        
        NSSortDescriptor* sortByCategory = [NSSortDescriptor sortDescriptorWithKey:@"categoryCode" ascending:YES];
        NSSortDescriptor* sortByTitle = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        [fetchRequest setSortDescriptors:@[sortByCategory, sortByTitle]];
        
        _eventsFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"category.Title" cacheName:nil];
        
        NSError *error = nil;
        if (![_eventsFRC performFetch:&error]) {
            NSLog(@"Error fetching up games %@, %@", error, [error userInfo]);
        }
    }
    
    return _eventsFRC;
}

#pragma mark - Private Methods
- (void)configureGameStatCell:(INSOGameStatTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Event* event = [self.eventsFRC objectAtIndexPath:indexPath];
    cell.statNameLabel.text = event.title;
    cell.statCountLabel.text = @"0";
    cell.statPercentLabel.text = @"0.0%%";
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.eventsFRC.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self.eventsFRC sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    INSOGameStatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:INSOGameStatsCellIdentifier forIndexPath:indexPath];
    
    [self configureGameStatCell:cell atIndexPath:indexPath]; 
    
    return cell;
}


@end
