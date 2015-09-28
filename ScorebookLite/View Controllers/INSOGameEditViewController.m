//
//  INSOGameEditViewController.m
//  ScorebookLite
//
//  Created by James Dabrowski on 9/26/15.
//  Copyright © 2015 Intangible Software. All rights reserved.
//

#import "UIColor+INSOScorebookColor.h"

#import "AppDelegate.h"

#import "INSOGameEditViewController.h"

#import "Game.h"

@interface INSOGameEditViewController () <UINavigationBarDelegate, UITextFieldDelegate>
// IBOutlet
@property (nonatomic, weak) IBOutlet UIBarButtonItem* cancelButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem* doneButton;

@property (nonatomic, weak) IBOutlet UITextField* gameDateTimeField;
@property (nonatomic, weak) IBOutlet UITextField* homeTeamField;
@property (nonatomic, weak) IBOutlet UITextField* visitingTeamField;
@property (nonatomic, weak) IBOutlet UITextField* locationField;

@property (nonatomic, weak) IBOutlet UISegmentedControl* playerStatSegmentedControl;

@property (nonatomic, weak) IBOutlet UICollectionView* playerStatCollectionView; 

// IBActions
- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

// Private Properties
@property (nonatomic) UIToolbar* datePickerToolbar;
@property (nonatomic) UIDatePicker* datePicker;
@property (nonatomic) NSManagedObjectContext* managedObjectContext;

// Private Methods
- (void)configureView;
- (BOOL)shouldEnableDoneButton;
- (void)dateChanged;
- (void)doneSettingDate;

- (NSString*)gameDateAsString;


@end

@implementation INSOGameEditViewController
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureView]; 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions
- (void)cancel:(id)sender
{
    // Discard any changes that may have been made.
    if ([self.game hasChanges]) {
        [self.managedObjectContext rollback];
    }
    
    // And go away.
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)done:(id)sender
{
    // Just save the changes that have already been made.
    NSError* error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving changes to game: %@", error.localizedDescription);
    }

    // Now dismiss
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private Properties
- (UIToolbar*)datePickerToolbar
{
    if (!_datePickerToolbar) {
        _datePickerToolbar = [[UIToolbar alloc] init];
        
        UIBarButtonItem* spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneSettingDate)];
        
        _datePickerToolbar.items = @[spacer, doneButton];
        _datePickerToolbar.tintColor = [UIColor scorebookBlue];
        [_datePickerToolbar sizeToFit];
    }
    return _datePickerToolbar;
}
- (UIDatePicker*)datePicker
{
    if (!_datePicker) {
        _datePicker = [[UIDatePicker alloc] init];
        _datePicker.datePickerMode = UIDatePickerModeDateAndTime;
        _datePicker.minuteInterval = 15;
        _datePicker.date = self.game.gameDateTime;
        [_datePicker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];
    }
    return _datePicker;
}

- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

#pragma mark - Private Methods
- (void)configureView
{
    self.gameDateTimeField.text = [self gameDateAsString];
    self.gameDateTimeField.inputView = self.datePicker;
    self.gameDateTimeField.inputAccessoryView = self.datePickerToolbar;
    
    self.homeTeamField.text = self.game.homeTeam;
    self.visitingTeamField.text = self.game.visitingTeam;
    self.locationField.text = self.game.location;
    
    self.doneButton.enabled = [self shouldEnableDoneButton]; 
}

- (BOOL)shouldEnableDoneButton
{
    NSString* homeString = [self.homeTeamField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString* visitingString = [self.visitingTeamField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    return ([homeString length] > 0) && ([visitingString length] > 0);
}

- (void)dateChanged
{
    // Update the label and the game
    self.game.gameDateTime = self.datePicker.date;
    self.gameDateTimeField.text = [self gameDateAsString];
}

- (NSString*)gameDateAsString
{
    NSString* dateFormat = [NSDateFormatter dateFormatFromTemplate:@"Mdyy" options:0 locale:[NSLocale currentLocale]];
    NSString* timeFormat = [NSDateFormatter dateFormatFromTemplate:@"hmma" options:0 locale:[NSLocale currentLocale]];
    NSString* dateTimeFormat = [NSString stringWithFormat:@"%@' at '%@", dateFormat, timeFormat];
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateTimeFormat];
    return [formatter stringFromDate:self.game.gameDateTime];
}

- (void)doneSettingDate
{
    [self.homeTeamField becomeFirstResponder]; 
}

#pragma mark - Delegate Methods
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached; 
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField endEditing:YES];
    
    self.doneButton.enabled = [self shouldEnableDoneButton];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([textField isEqual:self.gameDateTimeField]) {
        // Set in object when picker changed.
        [self.homeTeamField becomeFirstResponder];
    } else if ([textField isEqual:self.homeTeamField]) {
        self.game.homeTeam = [self.homeTeamField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.visitingTeamField becomeFirstResponder];
    } else if ([textField isEqual:self.visitingTeamField]) {
        self.game.visitingTeam = [self.visitingTeamField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.locationField becomeFirstResponder];
    } else if ([textField isEqual:self.locationField]) {
        self.game.location = [self.locationField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [textField resignFirstResponder];
    }
}


@end
