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


@interface MRRealmResultsController : NSObject


-   (id)initWithClass:(Class)objectClass
            predicate:(NSPredicate *)predicate
                realm:(RLMRealm *)realmOrNil
       sortDescriptor:(NSSortDescriptor *)sortDescriptor
sectionSortDescriptor:(NSSortDescriptor *)sectionSortDescriptorOrNil
       andNameKeyPath:(NSString *)sectionNameKeyPath;

- (void)performFetch;


#pragma mark CONFIGURATION


@property (nonatomic, readonly) NSPredicate *predicate;

@property (nonatomic, readonly) NSSortDescriptor *sortDescriptor;

@property (nonatomic, readonly) RLMRealm *realm;

@property (nonatomic, strong, readonly) NSSortDescriptor *sectionSortDescriptor;

@property (nonatomic, strong, readonly) NSString *sectionNameKeyPath;

@property(nonatomic, assign) id< MRRealmResultsControllerDelegate > delegate;


#pragma mark ACCESSING OBJECT RESULTS


@property  (nonatomic, readonly) RLMArray *fetchedObjects;

- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

-(NSIndexPath *)indexPathForObject:(id)object;


#pragma mark  CONFIGURING SECTION INFORMATION


- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName;

@property (nonatomic, readonly) NSArray *sectionIndexTitles;


#pragma mark QUERYING SECTION INFORMATION


@property (nonatomic, readonly) NSArray *sections;

- (NSInteger)sectionForSectionIndexTitleAtIndex:(NSInteger)sectionIndex;


@end


#pragma mark -
#pragma mark -


@protocol MRRealmSectionInfo


@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) NSString *indexTitle;

@property (nonatomic, readonly) NSUInteger numberOfObjects;

@property (nonatomic, readonly) id<NSFastEnumeration> objects;


@end


#pragma mark -
#pragma mark -


@protocol MRRealmResultsControllerDelegate <NSObject>


enum {
    MRRealmResultsChangeInsert = 1,
    MRRealmResultsChangeDelete = 2,
    MRRealmResultsChangeCount = 5,
};
typedef NSUInteger MRRealmResultsChangeType;

@optional
- (void)controller:(MRRealmResultsController *)controller
  didChangeSection:(id <MRRealmSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(MRRealmResultsChangeType)type;

@optional
- (void)controllerWillChangeContent:(MRRealmResultsController *)controller;

@optional
- (void)controllerDidChangeContent:(MRRealmResultsController *)controller;

@optional
-        (NSString *)controller:(MRRealmResultsController *)controller
sectionIndexTitleForSectionName:(NSString *)sectionName;


@end
