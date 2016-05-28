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
@property (weak, nonatomic) IBOutlet UILabel *exportToggleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *exportToggleSwitch;

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (weak, nonatomic) IBOutlet UIButton *prepareStatsButton;

// IBActions
- (IBAction)toggleExport:(id)sender;
- (IBAction)prepareStatsFile:(id)sender;

@property (nonatomic, assign) BOOL isPreparingForBoys;

@end

@implementation INSOEmailStatsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[[INSOProductManager sharedManager] appProductName] isEqualToString:@"Men’s Lacrosse Stats"]) {
        self.isPreparingForBoys = YES;
    } else {
        self.isPreparingForBoys = NO;
    }
    
    if (self.isExportingForMaxPreps) {
        self.title = NSLocalizedString(@"MaxPreps Export", nil) ;
        [self.exportToggleLabel removeFromSuperview];
        [self.exportToggleSwitch removeFromSuperview];
        self.messageLabel.text = NSLocalizedString(@"The app will export all stats collected in a format compatible for sending to MaxPreps.", nil);
        self.messageLabel.font = [UIFont systemFontOfSize:17.0];
        [self.prepareStatsButton setTitle:NSLocalizedString(@"Prepare MaxPreps File", nil) forState:UIControlStateNormal]; 
    } else {
        self.title = NSLocalizedString(@"Email Export", nil) ;
        [self.prepareStatsButton setTitle:NSLocalizedString(@"Prepare .CSV File", nil) forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions
- (void)toggleExport:(id)sender
{
    if (self.exportToggleSwitch.isOn) {
        self.messageLabel.text = NSLocalizedString(@"The app will export only those stats collected for this game.", nil);
    } else {
        self.messageLabel.text = NSLocalizedString(@"The app will export all available stats whether specifically collected or not.", nil);
    }
}

- (void)prepareStatsFile:(id)sender
{
    // Freeze the UI
    self.exportToggleSwitch.enabled = NO;
    self.prepareStatsButton.enabled = NO;
    [self.activityIndicator startAnimating];
    
    // Now actually prepare the stats file
    INSOEmailStatsFileGenerator* fileGenerator = [[INSOEmailStatsFileGenerator alloc] initWithGame:self.game];
    if (self.isExportingForMaxPreps) {
        // Boys or girls?
        if (self.isPreparingForBoys) {
            [fileGenerator createBoysMaxPrepsGameStatsFile:^(NSData *gameStatsData) {
                self.prepareStatsButton.enabled = YES;
                [self.activityIndicator stopAnimating];
                
                [self prepareEmailMessageForMaxPrepsData:gameStatsData];
            }];
        } else {
            [fileGenerator createGirlsMaxPrepsGameStatsFile:^(NSData *gameStatsData) {
                self.prepareStatsButton.enabled = YES;
                [self.activityIndicator stopAnimating];
                
                [self prepareEmailMessageForMaxPrepsData:gameStatsData];
            }];
        }
    } else {
        // Not exporting for max preps so configure differently
        if (self.exportToggleSwitch.isOn) {
            [fileGenerator createGameStatsDataFileForRecordedStats:^(NSData *gameStatsData) {
                self.exportToggleSwitch.enabled = YES;
                self.prepareStatsButton.enabled = YES;
                [self.activityIndicator stopAnimating];
                
                [self prepareEmailMessageForStatsData:gameStatsData];
            }];
        } else {
            [fileGenerator createGameStatsDataFileForAllStats:^(NSData *gameStatsData) {
                self.exportToggleSwitch.enabled = YES;
                self.prepareStatsButton.enabled = YES;
                [self.activityIndicator stopAnimating];
                
                [self prepareEmailMessageForStatsData:gameStatsData];
            }];
        }
    }
}

#pragma mark - Private Methods
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
