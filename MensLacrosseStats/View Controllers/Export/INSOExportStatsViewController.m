//
//  INSOExportStatsViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 11/25/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "INSOExportStatsViewController.h"
#import "INSOEmailStatsViewController.h"
#import "MensLacrosseStatsAppDelegate.h"
#import "INSOReceiptValidator.h"

static NSString * const INSOEmailStatsSegueIdentifier = @"EmailStatsSegue";
static NSString * const INSOMaxPrepsExportSegueIdentifier = @"MaxPrepsSegue";

static const CGFloat INSODefaultButtonHeight = 50.0;

@interface INSOExportStatsViewController ()
// IBOutlets
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *purchaseButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* purchaseButtonHeightConstraint;

@property (weak, nonatomic) IBOutlet UILabel *restorePurchaseLabel;
@property (weak, nonatomic) IBOutlet UIButton *restorePurchaseButton;

@property (nonatomic, weak) IBOutlet UIButton* emailButton;
@property (nonatomic, weak) IBOutlet UIButton* maxPrepsButton;

// IBActions
- (IBAction)done:(id)sender;
- (IBAction)purchaseApp:(id)sender;
- (IBAction)restorePurchase:(id)sender;

- (NSString*)localizedAppNotPurchasedMessage;
- (NSString*)localizedAppPurchaseExpiredMessage;
- (NSString*)localizedAppPurchasedMessage;

@end

@implementation INSOExportStatsViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.receiptValidator.appIsPurchased) {
        [self configureViewForAppPurchased];
    } else {
        [self configureViewForAppNotPurchased];
    }
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

- (IBAction)purchaseApp:(id)sender
{

}

- (IBAction)restorePurchase:(id)sender
{
    // Just going to revalidate receipt for now
    // Which actually just generates random shit.
    MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate.receiptValidator validateReceipt];
    
    // Re-configure the view to match.
    if (appDelegate.receiptValidator.appIsPurchased) {
        [self configureViewForAppPurchased];
    } else {
        [self configureViewForAppNotPurchased];
    }
}

#pragma mark - Private Methods
#pragma mark - Navigation
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

#pragma mark - Other
- (void)configureViewForAppNotPurchased
{
    // Start with the message
    NSString* messageString = [NSString stringWithFormat:[self localizedAppNotPurchasedMessage], @"$4.99", @"1 year"];
    self.messageLabel.text = messageString;
    
    // And the buy now button
    NSString* purchaseButtonString = NSLocalizedString(@"Purchase 1 year of access for $4.99", nil);
    [self.purchaseButton setTitle:purchaseButtonString forState:UIControlStateNormal];
    self.purchaseButtonHeightConstraint.constant = INSODefaultButtonHeight;
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
        self.purchaseButton.alpha = 1.0; 
    }];
    
    // Disable exporting buttons
    self.emailButton.enabled = NO;
    self.maxPrepsButton.enabled = NO;
}

- (void)configureViewForAppPurchased
{
    // App has been purchased, but might be expired
    MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.receiptValidator.appPurchaseExpired) {
        [self configureViewForAppPurchaseExpired];
    } else {
        [self configureViewForAppPurchaseActive];
    }
    
}

- (void)configureViewForAppPurchaseExpired
{
    MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    NSDate* appExpirationDate = appDelegate.receiptValidator.appExpirationDate;
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    
    // Start with the message
    NSString* messageString = [NSString stringWithFormat:[self localizedAppPurchaseExpiredMessage], [formatter stringFromDate:appExpirationDate], @"1 year", @"$4.99"];
    self.messageLabel.text = messageString;
    
    // And the buy now button.
    NSString* purchaseButtonString = NSLocalizedString(@"Purchase 1 year of access for $4.99", nil);
    [self.purchaseButton setTitle:purchaseButtonString forState:UIControlStateNormal];
    self.purchaseButtonHeightConstraint.constant = INSODefaultButtonHeight;
    [UIView animateWithDuration:0.3 animations:^{
        [self.view updateConstraints];
        self.purchaseButton.alpha = 1.0;
    }];

    // Disable export buttons.
    self.emailButton.enabled = NO;
    self.maxPrepsButton.enabled = NO;
}

- (void)configureViewForAppPurchaseActive
{
    MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    NSDate* appExpirationDate = appDelegate.receiptValidator.appExpirationDate;
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];

    // Start with the message
    NSString* messageString = [NSString stringWithFormat:[self localizedAppPurchasedMessage], [formatter stringFromDate:appExpirationDate]];
    self.messageLabel.text = messageString;
    
    // Hide/remove the purchase button?
    self.purchaseButtonHeightConstraint.constant = 0.0;
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
        self.purchaseButton.alpha = 0.0;
    }];
    
    // And the restore purchase stuff?
    //self.restorePurchaseButton.enabled = NO;
    //self.restorePurchaseLabel.enabled = NO;
    
    // Export
    self.emailButton.enabled = YES;
    self.maxPrepsButton.enabled = YES;
}

- (NSString*)localizedAppNotPurchasedMessage
{
    return NSLocalizedString(@"Exporting stats is available with a %@ in-app purchase. Your purchase will enable adding games and exporting stats for %@.", nil);
}

- (NSString*)localizedAppPurchaseExpiredMessage
{
    return NSLocalizedString(@"Your purchase of Men’s Lacrosse Stats expired on %@. Tap the button below to purchase %@ of access for %@.", nil);
}

- (NSString*)localizedAppPurchasedMessage
{
    return NSLocalizedString(@"Thank you for purchasing full access to Men’s Lacrosse Stats. You have access to all features of the app until %@.", nil);
}

@end
