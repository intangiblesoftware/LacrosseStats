//
//  INSOGameDetailViewController.m
//  ScorebookLite
//
//  Created by James Dabrowski on 9/26/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOGameDetailViewController.h"
#import "INSOGameEditViewController.h"
#import "INSORosterPlayerSelectorViewController.h"

#import "Game.h"

static NSString * INSOEditGameSegueIdentifier = @"EditGameSegue";
static NSString * INSORecordStatsSegueIdentifier = @"RecordStatsSegue";

@interface INSOGameDetailViewController ()
// IBOutlets
@property (nonatomic, weak) IBOutlet UILabel* gameDateTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel* homeTeamLabel;
@property (nonatomic, weak) IBOutlet UILabel* homeScoreLabel;
@property (nonatomic, weak) IBOutlet UILabel* visitingTeamLabel;
@property (nonatomic, weak) IBOutlet UILabel* visitingScoreLabel;
@property (nonatomic, weak) IBOutlet UILabel* locationLabel;

@property (nonatomic, weak) IBOutlet UITableView* statsTableView;

// IBActions

// Private Properties

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


@end
