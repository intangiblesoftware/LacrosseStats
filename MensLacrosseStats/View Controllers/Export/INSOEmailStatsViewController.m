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

@interface INSOEmailStatsViewController () <MFMailComposeViewControllerDelegate>
// IBOutlets
@property (weak, nonatomic) IBOutlet UISwitch *gameSummarySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *playerStatsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *maxPrepsSwitch; 

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (weak, nonatomic) IBOutlet UIButton *exportStatsButton;

// IBActions
- (IBAction)cancel:(id)sender;
- (IBAction)toggledSwitch:(id)sender;
- (IBAction)prepareStatsFile:(id)sender;

@property (nonatomic, assign) BOOL isPreparingForBoys;

@end

@implementation INSOEmailStatsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.gameSummarySwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:INSOExportGameSummaryDefaultKey]];
    [self.playerStatsSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:INSOExportPlayerStatsDefaultKey]];
    [self.maxPrepsSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:INSOExportMaxPrepsDefaultKey]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions
- (void)cancel:(id)sender
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

- (void)prepareStatsFile:(id)sender
{
    // Freeze the UI
    [self disableUI];
    
    [self performSelector:@selector(enableUI) withObject:self afterDelay:3.0]; 
    
    
    /*
    // Now actually prepare the stats file
    INSOEmailStatsFileGenerator* fileGenerator = [[INSOEmailStatsFileGenerator alloc] initWithGame:self.game];
    if (self.maxPrepsSwitch.isOn) {
        // Boys or girls?
        if (self.isPreparingForBoys) {
            [fileGenerator createBoysMaxPrepsGameStatsFile:^(NSData *gameStatsData) {
                self.gameSummarySwitch.enabled = YES;
                self.playerStatsSwitch.enabled = YES;
                self.maxPrepsSwitch.enabled = YES;
                self.prepareStatsButton.enabled = YES;
                [self.activityIndicator stopAnimating];
                
//                [self prepareEmailMessageForMaxPrepsData:gameStatsData];
            }];
        } else {
            [fileGenerator createGirlsMaxPrepsGameStatsFile:^(NSData *gameStatsData) {
                self.gameSummarySwitch.enabled = YES;
                self.playerStatsSwitch.enabled = YES;
                self.maxPrepsSwitch.enabled = YES;
                self.prepareStatsButton.enabled = YES;
                [self.activityIndicator stopAnimating];
                
//                [self prepareEmailMessageForMaxPrepsData:gameStatsData];
            }];
        }
    }
    
    if (self.gameSummarySwitch.isOn) {
        if (self.isPreparingForBoys) {
            [fileGenerator createBoysMaxPrepsGameStatsFile:^(NSData *gameStatsData) {
                self.gameSummarySwitch.enabled = YES;
                self.playerStatsSwitch.enabled = YES;
                self.maxPrepsSwitch.enabled = YES;
                self.prepareStatsButton.enabled = YES;
                [self.activityIndicator stopAnimating];
                
            }];
        } else {
            [fileGenerator createGirlsMaxPrepsGameStatsFile:^(NSData *gameStatsData) {
                self.gameSummarySwitch.enabled = YES;
                self.playerStatsSwitch.enabled = YES;
                self.maxPrepsSwitch.enabled = YES;
                self.prepareStatsButton.enabled = YES;
                [self.activityIndicator stopAnimating];
                
            }];
        }
    }
    
    if (self.playerStatsSwitch.isOn) {
        if (self.isPreparingForBoys) {
            [fileGenerator createBoysMaxPrepsGameStatsFile:^(NSData *gameStatsData) {
                self.gameSummarySwitch.enabled = YES;
                self.playerStatsSwitch.enabled = YES;
                self.maxPrepsSwitch.enabled = YES;
                self.prepareStatsButton.enabled = YES;
                [self.activityIndicator stopAnimating];
                
            }];
        } else {
            [fileGenerator createGirlsMaxPrepsGameStatsFile:^(NSData *gameStatsData) {
                self.gameSummarySwitch.enabled = YES;
                self.playerStatsSwitch.enabled = YES;
                self.maxPrepsSwitch.enabled = YES;
                self.prepareStatsButton.enabled = YES;
                [self.activityIndicator stopAnimating];
                
            }];
        }
    }
     */
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
    return self.gameSummarySwitch.isOn || self.playerStatsSwitch.isOn || self.maxPrepsSwitch.isOn;
}

- (void)prepareEmailMessageForStatsData:(NSData*)statsData
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
        NSString* fileName = NSLocalizedString(@"GameStats.csv", nil);
        [mailViewcontroller addAttachmentData:statsData mimeType:@"text/csv" fileName:fileName];
        
        if (self.isPreparingForBoys) {
            [mailViewcontroller.navigationBar setTintColor:[UIColor scorebookBlue]];
        } else {
            [mailViewcontroller.navigationBar setTintColor:[UIColor scorebookTeal]];
        }
        
        // Display the view to mail the message.
        [self presentViewController:mailViewcontroller animated:YES completion:nil];
        
    } else {
        // unable to send mail. Hmmm;
        NSLog(@"Unable to send email.");
    }
}

- (void)prepareEmailMessageForMaxPrepsData:(NSData*)maxPrepsData
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* mailViewcontroller = [[MFMailComposeViewController alloc] init];
        mailViewcontroller.mailComposeDelegate = self;
        
        // Get subject
        NSString* subject = [self maxPrepsMessageSubject];
        
        // Get body
        NSString* body = [self maxPrepsMessageBody];
        
        // Now set these things
        [mailViewcontroller setSubject:subject];
        [mailViewcontroller setMessageBody:body isHTML:NO];
        
        // Add attachment(s)
        NSString* fileName = NSLocalizedString(@"MaxPrepsExport.txt", nil);
        [mailViewcontroller addAttachmentData:maxPrepsData mimeType:@"text/plain" fileName:fileName];
        
        if (self.isPreparingForBoys) {
            [mailViewcontroller.navigationBar setTintColor:[UIColor scorebookBlue]];
        } else {
            [mailViewcontroller.navigationBar setTintColor:[UIColor scorebookTeal]];
        }
        
        // Display the view to mail the message.
        [self presentViewController:mailViewcontroller animated:YES completion:nil];
        
    } else {
        // unable to send mail. Hmmm;
        NSLog(@"Unable to send email.");
    }
}

- (NSString*)mailMessageSubject
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    NSString* localizedSubjectString = NSLocalizedString(@"Game stats for %@ vs. %@ on %@", nil);
    NSString* subject = [NSString stringWithFormat:localizedSubjectString, self.game.visitingTeam, self.game.homeTeam, [dateFormatter stringFromDate:self.game.gameDateTime]];
    
    return subject;
}

- (NSString*)maxPrepsMessageSubject
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    NSString* localizedSubjectString = NSLocalizedString(@"MaxPreps Export for %@ vs. %@ on %@", nil);
    NSString* subject = [NSString stringWithFormat:localizedSubjectString, self.game.visitingTeam, self.game.homeTeam, [dateFormatter stringFromDate:self.game.gameDateTime]];
    
    return subject;
}

- (NSString*)mailMessageBody
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    NSString* localizedSubjectString = NSLocalizedString(@"Game stats for %@ vs. %@ on %@ at %@.\n", nil);
    NSString* subject = [NSString stringWithFormat:localizedSubjectString, self.game.visitingTeam, self.game.homeTeam, [dateFormatter stringFromDate:self.game.gameDateTime], self.game.location];
    
    return subject;
}

- (NSString*)maxPrepsMessageBody
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    NSString* localizedSubjectString = NSLocalizedString(@"MaxPreps file export for %@ vs. %@ on %@ at %@.\n", nil);
    NSString* subject = [NSString stringWithFormat:localizedSubjectString, self.game.visitingTeam, self.game.homeTeam, [dateFormatter stringFromDate:self.game.gameDateTime], self.game.location];
    
    return subject;
}

#pragma mark - MFMailComposeControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result) {
        case MFMailComposeResultSent:
            NSLog(@"You sent the email.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"You saved a draft of this email");
            break;
        case MFMailComposeResultCancelled:
            NSLog(@"You cancelled sending this email.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed:  An error occurred when trying to compose this email");
            break;
        default:
            NSLog(@"An error occurred when trying to compose this email");
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
