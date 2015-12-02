//
//  INSOExportStatsViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 11/25/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOExportStatsViewController.h"
#import "INSOEmailStatsViewController.h"

static NSString * const INSOEmailStatsSegueIdentifier = @"EmailStatsSegue";
static NSString * const INSOMaxPrepsExportSegueIdentifier = @"MaxPrepsSegue";


@interface INSOExportStatsViewController ()

- (IBAction)done:(id)sender;

@end

@implementation INSOExportStatsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions
- (void)done:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private Methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:INSOEmailStatsSegueIdentifier]) {
        [self prepareForEmailStatsSegue:segue sender:sender];
    }
    
    if ([segue.identifier isEqualToString:INSOMaxPrepsExportSegueIdentifier]) {
        [self prepareForMaxPrepsExportSegue:segue sender:sender]; 
    }
}

- (void)prepareForEmailStatsSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    INSOEmailStatsViewController* dest = segue.destinationViewController;
    dest.game = self.game;
    dest.isExportingForMaxPreps = NO;
}

- (void)prepareForMaxPrepsExportSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    INSOEmailStatsViewController* dest = segue.destinationViewController;
    dest.game = self.game;
    dest.isExportingForMaxPreps = YES; 
}

@end
