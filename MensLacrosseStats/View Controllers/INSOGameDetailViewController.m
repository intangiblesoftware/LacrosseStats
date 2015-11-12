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

@interface INSOGameDetailViewController ()
// IBOutlets
@property (nonatomic, weak) IBOutlet UILabel* gameDateTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel* homeTeamLabel;
@property (nonatomic, weak) IBOutlet UILabel* homeScoreLabel;
@property (nonatomic, weak) IBOutlet UILabel* visitingTeamLabel;
@property (nonatomic, weak) IBOutlet UILabel* visitingScoreLabel;
@property (nonatomic, weak) IBOutlet UILabel* locationLabel;

// IBActions

// Private Properties
@property (nonatomic) NSManagedObjectContext* managedObjectContext;
@property (nonatomic) NSInteger countOfGoals;
@property (nonatomic) NSInteger countOfGoalsAllowed;

// Private Methods

@end

@implementation INSOGameDetailViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
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
//- (NSFetchedResultsController*)visitorScoreFRC
//{
//    if (!_visitorScoreFRC) {
//        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:[GameEvent entityName]];
//        [request setFetchBatchSize:50];
//        
//        INSOEventCode eventCode;
//        if ([self.game.teamWatching isEqualToString:self.game.visitingTeam]) {
//            eventCode = INSOEventCodeGoal;
//        } else {
//            eventCode = INSOEventCodeGoalAllowed;
//        }
//        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"game == %@ AND event.eventCode == %@", self.game, @(eventCode)];
//        request.predicate = predicate;
//        
//        NSSortDescriptor* sortByTimestamp = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
//        request.sortDescriptors = @[sortByTimestamp];
//        
//        _visitorScoreFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
//        _visitorScoreFRC.delegate = self;
//        
//        NSError* error = nil;
//        if (![_visitorScoreFRC performFetch:&error]) {
//            // Error fetching games
//            NSLog(@"Error fetching games: %@", error.localizedDescription);
//        }
//    }
//    return _visitorScoreFRC;
//}

- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

- (NSInteger)countOfGoals
{
    NSSet* goals = [self.game.events objectsPassingTest:^BOOL(GameEvent*  _Nonnull gameEvent, BOOL * _Nonnull stop) {
        return gameEvent.event.eventCodeValue == INSOEventCodeGoal;
    }];
    
    return [goals count];
}

- (NSInteger)countOfGoalsAllowed
{
    NSSet* goals = [self.game.events objectsPassingTest:^BOOL(GameEvent*  _Nonnull gameEvent, BOOL * _Nonnull stop) {
        return gameEvent.event.eventCodeValue == INSOEventCodeGoalAllowed;
    }];
    
    return [goals count];
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
    self.visitingTeamLabel.text = self.game.visitingTeam;

    NSInteger goals = self.countOfGoals;
    NSInteger goalsAllowed = self.countOfGoalsAllowed;
    
    if ([self.game.homeTeam isEqualToString:self.game.teamWatching]) {
        self.homeScoreLabel.text = [NSString stringWithFormat:@"%@", @(goals)];
        self.game.homeScoreValue = goals;
    } else {
        self.homeScoreLabel.text = [NSString stringWithFormat:@"%@", @(goalsAllowed)];
        self.game.homeScoreValue = goalsAllowed;
    }
    
    if ([self.game.visitingTeam isEqualToString:self.game.teamWatching]) {
        self.visitingScoreLabel.text = [NSString stringWithFormat:@"%@", @(goals)];
        self.game.visitorScoreValue = goals;
    } else {
        self.visitingScoreLabel.text = [NSString stringWithFormat:@"%@", @(goalsAllowed)];
        self.game.visitorScoreValue = goalsAllowed;
    }
    
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


@end
