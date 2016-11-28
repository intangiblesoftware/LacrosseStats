//
//  INSOPurchaseViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 12/13/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

@import StoreKit;

#import "INSOProductManager.h"

#import "INSOPurchaseViewController.h"
#import "INSOExportOptionsTableViewController.h"
#import "INSOEmailStatsViewController.h"

static NSString * const INSOEmailStatsSegueIdentifier = @"EmailStatsSegue";
static NSString * const INSOMaxPrepsExportSegueIdentifier = @"MaxPrepsSegue";
static NSString * const INSOEmbededExportTableSegueIdentifier = @"EmbededExportTableSegue";

static const CGFloat INSODefaultAnimationDuration = 0.25;

@interface INSOPurchaseViewController () <UINavigationBarDelegate, INSOStatsExportDelegate, INSOProductManagerDelegate>

// IBOutlets
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *purchaseButton;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* activityIndicator;

@property (weak, nonatomic) IBOutlet UILabel *restorePurchaseLabel;
@property (weak, nonatomic) IBOutlet UIButton *restorePurchaseButton;

@property (weak, nonatomic) IBOutlet UIView* embededExportOptionsView;

// IBActions
- (IBAction)done:(id)sender;
- (IBAction)purchase:(id)sender;
- (IBAction)restorePurchase:(id)sender;

// Private properties

// Private methods
- (NSString*)localizedAppNotPurchasedMessage;
- (NSString*)localizedAppPurchaseExpiredMessage;
- (NSString*)localizedAppPurchasedMessage;

@end

@implementation INSOPurchaseViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Become the product purchase delegate
    [INSOProductManager sharedManager].delegate = self;
    [[INSOProductManager sharedManager] refreshProduct];

    [self configureView];
}

- (void)dealloc
{
    // Just being safe.
    [INSOProductManager sharedManager].delegate = nil;
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

- (void)purchase:(id)sender
{
    // Set up the UI for purchasing
    [self.activityIndicator startAnimating];
    self.purchaseButton.enabled = NO;
    
    // Now purchase
    [[INSOProductManager sharedManager] purchaseProduct];
}

- (void)restorePurchase:(id)sender
{
    // Set up the UI as if for purchasing
    [self.activityIndicator startAnimating];
    self.purchaseButton.enabled = NO;
    
    // And restore.
    [[INSOProductManager sharedManager] restorePurchase];
}

#pragma mark - Private methods
- (NSString*)localizedAppNotPurchasedMessage
{
    return NSLocalizedString(@"Adding additional games and exporting stats is available through a %@ in-app purchase. Your purchase will enable these features for %@. ", nil);
}

- (NSString*)localizedAppPurchaseExpiredMessage
{
    return NSLocalizedString(@"Your purchase of %@ expired on %@. Tap the button below to purchase %@ of access for %@.", nil);
}

- (NSString*)localizedAppPurchasedMessage
{
    return NSLocalizedString(@"Thank you for purchasing full access to %@. All features of the app are enabled until %@.", nil);
}

- (NSString*)localizedPurchaseButtonTitle
{
    return NSLocalizedString(@"Purchase %@ of access for %@", nil);
}

- (NSString*)localizedProductPriceString
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    return [numberFormatter stringFromNumber:[[INSOProductManager sharedManager] productPrice]];
}

- (void)configureView
{
    // Re-configure the view to match.
    if ([[INSOProductManager sharedManager] canPurchaseProduct]) {
        if ([[INSOProductManager sharedManager] productIsPurchased]) {
            if ([[INSOProductManager sharedManager] productPurchaseExpired]) {
                [self configureViewForAppPurchaseExpired];
            } else {
                [self configureViewForAppPurchaseActive];
            }
        } else {
            [self configureViewForAppNotPurchased];
        }
    } else {
        [self configureViewForStoreUnavailable];
    }
}

- (void)configureViewForAppNotPurchased
{
    // Start with the message
    NSString* messageString = [NSString stringWithFormat:[self localizedAppNotPurchasedMessage], [self localizedProductPriceString], [[INSOProductManager sharedManager] productTitle]];
    
    // And the buy now button
    NSString* purchaseButtonString = [NSString stringWithFormat:[[self localizedPurchaseButtonTitle] capitalizedString], [[[INSOProductManager sharedManager] productTitle] capitalizedString], [self localizedProductPriceString]];
    
    [self.activityIndicator stopAnimating];

    [UIView animateWithDuration:INSODefaultAnimationDuration animations:^{
        self.messageLabel.text = messageString;

        [self.purchaseButton setTitle:purchaseButtonString forState:UIControlStateNormal];
        [self.restorePurchaseButton setTitle:NSLocalizedString(@"Restore Purchase", nil) forState:UIControlStateNormal];

        self.purchaseButton.hidden = NO;
        self.purchaseButton.enabled = YES;
        self.restorePurchaseLabel.hidden = NO;
        self.restorePurchaseButton.hidden = NO;

        self.embededExportOptionsView.alpha = 0.5;
        self.embededExportOptionsView.userInteractionEnabled = NO;
    }];
}

- (void)configureViewForAppPurchaseExpired
{
    NSDate* appExpirationDate = [[INSOProductManager sharedManager] productExpirationDate];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    
    // Start with the message
    NSString* messageString = [NSString stringWithFormat:[self localizedAppPurchaseExpiredMessage], [[INSOProductManager sharedManager] appProductName], [formatter stringFromDate:appExpirationDate], [[INSOProductManager sharedManager] productTitle], [self localizedProductPriceString]];
    
    // And the buy now button.
    NSString* purchaseButtonString = [NSString stringWithFormat:[[self localizedPurchaseButtonTitle] capitalizedString], [[[INSOProductManager sharedManager] productTitle] capitalizedString], [self localizedProductPriceString]];
    
    [self.activityIndicator stopAnimating];

    [UIView animateWithDuration:INSODefaultAnimationDuration animations:^{
        self.messageLabel.text = messageString;

        [self.purchaseButton setTitle:purchaseButtonString forState:UIControlStateNormal];
        [self.restorePurchaseButton setTitle:NSLocalizedString(@"Restore Purchase", nil) forState:UIControlStateNormal];
        
        self.purchaseButton.hidden = NO;
        self.purchaseButton.enabled = YES;
        self.restorePurchaseLabel.hidden = NO;
        self.restorePurchaseButton.hidden = NO;

        self.embededExportOptionsView.alpha = 0.5;
        self.embededExportOptionsView.userInteractionEnabled = NO;
    }];
}

- (void)configureViewForAppPurchaseActive
{
    NSDate* appExpirationDate = [[INSOProductManager sharedManager] productExpirationDate];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    
    // Start with the message
    NSString* messageString = [NSString stringWithFormat:[self localizedAppPurchasedMessage], [[INSOProductManager sharedManager] appProductName], [formatter stringFromDate:appExpirationDate]];
    
    [self.activityIndicator stopAnimating];

    [UIView animateWithDuration:INSODefaultAnimationDuration animations:^{
        self.messageLabel.text = messageString;

        [self.purchaseButton setTitle:@"" forState:UIControlStateNormal];
        [self.restorePurchaseButton setTitle:@"" forState:UIControlStateNormal];
        
        self.purchaseButton.hidden = YES;
        self.restorePurchaseLabel.hidden = YES;
        self.restorePurchaseButton.hidden = YES;

        self.embededExportOptionsView.alpha = 1.0;
        self.embededExportOptionsView.userInteractionEnabled = YES;
    }];
}

- (void)configureViewForStoreUnavailable
{
    [self.activityIndicator stopAnimating];
    
    [UIView animateWithDuration:INSODefaultAnimationDuration animations:^{
        self.messageLabel.text = NSLocalizedString(@"Unable to connect with the App Store. This may be because this device is not connected to the internet or because the App Store is currently unavailable.", nil);
        [self.purchaseButton setTitle:@"" forState:UIControlStateNormal];
        [self.restorePurchaseButton setTitle:@"" forState:UIControlStateNormal];
        
        self.purchaseButton.hidden = YES;
        self.restorePurchaseLabel.hidden = YES;
        self.restorePurchaseButton.hidden = YES;
        
        self.embededExportOptionsView.alpha = 0.5;
        self.embededExportOptionsView.userInteractionEnabled = NO;
    }];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:INSOEmbededExportTableSegueIdentifier]) {
        INSOExportOptionsTableViewController* dest = segue.destinationViewController;
        dest.delegate = self;
    }
    
    if ([segue.identifier isEqualToString:INSOEmailStatsSegueIdentifier]) {
        INSOEmailStatsViewController* dest = segue.destinationViewController;
        dest.game = self.game;
    }
    
    if ([segue.identifier isEqualToString:INSOMaxPrepsExportSegueIdentifier]) {
        INSOEmailStatsViewController* dest = segue.destinationViewController;
        dest.game = self.game;
    }
}

#pragma mark - UINavigationBarDelegate
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - INSOProductPurchaseDelegate
- (void)didRefreshProduct
{
    [self configureView]; 
}

- (void)didPurchaseProduct
{
    [self configureView];
}

- (void)productPurchaseFailed
{
    [self configureView];
}

- (void)didRestorePurchase
{
    [self configureView];
}

#pragma mark - INSOExportDelegate
- (void)didSelectEmailStats
{
    [self performSegueWithIdentifier:INSOEmailStatsSegueIdentifier sender:self];
}

- (void)didSelectMaxPrepsExport
{
    [self performSegueWithIdentifier:INSOMaxPrepsExportSegueIdentifier sender:self]; 
}

@end
