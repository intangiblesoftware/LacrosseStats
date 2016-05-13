#import "Event.h"

static NSString * const INSOMaxPrepsGoal          = @"Goals";
static NSString * const INSOMaxPrepsAssists       = @"Assists";
static NSString * const INSOMaxPrepsShotsOnGoal   = @"ShotsOnGoal";
static NSString * const INSOMaxPrepsGroundballs   = @"GroundBalls";
static NSString * const INSOMaxPrepsInterceptions = @"Interceptions";
static NSString * const INSOMaxPrepsFaceoffWon    = @"FaceoffWon";
static NSString * const INSOMaxPrepsGoalsAgainst  = @"GoalsAgainst";
static NSString * const INSOMaxPrepsSaves         = @"Saves";
static NSString * const INSOMaxPrepsDrawTaken     = @"FaceoffAttempts";
static NSString * const INSOMaxPrepsDrawControl   = @"FaceoffWon";


@interface Event ()

@end

@implementation Event

// Custom logic goes here.
+ (Event*)eventForCode:(INSOEventCode)code inManagedObjectContext:(NSManagedObjectContext *)moc
{
    Event* matchingEvent = nil;
    
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:[Event entityName]];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"eventCode == %@", @(code)];
    request.predicate = predicate;
    
    NSError* error = nil;
    NSArray* eventsMatching = [moc executeFetchRequest:request error:&error];
    
    if ([eventsMatching count] > 0) {
        // We had some events that matched the code, so grab one and return it
        matchingEvent = [eventsMatching firstObject];
    }
    
    return  matchingEvent;
}

- (NSString*)maxPrepsTitle
{
    switch (self.eventCodeValue) {
        case INSOEventCodeGoal:
            return INSOMaxPrepsGoal;
            break;
        case INSOEventCodeAssist:
            return INSOMaxPrepsAssists;
            break;
        case INSOEventCodeShotOnGoal:
            return INSOMaxPrepsShotsOnGoal;
            break;
        case INSOEventCodeGroundball:
            return INSOMaxPrepsGroundballs;
            break;
        case INSOEventCodeInterception:
            return INSOMaxPrepsInterceptions;
            break;
        case INSOEventCodeFaceoffWon:
            return INSOMaxPrepsFaceoffWon;
            break;
        case INSOEventCodeGoalAllowed:
            return INSOMaxPrepsGoalsAgainst;
            break;
        case INSOEventCodeSave:
            return INSOMaxPrepsSaves;
            break;
        case INSOEventCodeDrawTaken:
            return INSOMaxPrepsDrawTaken;
            break;
        case INSOEventCodeDrawControl:
            return INSOMaxPrepsDrawControl;
            break;
        default:
            return nil;
            break;
    }
}

@end
