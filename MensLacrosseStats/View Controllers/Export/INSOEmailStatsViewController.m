//
//  INSOEmailStatsViewController.m
//  MensLacrosseStats
//
//  Created by James Dabrowski on 11/25/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

@import MessageUI;

#import "UIColor+INSOScorebookColor.h"

#import "INSOEmailStatsViewController.h"
#import "INSOEmailStatsFileGenerator.h"
#import "INSOProductManager.h"
#import "INSOMensLacrosseStatsConstants.h"

#import "Game.h"

@interface INSOEmailStatsViewController () <UITableViewDataSource, UITabBarDelegate, MFMailComposeViewControllerDelegate>
// IBOutlets
@property (weak, nonatomic) IBOutlet UISwitch *gameSummarySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *playerStatsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *maxPrepsSwitch; 

@property (weak, nonatomic) IBOutlet UILabel *instructionLabel; 
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (weak, nonatomic) IBOutlet UIButton *exportStatsButton;

// IBActions
- (IBAction)done:(id)sender;
- (IBAction)toggledSwitch:(id)sender;
- (IBAction)exportStats:(id)sender;

@property (nonatomic, assign) BOOL isPreparingForBoys;

@property (nonatomic) NSData *maxPrepsAttachmentData;
@property (nonatomic) NSData *playerStatsAttachmentData;
@property (nonatomic) NSData *gameSummaryAttachmentData;

@end

@implementation INSOEmailStatsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.alwaysBounceVertical = NO;
    
// FIXME Which product are we exporting for?
    // Are we sending boys or girls stats?
//    if ([[[INSOProductManager sharedManager] appProductName] isEqualToString:INSOMensProductName]) {
        self.isPreparingForBoys = YES;
//    } else {
//        self.isPreparingForBoys = NO;
//    }
    
    [self.gameSummarySwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:INSOExportGameSummaryDefaultKey]];
    [self.playerStatsSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:INSOExportPlayerStatsDefaultKey]];
    [self.maxPrepsSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:INSOExportMaxPrepsDefaultKey]];
    
    self.exportStatsButton.enabled = [self shouldEnableExportStatsButton];
    
    self.messageLabel.text = nil;

    if (![MFMailComposeViewController canSendMail]) {
        // Can't send email so disable UI and put up a message
        [self disableUI];
        [self.activityIndicator stopAnimating];
        self.messageLabel.text = @"Unable to export stats via email. Check your mail settings and try again.";
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions
- (void)done:(id)sender
{
    // Just dismiss
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)toggledSwitch:(id)sender
{
    self.exportStatsButton.enabled = [self shouldEnableExportStatsButton];
    
    [[NSUserDefaults standardUserDefaults] setBool:self.gameSummarySwitch.isOn forKey:INSOExportGameSummaryDefaultKey];
    [[NSUserDefaults standardUserDefaults] setBool:self.playerStatsSwitch.isOn forKey:INSOExportPlayerStatsDefaultKey];
    [[NSUserDefaults standardUserDefaults] setBool:self.maxPrepsSwitch.isOn forKey:INSOExportMaxPrepsDefaultKey];
}

- (void)exportStats:(id)sender
{
    // Freeze the UI
    [self disableUI];
    
    // Prepare the stats file(s)
    INSOEmailStatsFileGenerator* fileGenerator = [[INSOEmailStatsFileGenerator alloc] initWithGame:self.game];
    
    if (self.maxPrepsSwitch.isOn) {
        // Boys or girls?
        if (self.isPreparingForBoys) {
            [fileGenerator createMaxPrepsGameStatsData:^(NSData *maxPrepsData) {
                self.maxPrepsAttachmentData = maxPrepsData;
            }];
        } else {
            [fileGenerator createMaxPrepsGameStatsData:^(NSData *maxPrepsData) {
                self.maxPrepsAttachmentData = maxPrepsData;
            }];
        }
    }
    
    if (self.gameSummarySwitch.isOn) {
        [fileGenerator createGameSummaryData:^(NSData *gameSummaryData) {
            self.gameSummaryAttachmentData = gameSummaryData;
        }];
    }
    
    if (self.playerStatsSwitch.isOn) {
        [fileGenerator createPlayerStatsData:^(NSData *playerStatsData) {
            self.playerStatsAttachmentData = playerStatsData;
        }];
    }
    
    // Send the email
    [self actuallySendEmail];
}

#pragma mark - Private Methods
- (void)disableUI {
    self.gameSummarySwitch.enabled = NO;
    self.playerStatsSwitch.enabled = NO;
    self.maxPrepsSwitch.enabled = NO;
    self.exportStatsButton.enabled = NO;
    [self.activityIndicator startAnimating];
}

- (void)enableUI {
    self.gameSummarySwitch.enabled = YES;
    self.playerStatsSwitch.enabled = YES;
    self.maxPrepsSwitch.enabled = YES;
    self.exportStatsButton.enabled = YES;
    [self.activityIndicator stopAnimating];
}

- (BOOL)shouldEnableExportStatsButton
{
    return [MFMailComposeViewController canSendMail] && (self.gameSummarySwitch.isOn || self.playerStatsSwitch.isOn || self.maxPrepsSwitch.isOn);
}

- (void)actuallySendEmail
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* mailViewcontroller = [[MFMailComposeViewController alloc] init];
        mailViewcontroller.mailComposeDelegate = self;
        
        // Get subject
        NSString* subject = [self mailMessageSubject];
        
        // Get body
        NSString* body = [self mailMessageBody];
        
         // Now set these things
        [mailViewcontroller setSubject:subject];
        [mailViewcontroller setMessageBody:body isHTML:NO];
        
        // Add attachment(s)
        if (self.maxPrepsAttachmentData) {
            NSString* fileName = NSLocalizedString(@"MaxPreps Export.txt", nil);
            [mailViewcontroller addAttachmentData:self.maxPrepsAttachmentData mimeType:@"text/txt" fileName:fileName];
        }
        
        if (self.gameSummaryAttachmentData) {
            NSString* fileName = NSLocalizedString(@"Game Summary.pdf", nil);
            [mailViewcontroller addAttachmentData:self.gameSummaryAttachmentData mimeType:@"application/pdf" fileName:fileName];
        }
        
        if (self.playerStatsAttachmentData) {
            NSString* fileName = NSLocalizedString(@"Player Stats.csv", nil);
            [mailViewcontroller addAttachmentData:self.playerStatsAttachmentData mimeType:@"text/csv" fileName:fileName];
        }

        if (self.isPreparingForBoys) {
            [mailViewcontroller.navigationBar setTintColor:[UIColor scorebookBlue]];
        } else {
            [mailViewcontroller.navigationBar setTintColor:[UIColor scorebookTeal]];
        }
        
        // Display the view to mail the message.
        [self presentViewController:mailViewcontroller animated:YES completion:^{
            // Re-enable the UI so that when the user dismisses the mail view,
            // the UI is ready to re-use.
            [self enableUI];
        }];
        
    } else {
        // unable to send mail. Hmmm;
        NSLog(@"Error - Unable to send email. Should never have gotten here.");
    }
}

- (NSString*)mailMessageSubject
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    NSString* localizedSubjectString = NSLocalizedString(@"Lacrosse Stats export for %@ vs. %@ on %@", nil);
    NSString* subject = [NSString stringWithFormat:localizedSubjectString, self.game.visitingTeam, self.game.homeTeam, [dateFormatter stringFromDate:self.game.gameDateTime]];
    
    return subject;
}

- (NSString*)mailMessageBody
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    NSString* localizedMessageString = NSLocalizedString(@"Stats files for %@ vs. %@ on %@ at %@.\n\n", nil);
    NSString* messageBody = [NSString stringWithFormat:localizedMessageString, self.game.visitingTeam, self.game.homeTeam, [dateFormatter stringFromDate:self.game.gameDateTime], self.game.location];
    NSMutableString *mutableMessageBody = [[NSMutableString alloc] initWithString:messageBody];
    
    int fileCount = self.gameSummarySwitch.isOn;
    fileCount += self.playerStatsSwitch.isOn;
    fileCount += self.maxPrepsSwitch.isOn;
    
    if (fileCount == 1) {
        [mutableMessageBody appendString:NSLocalizedString(@"The following file is attached:\n", nil)];
    } else {
        [mutableMessageBody appendString:NSLocalizedString(@"The following files are attached:\n", nil)];
    }
    
    if (self.gameSummarySwitch.isOn) {
        [mutableMessageBody appendString:NSLocalizedString(@"Game Summary", nil)];
        [mutableMessageBody appendString:@"\n"];
    }
    
    if (self.playerStatsSwitch.isOn) {
        [mutableMessageBody appendString:NSLocalizedString(@"Individual player stats", nil)];
        [mutableMessageBody appendString:@"\n"];
    }
    
    if (self.maxPrepsSwitch.isOn) {
        [mutableMessageBody appendString:NSLocalizedString(@"MaxPreps file", nil)];
        [mutableMessageBody appendString:@"\n"];
    }
    
    return mutableMessageBody;
}

#pragma mark - MFMailComposeControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result) {
        case MFMailComposeResultSent:
            // It would be nice if I could play a sound here.
            self.messageLabel.text = NSLocalizedString(@"Email sent.", nil);
            break;
        case MFMailComposeResultSaved:
            self.messageLabel.text = NSLocalizedString(@"Draft email saved.", nil);
            break;
        case MFMailComposeResultCancelled:
            self.messageLabel.text = NSLocalizedString(@"Email cancelled.", nil);
            break;
        case MFMailComposeResultFailed:
            self.messageLabel.text = NSLocalizedString(@"An error occurred when trying to compose this email.", nil);
            break;
        default:
            self.messageLabel.text = nil;
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
