//
//  INSOGameDetailViewController.m
//  ScorebookLite
//
//  Created by James Dabrowski on 9/26/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "MensLacrosseStatsAppDelegate.h"

#import "INSOGameDetailViewController.h"
#import "INSOGameEditViewController.h"
#import "INSORosterPlayerSelectorViewController.h"
#import "INSOMensLacrosseStatsEnum.h"
#import "INSOGameStatsViewController.h"

#import "Game.h"
#import "GameEvent.h"
#import "Event.h"

static NSString * INSOEditGameSegueIdentifier    = @"EditGameSegue";
static NSString * INSORecordStatsSegueIdentifier = @"RecordStatsSegue";
static NSString * INSOGameStatsSegueIdentifier   = @"GameStatsSegue";

@interface INSOGameDetailViewController () <NSFetchedResultsControllerDelegate>
// IBOutlets
@property (nonatomic, weak) IBOutlet UILabel* gameDateTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel* homeTeamLabel;
@property (nonatomic, weak) IBOutlet UILabel* homeScoreLabel;
@property (nonatomic, weak) IBOutlet UILabel* visitingTeamLabel;
@property (nonatomic, weak) IBOutlet UILabel* visitingScoreLabel;
@property (nonatomic, weak) IBOutlet UILabel* locationLabel;

// IBActions

// Private Properties
@property (nonatomic) NSFetchedResultsController* homeScoreFRC;
@property (nonatomic) NSFetchedResultsController* visitorScoreFRC;
@property (nonatomic) NSManagedObjectContext* managedObjectContext;

// Private Methods

@end

@implementation INSOGameDetailViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.game.homeScoreValue = [self.homeScoreFRC.fetchedObjects count];
    self.game.visitorScoreValue = [self.visitorScoreFRC.fetchedObjects count]; 
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions

#pragma mark - Private Properties
- (NSFetchedResultsController*)homeScoreFRC
{
    if (!_homeScoreFRC) {
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:[GameEvent entityName]];
        [request setFetchBatchSize:50];
        
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@", self.game, @(INSOEventCodeGoal)];
        request.predicate = predicate;
        
        NSSortDescriptor* sortByTimestamp = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
        request.sortDescriptors = @[sortByTimestamp];
        
        _homeScoreFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        _homeScoreFRC.delegate = self;
        
        NSError* error = nil;
        if (![_homeScoreFRC performFetch:&error]) {
            // Error fetching games
            NSLog(@"Error fetching games: %@", error.localizedDescription);
        }
    }
    return _homeScoreFRC;
}

- (NSFetchedResultsController*)visitorScoreFRC
{
    if (!_visitorScoreFRC) {
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:[GameEvent entityName]];
        [request setFetchBatchSize:50];
        
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@", self.game, @(INSOEventCodeGoalAllowed)];
        request.predicate = predicate;
        
        NSSortDescriptor* sortByTimestamp = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
        request.sortDescriptors = @[sortByTimestamp];
        
        _visitorScoreFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        _visitorScoreFRC.delegate = self;
        
        NSError* error = nil;
        if (![_visitorScoreFRC performFetch:&error]) {
            // Error fetching games
            NSLog(@"Error fetching games: %@", error.localizedDescription);
        }
    }
    return _visitorScoreFRC;
}

- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

#pragma mark - Private Methods
- (void)configureView
{
    NSString* dateFormat = [NSDateFormatter dateFormatFromTemplate:@"Mdyy" options:0 locale:[NSLocale currentLocale]];
    NSString* timeFormat = [NSDateFormatter dateFormatFromTemplate:@"hmma" options:0 locale:[NSLocale currentLocale]];
    NSString* dateTimeFormat = [NSString stringWithFormat:@"%@' at '%@", dateFormat, timeFormat];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateTimeFormat];
    self.gameDateTimeLabel.text = [formatter stringFromDate:self.game.gameDateTime];
    
    self.homeTeamLabel.text = self.game.homeTeam;
    self.homeScoreLabel.text = [NSString stringWithFormat:@"%@", self.game.homeScore];
    
    self.visitingTeamLabel.text = self.game.visitingTeam;
    self.visitingScoreLabel.text = [NSString stringWithFormat:@"%@", self.game.visitorScore];
    
    self.locationLabel.text = self.game.location;
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:INSOEditGameSegueIdentifier]) {
        [self prepareForGameEditSegue:segue sender:sender];
    }
    
    if ([segue.identifier isEqualToString:INSORecordStatsSegueIdentifier]) {
        [self prepareForRecordStatsSegue:segue sender:sender]; 
    }
    
    if ([segue.identifier isEqualToString:INSOGameStatsSegueIdentifier]) {
        [self prepareForGameStatsSegue:segue sender:sender]; 
    }
}

- (void)prepareForGameEditSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    INSOGameEditViewController* dest = segue.destinationViewController;
    dest.game = self.game; 
}

- (void)prepareForRecordStatsSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    INSORosterPlayerSelectorViewController* dest = segue.destinationViewController;
    dest.game = self.game; 
}

- (void)prepareForGameStatsSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    INSOGameStatsViewController* dest = segue.destinationViewController;
    dest.game = self.game;
}

#pragma mark - Delegates
#pragma mark - NSFetchedResultsControllerDelegate
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    if ([controller isEqual:self.homeScoreFRC]) {
        self.game.homeScoreValue = [self.homeScoreFRC.fetchedObjects count];
    }
    
    if ([controller isEqual:self.visitorScoreFRC]) {
        self.game.visitorScoreValue = [self.visitorScoreFRC.fetchedObjects count];
    }
    
    [self configureView]; 
}

@end
