//
//  INSOPenaltyTimeViewController.m
//  Scorebook
//
//  Created by Jim Dabrowski on 3/18/15.
//  Copyright (c) 2015 IntangibleSoftware. All rights reserved.
//

#import "MensLacrosseStatsAppDelegate.h"
#import "INSOMensLacrosseStatsEnum.h"

#import "INSOPenaltyTimeViewController.h"

#import "Game.h"
#import "RosterPlayer.h"
#import "Event.h"
#import "EventCategory.h"
#import "GameEvent.h"

typedef NS_ENUM(NSUInteger, StackPosition) {
    digitsPosition,
    tensPosition,
    minutesPosition,
};

static NSString * const INSODoneAddingEventSegueIdentifier = @"DoneAddingEventSegue";

@interface INSOPenaltyTimeViewController ()

// IBOutlets
@property (nonatomic, weak) IBOutlet UILabel*  penaltyTimeLabel;

@property (nonatomic, weak) IBOutlet UIButton* oneButton;
@property (nonatomic, weak) IBOutlet UIButton* twoButton;
@property (nonatomic, weak) IBOutlet UIButton* threeButton;
@property (nonatomic, weak) IBOutlet UIButton* fourButton;
@property (nonatomic, weak) IBOutlet UIButton* fiveButton;
@property (nonatomic, weak) IBOutlet UIButton* sixButton;
@property (nonatomic, weak) IBOutlet UIButton* sevenButton;
@property (nonatomic, weak) IBOutlet UIButton* eightButton;
@property (nonatomic, weak) IBOutlet UIButton* nineButton;
@property (nonatomic, weak) IBOutlet UIButton* zeroButton;

@property (nonatomic, weak) IBOutlet UIButton* clearButton;
@property (nonatomic, weak) IBOutlet UIButton* deleteButton;

@property (nonatomic, weak) IBOutlet UISwitch* manDownSwitch;

@property (nonatomic, weak) IBOutlet UIBarButtonItem* doneButton;

// IBActions
- (IBAction)push:(id)sender;
- (IBAction)pop:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)done:(id)sender;

// Private Properties
@property (nonatomic) NSMutableArray* stack;
@property (nonatomic) NSManagedObjectContext* managedObjectContext; 

// Private Methods
- (void)configurePenaltyTimeLabel;
- (BOOL)shouldEnableDoneButton;

@end

@implementation INSOPenaltyTimeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.doneButton.enabled = [self shouldEnableDoneButton];
    
    // Set the default time
    // TODO: Figure out a way to set a default penalty time. 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions
- (IBAction)push:(id)sender
{
    UIButton* numberButton = (UIButton*)sender;
    NSInteger number = [numberButton.titleLabel.text integerValue];

    self.stack[minutesPosition] = self.stack[tensPosition];
    self.stack[tensPosition] = self.stack[digitsPosition];
    self.stack[digitsPosition] = @(number);
    
    [self configurePenaltyTimeLabel];
    
    self.doneButton.enabled = [self shouldEnableDoneButton];
}

- (IBAction)pop:(id)sender
{
    self.stack[digitsPosition] = self.stack[tensPosition];
    self.stack[tensPosition] = self.stack[minutesPosition];
    self.stack[minutesPosition] = @(0);
    
    [self configurePenaltyTimeLabel];
    
    self.doneButton.enabled = [self shouldEnableDoneButton];
}

- (IBAction)clear:(id)sender
{
    self.stack[digitsPosition] = @(0);
    self.stack[tensPosition] = @(0);
    self.stack[minutesPosition] = @(0);
    
    [self configurePenaltyTimeLabel];
    
    self.doneButton.enabled = [self shouldEnableDoneButton];
}

- (IBAction)done:(id)sender
{
    // Create the penalty game event
    GameEvent* penaltyGameEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
    
    // Set its properties
    penaltyGameEvent.timestamp = [NSDate date];
    penaltyGameEvent.penaltyTimeValue = [self penaltyTime];
    
    // Set its relations
    penaltyGameEvent.event = self.event;
    penaltyGameEvent.game = self.rosterPlayer.game;
    penaltyGameEvent.player = self.rosterPlayer;
    
    // And now, if this creates an extra-man opportunity, create one of those as well.
    if (self.manDownSwitch.isOn) {
        GameEvent* manDownGameEvent = [GameEvent insertInManagedObjectContext:self.managedObjectContext];
        
        manDownGameEvent.player = self.rosterPlayer.game.teamPlayer; 
        manDownGameEvent.timestamp = [NSDate date];
        manDownGameEvent.event = [Event eventForCode:INSOEventCodeManDown inManagedObjectContext:self.managedObjectContext];
        manDownGameEvent.game = self.rosterPlayer.game;
    }
    
    // Save the MOC
    NSError* error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving the new penalty event: %@, %@", error, error.userInfo);
    }
    
    // And pop to root
    [self performSegueWithIdentifier:INSODoneAddingEventSegueIdentifier sender:penaltyGameEvent];
}

#pragma mark - Private Properties
- (NSMutableArray*)stack
{
    if (!_stack) {
        _stack = [NSMutableArray new];
        [_stack addObject:@(0)];
        [_stack addObject:@(0)];
        [_stack addObject:@(0)];
    }
    return _stack;
}

- (NSManagedObjectContext*)managedObjectContext
{
    // Just want to use the game's moc and want an easier ref to it.
    if (!_managedObjectContext) {
        MensLacrosseStatsAppDelegate* appDelegate = (MensLacrosseStatsAppDelegate *)[[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    
    return _managedObjectContext;
}

#pragma mark - Private Methods;
- (void)configurePenaltyTimeLabel
{
    self.penaltyTimeLabel.text = [NSString stringWithFormat:@"%@:%@%@", self.stack[minutesPosition], self.stack[tensPosition], self.stack[digitsPosition]];
}

- (BOOL)shouldEnableDoneButton
{
    // Only let them hit Done if penalty time is > 0
    return [self penaltyTime] > 0;
}

- (NSInteger)penaltyTime
{
    NSInteger penaltyTime = 0;
    
    penaltyTime += [self.stack[minutesPosition] integerValue] * 60;
    penaltyTime += [self.stack[tensPosition] integerValue] * 10;
    penaltyTime += [self.stack[digitsPosition] integerValue];
    
    return penaltyTime;
}

@end
