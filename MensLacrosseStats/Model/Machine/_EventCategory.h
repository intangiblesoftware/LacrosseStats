// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EventCategory.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class Event;

@interface EventCategoryID : NSManagedObjectID {}
@end

@interface _EventCategory : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (nullable NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EventCategoryID *objectID;

@property (nonatomic, strong, nullable) NSNumber* categoryCode;

@property (atomic) int16_t categoryCodeValue;
- (int16_t)categoryCodeValue;
- (void)setCategoryCodeValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSString* title;

@property (nonatomic, strong, nullable) NSSet<Event*> *events;
- (nullable NSMutableSet<Event*>*)eventsSet;

@end

@interface _EventCategory (EventsCoreDataGeneratedAccessors)
- (void)addEvents:(NSSet<Event*>*)value_;
- (void)removeEvents:(NSSet<Event*>*)value_;
- (void)addEventsObject:(Event*)value_;
- (void)removeEventsObject:(Event*)value_;

@end

@interface _EventCategory (CoreDataGeneratedPrimitiveAccessors)

- (nullable NSNumber*)primitiveCategoryCode;
- (void)setPrimitiveCategoryCode:(nullable NSNumber*)value;

- (int16_t)primitiveCategoryCodeValue;
- (void)setPrimitiveCategoryCodeValue:(int16_t)value_;

- (nullable NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(nullable NSString*)value;

- (NSMutableSet<Event*>*)primitiveEvents;
- (void)setPrimitiveEvents:(NSMutableSet<Event*>*)value;

@end

@interface EventCategoryAttributes: NSObject 
+ (NSString *)categoryCode;
+ (NSString *)title;
@end

@interface EventCategoryRelationships: NSObject
+ (NSString *)events;
@end

NS_ASSUME_NONNULL_END
