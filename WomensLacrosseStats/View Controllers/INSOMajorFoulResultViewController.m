//
//  INSOMajorFoulResultViewController.m
//  LacrosseStats
//
//  Created by James Dabrowski on 2/25/16.
//  Copyright © 2016 Intangible Software. All rights reserved.
//

#import "INSOMajorFoulResultViewController.h"

static NSString * const INSO8mShotResultSegueIdentifier = @"8mShotResultSegue";

@interface INSOMajorFoulResultViewController ()

// IBOutlets
@property (nonatomic, weak) IBOutlet UISwitch *freePositionAwardedSwitch;
@property (nonatomic, weak) IBOutlet UIView *freePositionShotTakenView;
@property (nonatomic, weak) IBOutlet UISwitch *freePositionShotTakenSwitch;
@property (nonatomic, weak) IBOutlet UIButton *shotResultButton;

// IBActions
- (IBAction)done:(id)sender;
- (IBAction)toggleFreePositionAwarded:(id)sender;
- (IBAction)toggleFreePositionShotTaken:(id)sender;

@end

@implementation INSOMajorFoulResultViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.freePositionShotTakenView.alpha = 0.0;
    self.shotResultButton.alpha = 0.0;
    self.shotResultButton.enabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions
- (void)done:(id)sender
{
    
}

- (void)toggleFreePositionAwarded:(id)sender
{
    // Turn off the shot taken switch
    if (!self.freePositionAwardedSwitch.isOn) {
        [self turnOffFreePositionShotSwitch];
    }
    
    // Then fade things appropriately
    CGFloat shotViewAlpha = self.freePositionAwardedSwitch.isOn ? 1.0 : 0.0;
    [UIView animateWithDuration:0.3 animations:^{
        self.freePositionShotTakenView.alpha = shotViewAlpha;
    }];
}

- (void)toggleFreePositionShotTaken:(id)sender
{
    self.shotResultButton.enabled = self.freePositionShotTakenSwitch.isOn;
    
    CGFloat shotResultButtonAlpha = self.freePositionShotTakenSwitch.isOn ? 1.0 : 0.0;
    [UIView animateWithDuration:0.3 animations:^{
        self.shotResultButton.alpha = shotResultButtonAlpha;
    }]; 
}

#pragma mark - Private methods
- (void)turnOffFreePositionShotSwitch
{
    if (self.freePositionShotTakenSwitch.isOn) {
        [self.freePositionShotTakenSwitch setOn:NO animated:YES];
        [UIView animateWithDuration:0.3 animations:^{
            self.shotResultButton.alpha = 0.0;
        }];
    }
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:INSO8mShotResultSegueIdentifier]) {
        [self prepareFor8mShotResultSegue:segue sender:sender];
    }
}

- (void)prepareFor8mShotResultSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"moo!");
}

@end
