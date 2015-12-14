//
//  INSOPurchaseViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 12/13/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "MensLacrosseStatsAppDelegate.h"

#import "INSOPurchaseViewController.h"
#import "INSOReceiptValidator.h"

@interface INSOPurchaseViewController () <UINavigationBarDelegate>

// IBOutlets
@property (nonatomic, weak) IBOutlet UILabel* messageLabel;

// IBActions
- (IBAction)cancel:(id)sender;
- (IBAction)purchase:(id)sender;
- (IBAction)restorePurchase:(id)sender;

// Private properties

// Private methods


@end

@implementation INSOPurchaseViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    MensLacrosseStatsAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.receiptValidator.appIsPurchased && appDelegate.receiptValidator.appPurchaseExpired) {
        [self configureViewForAppPurchaseExpired];
    } else {
        [self configureViewForAppNotPurchased];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions
- (void)cancel:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)purchase:(id)sender
{
    
}

- (void)restorePurchase:(id)sender
{
    
}

#pragma mark - Private methods
- (NSString*)localizedAppNotPurchasedMessage
{
    return NSLocalizedString(@"Adding additional games and the ability to export stats is available through a %@ in-app purchase. Your purchase will enable adding games and exporting stats for %@. ", nil);
}

- (NSString*)localizedAppPurchaseExpiredMessage
{
    return NSLocalizedString(@"Your purchase of Men’s Lacrosse Stats expired on %@. Tap the button below to purchase %@ of access for %@.", nil);
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
}

- (void)configureViewForAppNotPurchased
{
    // Start with the message
    NSString* messageString = [NSString stringWithFormat:[self localizedAppNotPurchasedMessage], @"$4.99", @"1 year"];
    self.messageLabel.text = messageString;
}

@end
