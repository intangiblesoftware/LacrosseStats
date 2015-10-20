// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to EventCategory.h instead.

@import CoreData;

extern const struct EventCategoryAttributes {
	__unsafe_unretained NSString *sortOrder;
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

@property (nonatomic, strong) NSNumber* sortOrder;

@property (atomic) float sortOrderValue;
- (float)sortOrderValue;
- (void)setSortOrderValue:(float)value_;

//- (BOOL)validateSortOrder:(id*)value_ error:(NSError**)error_;

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

- (NSNumber*)primitiveSortOrder;
- (void)setPrimitiveSortOrder:(NSNumber*)value;

- (float)primitiveSortOrderValue;
- (void)setPrimitiveSortOrderValue:(float)value_;

- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;

- (NSMutableSet*)primitiveEvents;
- (void)setPrimitiveEvents:(NSMutableSet*)value;

@end
