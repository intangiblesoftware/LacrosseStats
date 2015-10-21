// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EventCategory.h instead.

@import CoreData;

extern const struct EventCategoryAttributes {
	__unsafe_unretained NSString *categoryCode;
	__unsafe_unretained NSString *title;
} EventCategoryAttributes;

extern const struct EventCategoryRelationships {
	__unsafe_unretained NSString *events;
} EventCategoryRelationships;

@class Event;

@interface EventCategoryID : NSManagedObjectID {}
@end

@interface _EventCategory : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EventCategoryID* objectID;

@property (nonatomic, strong) NSNumber* categoryCode;

@property (atomic) int16_t categoryCodeValue;
- (int16_t)categoryCodeValue;
- (void)setCategoryCodeValue:(int16_t)value_;

//- (BOOL)validateCategoryCode:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* title;

//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *events;

- (NSMutableSet*)eventsSet;

@end

@interface _EventCategory (EventsCoreDataGeneratedAccessors)
- (void)addEvents:(NSSet*)value_;
- (void)removeEvents:(NSSet*)value_;
- (void)addEventsObject:(Event*)value_;
- (void)removeEventsObject:(Event*)value_;

@end

@interface _EventCategory (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveCategoryCode;
- (void)setPrimitiveCategoryCode:(NSNumber*)value;

- (int16_t)primitiveCategoryCodeValue;
- (void)setPrimitiveCategoryCodeValue:(int16_t)value_;

- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;

- (NSMutableSet*)primitiveEvents;
- (void)setPrimitiveEvents:(NSMutableSet*)value;

@end
