// MRRealmResultsController.h
//
// Copyright (c) 2013 Héctor Marqués
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

@class RLMObjectSchema;
@class RLMRealm;
@class RLMArray;

@protocol MRRealmResultsControllerDelegate;
@protocol MRRealmSectionInfo;


/**
 This class is intended to provide `NSFetchedResultsController`-like 
 functionality for use with 
 **[realm-cocoa](https://github.com/realm/realm-cocoa/)**.
 */
@interface MRRealmResultsController : NSObject

/**
 Initializes an instance of `MRRealmResultsController`.
 
 @param objectClass Specific `RLMObject` subclass used in the queries.
 @param predicate The predicate used for querying `fetchedObjects`.
 @param realm The *Realm* instance in the main thread.
 @param sortDescriptor The sort descriptor used for sorting the results.
 @param sectionSortDescriptorOrNil A sort descriptor that will be used to 
 pre-compute the section information (must match the `sectionNameKeyPath`
 parameter).
 @param sectionNameKeyPath Keypath on resulting objects that returns the section
 name. This will be used to pre-compute the section information.
 
 @return The receiver initialized with the specified parameters.
 */
-   (id)initWithClass:(Class)objectClass
            predicate:(NSPredicate *)predicate
                realm:(RLMRealm *)realmOrNil
       sortDescriptor:(NSSortDescriptor *)sortDescriptor
sectionSortDescriptor:(NSSortDescriptor *)sectionSortDescriptorOrNil
       andNameKeyPath:(NSString *)sectionNameKeyPath;

/**
 Computes section information, begins change tracking and sets `fetchedObjects`.
*/
- (void)performFetch;


#pragma mark CONFIGURATION

/**
 The *Realm* instance.
 */
@property (nonatomic, strong, readonly) RLMRealm *realm;

/**
 Predicate used for querying `fetchedObjects`.
 */
@property (nonatomic, readonly) Class objectsClass;

/**
 Specific subclass of `RLMObject` used in the queries.
 */
@property (nonatomic, strong, readonly) NSPredicate *predicate;

/**
 Sort descriptor used for sorting the results.
 */
@property (nonatomic, strong, readonly) NSSortDescriptor *sortDescriptor;

/**
 Sort descriptor used to pre-compute the section information.
 */
@property (nonatomic, strong, readonly) NSSortDescriptor *sectionSortDescriptor;

/**
 Section name keypath on resulting objects.
 */
@property (nonatomic, strong, readonly) NSString *sectionNameKeyPath;

/**
 Receiver's delegate.
 */
@property (nonatomic, weak) id< MRRealmResultsControllerDelegate > delegate;


#pragma mark ACCESSING OBJECT RESULTS

/**
 Returns the results of the *fetch*.
 
 Returns `nil` if `performFetch` hasn't been called.
 */
@property  (nonatomic, readonly) RLMArray *fetchedObjects;

/**
 Returns the *fetched* object at a given indexPath.
 
 @param indexPath An index path in the *fetch* results.
 
 @return The object at a given index path in the receiver's *fetch* results.
 */
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

/**
 Returns the indexPath of a given object.

 @param object An object in the receiver's `fetchedObjects`.

 @return The index path of the object or `nil` if the object is not contained in
 the receiver's `fetchedObjects`.
*/
-(NSIndexPath *)indexPathForObject:(id)object;


#pragma mark  CONFIGURING SECTION INFORMATION

/**
 Returns the corresponding *section index* title for the given section name.
 
 Default implementation returns the capitalized first letter of `sectionName`
 parameter.
 
 @param sectionName The name of the section.
 
 @return The *section index* title corresponding to the given section name.
 */
- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName;

/**
 Returns the array of *section* index titles.
 */
@property (nonatomic, readonly) NSArray *sectionIndexTitles;


#pragma mark QUERYING SECTION INFORMATION

/**
 Returns an array of objects that implement the `MRRealmSectionInfo` protocol.
 
 Returns `nil` if `performFetch` hasn't been called.
*/
@property (nonatomic, readonly) NSArray *sections;

/**
 Returns the section number for a given *section index* index.
 
 @param sectionIndex The index of the section.
 
 @return The section number for the given section index in the *section index*.
 */
- (NSInteger)sectionForSectionIndexTitleAtIndex:(NSInteger)sectionIndex;


@end


#pragma mark -
#pragma mark -


/**
 This protocol defines the interface for section objects.
 */
@protocol MRRealmSectionInfo

/**
 Name of the section.
 */
@property (nonatomic, readonly) NSString *name;

/**
 Index title of the section (used when displaying the index).
 */
@property (nonatomic, readonly) NSString *indexTitle;

/**
 Number of objects in section.
 */
@property (nonatomic, readonly) NSUInteger numberOfObjects;

/**
 Returns the array of objects in the section.
 */
@property (nonatomic, readonly) id<NSFastEnumeration> objects;


@end


#pragma mark -
#pragma mark -


/**
 An instance of `MRRealmResultsController` uses methods in this protocol to 
 notify its delegate that the controller’s sections have been changed.
 */
@protocol MRRealmResultsControllerDelegate <NSObject>

enum {
    MRRealmResultsChangeInsert = 1,
    MRRealmResultsChangeDelete = 2,
    MRRealmResultsChangeCount = 5,
};
typedef NSUInteger MRRealmResultsChangeType;

/**
 Notifies the delegate of added and removed sections and sections that have 
 changed their number of objects.
 
 @param controller Controller instance that noticed the change on its sections.
 @param sectionInfo Changed section instance.
 @param index Index of changed section.
 @param type Indicates if the change was an insert, delete or count change.
 */
@optional
- (void)controller:(MRRealmResultsController *)controller
  didChangeSection:(id <MRRealmSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(MRRealmResultsChangeType)type;

/**
 Notifies the delegate that section changes are about to be processed and 
 notifications will be sent.
 
 @param controller Controller instance that noticed the change on its sections.
 */
@optional
- (void)controllerWillChangeContent:(MRRealmResultsController *)controller;

/**
 Notifies the delegate that all section changes have been sent.
 
 @param controller Controller instance that noticed the change on its sections.
 */
@optional
- (void)controllerDidChangeContent:(MRRealmResultsController *)controller;

/**
 Asks the delegate to return the corresponding *section index* title for a given
 section name.
 
 Only needed for customized section index titles.
 
 @param controller Controller instance that sent the message.
 @param sectionName The name of the section.
 
 @return The string to use as *section index* title for the specified section.
 */
@optional
-        (NSString *)controller:(MRRealmResultsController *)controller
sectionIndexTitleForSectionName:(NSString *)sectionName;


@end
