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

#import "MRRealmResultsController.h"
#import <Realm/Realm.h>


@interface MRRealmSectionInfo : NSObject <MRRealmSectionInfo>
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *keyPath;
@property (nonatomic, strong) NSPredicate *predicate;
@property (nonatomic, strong) NSString *indexTitle;
@property (nonatomic, assign) NSUInteger numberOfObjects;
@property (nonatomic, strong) id<NSFastEnumeration> objects;
@property (nonatomic, strong) RLMArray *sourceObjects;
@property (nonatomic, assign) NSSortDescriptor *secondarySort;
@end


@implementation MRRealmSectionInfo

+ (instancetype)mr_sectionInfoWithName:(NSString *const)name
                               keyPath:(NSString *const)keyPath
                             predicate:(NSPredicate *const)predicate
                            indexTitle:(NSString *const)indexTitle
                         sourceObjects:(RLMArray *const)sourceObjects
                                 range:(NSRange const)range
                        sortDescriptor:(NSSortDescriptor *const)sort
{
    NSParameterAssert(sourceObjects);
    
    MRRealmSectionInfo *const sectionInfo = [[self alloc] init];
    sectionInfo.name = name;
    sectionInfo.keyPath = keyPath;
    sectionInfo.predicate = predicate;
    sectionInfo.indexTitle = indexTitle;
    sectionInfo.numberOfObjects = range.length;
    sectionInfo.sourceObjects = sourceObjects;
    sectionInfo.secondarySort = sort;
    
    return sectionInfo;
}

#pragma mark Accessors

- (id<NSFastEnumeration>)objects
{
    if (_objects == nil) {
        RLMArray *const sourceObjects = self.sourceObjects;
        NSPredicate *const predicate = self.predicate;
        if (predicate) {
            RLMArray *const unsortedObjects =
            [sourceObjects objectsWithPredicate:predicate];
            NSSortDescriptor *const sort = self.secondarySort;
            if (sort) {
                _objects = [unsortedObjects arraySortedByProperty:sort.key
                                                        ascending:sort.ascending];
            } else {
                _objects = unsortedObjects;
            }
        } else {
            // only one section:
            _objects = sourceObjects;
        }
    }
    
    return  _objects;
}

@end


#pragma mark -
#pragma mark -


@interface MRRealmResultsController () {
    BOOL _willChangeContentDelegate;
    BOOL _didChangeContentDelegate;
    BOOL _didChangeSectionDelegate;
    BOOL _sectionIndexTitleDelegate;
    NSMutableArray *_sectionIndexTitles;
    NSMutableArray *_sectionIndexTitlesSections;
    NSArray *_sectionFirstObjectIndexes;
}
@property (nonatomic, assign) Class objectsClass;
@property (nonatomic, strong) RLMNotificationToken *notification;
@end


@implementation MRRealmResultsController

@dynamic sectionIndexTitles;

#pragma mark Public

-   (id)initWithClass:(Class const)objectClass
            predicate:(NSPredicate *const)predicate
                realm:(RLMRealm *const)realmOrNil
       sortDescriptor:(NSSortDescriptor *const)sortDescriptor
sectionSortDescriptor:(NSSortDescriptor *const)sectionSortDescriptorOrNil
       andNameKeyPath:(NSString *const)sectionNameKeyPath
{
    NSParameterAssert(objectClass);
    NSAssert(sectionSortDescriptorOrNil == nil || sectionNameKeyPath,
             @"section sort descriptor requires a section name key path");
    
    self = [self init];
    if (self) {
        _objectsClass = objectClass;
        _predicate = predicate;
        _sortDescriptor = sortDescriptor;
        _realm = (realmOrNil ?: RLMRealm.defaultRealm);
        if (sectionNameKeyPath && sectionSortDescriptorOrNil == nil) {
            _sectionSortDescriptor =
            [NSSortDescriptor sortDescriptorWithKey:sectionNameKeyPath
                                          ascending:YES];
        } else {
            _sectionSortDescriptor = sectionSortDescriptorOrNil;
        }
        _sectionNameKeyPath = sectionNameKeyPath;
    }
    
    return self;
}

- (void)performFetch
{
    if (_fetchedObjects == nil) { // TODO: FIXME: move to accessors
        NSPredicate *const predicate = self.predicate;
        RLMArray *array;
        if (predicate) {
            array = [self.objectsClass objectsInRealm:self.realm withPredicate:predicate];
        } else {
            array = [self.objectsClass allObjectsInRealm:self.realm];
        }
        NSSortDescriptor *const primarySort = self.mr_primarySort;
        if (primarySort) {
            _fetchedObjects = [array arraySortedByProperty:primarySort.key
                                                 ascending:primarySort.ascending];
        } else {
            _fetchedObjects = array;
        }
    }

    // TODO: update data structures instead of re-creating them --
    _sectionIndexTitles = nil;
    _sectionIndexTitlesSections = nil;
    
    NSArray *firstObjectIndexes;
    NSArray *const sectionNames = [self mr_sectionNames:&firstObjectIndexes];
    _sectionFirstObjectIndexes = firstObjectIndexes;
    _sections = [self mr_sectionsWithNames:sectionNames];
    // --
    
    if (self.notification == nil) {
        [self mr_addNotification];
    }
}

- (id)objectAtIndexPath:(NSIndexPath *const)indexPath
{
    NSInteger const section = indexPath.section;
    NSInteger const row = indexPath.row;
    RLMObject *object;
    if (self.sortDescriptor) {
        id <MRRealmSectionInfo> const sectionInfo = self.sections[section];
        object = sectionInfo.objects[row];
    } else {
        NSNumber *const firstIndexNumber = _sectionFirstObjectIndexes[section];
        NSUInteger const index = firstIndexNumber.unsignedIntegerValue + row;
        object = self.fetchedObjects[index];
    }
    
    return object;
}

- (NSIndexPath *)indexPathForObject:(id const)object
{
    __block NSIndexPath *indexPath;
    if (self.sortDescriptor) {
        void (^const block)(id <MRRealmSectionInfo>, NSUInteger, BOOL *) =
        ^(id <MRRealmSectionInfo> const sectionInfo,
          NSUInteger const sectionIndex,
          BOOL *const stop) {
            NSUInteger const index =
            [(RLMArray *)sectionInfo.objects indexOfObject:object];
            if (index != NSNotFound) {
                indexPath = [NSIndexPath indexPathForRow:index inSection:sectionIndex];
                *stop = YES;
            }
        };
        [self.sections enumerateObjectsUsingBlock:block];
    } else {
        NSUInteger const index = [self.fetchedObjects indexOfObject:object];
        if (index != NSNotFound) {
            NSUInteger candidateSection = 0;
            for (NSNumber *const firstNumber in _sectionFirstObjectIndexes) {
                NSUInteger const first = firstNumber.unsignedIntegerValue;
                if (first > index) {
                    NSAssert(candidateSection > 0,
                             @"unsigned integer candidateSection should be "
                             @"greater than 0 before it can be decremented");
                    candidateSection -= 1;
                    break;
                } else if (first == index) {
                    break;
                } else {
                    candidateSection += 1;
                }
            }
            NSNumber *const firstIndexNumber =
            _sectionFirstObjectIndexes[candidateSection];
            NSInteger const firstIndex = firstIndexNumber.integerValue;
            NSAssert(index >= firstIndex,
                     @"index should be greater or equal than firstIndex");
            NSInteger const row = index - firstIndex;
            indexPath = [NSIndexPath indexPathForRow:row inSection:candidateSection];
        }
    }
    
    return indexPath;
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *const)sectionName
{
    NSString *indexTitle;
    if (_sectionIndexTitleDelegate) {
        indexTitle = [self.delegate controller:self
               sectionIndexTitleForSectionName:sectionName];
    } else {
        if (sectionName.length == 0) {
            indexTitle = sectionName;
        } if (sectionName.length == 1) {
            indexTitle = sectionName.uppercaseString;
        } else if (sectionName.length == 2) {
            indexTitle = sectionName.uppercaseString;
        } else {
            indexTitle = [sectionName substringToIndex:2].uppercaseString;
        }
    }
    
    return indexTitle;
}

- (NSInteger)sectionForSectionIndexTitleAtIndex:(NSInteger const)sectionIndex;
{
    NSNumber *const section = _sectionIndexTitlesSections[sectionIndex];
    
    return section.integerValue;
}

#pragma mark Private

// Sets realm notification block.
- (void)mr_addNotification
{
    RLMRealm *const realm = self.realm;
    
    __weak typeof(self) weakSelf = self;
    self.notification = [realm addNotificationBlock:
                         ^(NSString *const note, RLMRealm *const realm) {
                             [weakSelf mr_reloadData];
                         }];
}

// Unsets realm notification block.
- (void)mr_removeNotification
{
    [RLMRealm.defaultRealm removeNotification:self.notification];
    self.notification = nil;
}

- (id<MRRealmSectionInfo>)mr_sectionInfoWithName:(NSString *const)sectionName
                                         keyPath:(NSString *const)keyPath
                                       predicate:(NSPredicate *const)predicate
                                   sourceObjects:(RLMArray *const)sourceObjects
                                           range:(NSRange const)range
                                  sortDescriptor:(NSSortDescriptor *const)sort
{
    NSString *const sectionIndexTitle =
    [self sectionIndexTitleForSectionName:sectionName];
    
    MRRealmSectionInfo *const sectionInfo =
    [MRRealmSectionInfo mr_sectionInfoWithName:sectionName
                                       keyPath:keyPath
                                     predicate:predicate
                                    indexTitle:sectionIndexTitle
                                 sourceObjects:sourceObjects
                                         range:range
                                sortDescriptor:sort];
    return sectionInfo;
}

// Notifies the changes to the delegate and performs a new fetch.
- (void)mr_reloadData
{
    NSAssert(self.sections != nil, @"cannot reload without data already loaded");
    
    id<MRRealmResultsControllerDelegate> const delegate = self.delegate;
    if (_willChangeContentDelegate) {
        [delegate controllerWillChangeContent:self];
    }
    
    // FIXME: 'per object notifications' will allow more efficient data refreshing --
    // (https://github.com/realm/realm-cocoa/issues/601)
    if (_didChangeSectionDelegate) {
        NSArray *const oldSections = self.sections;
        [self performFetch];
        [self mr_forwardSectionChanges:oldSections];
    } else {
        [self performFetch];
    }
    // --
    
    if (_didChangeContentDelegate) {
        [delegate controllerDidChangeContent:self];
    }
}

// Returns the primary sort descriptor.
- (NSSortDescriptor *)mr_primarySort
{
    NSSortDescriptor *primarySort;
    if (self.sectionNameKeyPath) {
        primarySort = self.sectionSortDescriptor;
    } else {
        primarySort = self.sortDescriptor;
    }
    
    return primarySort;
}

// Returns the secondary sort descriptor (used for re-sorting section objects).
- (NSSortDescriptor *)mr_secondarySortForSection:(NSInteger const)section
{
    NSAssert(section > 0, @"invalid section parameter %ld", (long)section);
    
    NSSortDescriptor *secondarySort;
    if (self.sectionNameKeyPath) {
        secondarySort = self.sortDescriptor;
    }
    
    return secondarySort;
}

// Returns all section names present in the fetched objects array and sets in
// firstObjectIndexesPtr an array built with the first index of each section.
- (NSArray *)mr_sectionNames:(NSArray **const)firstObjectIndexesPtr
{
    NSParameterAssert(firstObjectIndexesPtr);
    
    NSString *const sectionNameKeyPath = self.sectionNameKeyPath;
    RLMArray *const fetchedObjects = self.fetchedObjects;
    NSMutableArray *const sectionNames = NSMutableArray.array;
    NSMutableArray *firstObjectIndexes;
    if (sectionNameKeyPath) {
        NSString *previousName = (id)NSNull.null;
        NSUInteger index = 0;
        firstObjectIndexes = NSMutableArray.array;
        for (id const anObject in fetchedObjects) {
            NSString *const sectionName = [anObject valueForKeyPath:sectionNameKeyPath];
            if ((NSNull.null == (id)previousName && sectionName == nil) ||
                ![sectionName isEqual:previousName]) {
                previousName = sectionName;
                [sectionNames addObject:(sectionName ?: NSNull.null)];
                NSAssert(![firstObjectIndexes containsObject:@(index)],
                         @"_sectionFirstObjectIndexes already contains "
                         @"index %lu",
                         (unsigned long)index);
                [firstObjectIndexes addObject:@(index)];
            }
            index++;
        }
    }
    *firstObjectIndexesPtr = firstObjectIndexes;

    return sectionNames;
}

// Returns the sections for the fetchedObjects given their names and extra sort.
- (NSArray *)mr_sectionsWithNames:(NSArray *const)sectionNames
{
    // TODO: current implementation ignores section --
    NSSortDescriptor *const secondarySort = [self mr_secondarySortForSection:NSNotFound];
    // --
    NSString *const sectionNameKeyPath = self.sectionNameKeyPath;
    RLMArray *const fetchedObjects = self.fetchedObjects;
    NSPredicate *const predicate = self.predicate;
    
    NSMutableArray *const sections =
    [NSMutableArray arrayWithCapacity:sectionNames.count];
    if (sectionNameKeyPath) {
        NSUInteger section = 0;
        for (NSString *const candidate in sectionNames) {
            NSString *const sectionName =
            (NSNull.null == (id)candidate ? nil : candidate);
            NSString *const format =
            [NSString stringWithFormat:@"%@ = %%@", sectionNameKeyPath];
            // FIXME: 'Chaining queries' did not work --
            // (https://github.com/realm/realm-cocoa/issues/927) --
            //            NSPredicate *const sectionPredicate =
            //            [NSPredicate predicateWithFormat:format, sectionName];
            // --
            NSPredicate *const namePredicate  =
            [NSPredicate predicateWithFormat:format, sectionName];
            NSPredicate *sectionPredicate;
            if (predicate) {
                NSArray *const subpredicates = @[ predicate, namePredicate ];
                sectionPredicate =
                [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType
                                            subpredicates:subpredicates];
            } else {
                sectionPredicate = namePredicate;
            }
            NSRange const range = [self mr_sectionRange:section];
            //NSSortDescriptor *const secondarySort =
            //[self mr_secondarySortForSection:section];
            id<MRRealmSectionInfo> const sectionInfo = [self mr_sectionInfoWithName:sectionName
                                               keyPath:sectionNameKeyPath
                                             predicate:sectionPredicate
                                           sourceObjects:fetchedObjects
                                                 range:range
                                        sortDescriptor:secondarySort];
            [sections addObject:sectionInfo];
            section++;
        }
    } else if (fetchedObjects.firstObject) {
        NSRange const range = NSMakeRange(0, fetchedObjects.count);
        id<MRRealmSectionInfo> const sectionInfo =
        [self mr_sectionInfoWithName:nil
                             keyPath:nil
                           predicate:nil
                       sourceObjects:fetchedObjects
                               range:range
                      sortDescriptor:secondarySort];

        [sections addObject:sectionInfo];
    }
    
    return sections;
}

// Returns the range of a section in the fetched objects array given its index.
- (NSRange)mr_sectionRange:(NSUInteger const)section
{
    NSUInteger const nextSection = section + 1;
    NSNumber *const firstIndexNumber = _sectionFirstObjectIndexes[section];
    NSUInteger const firstIndex = firstIndexNumber.unsignedIntegerValue;
    
    NSRange range;
    if (_sectionFirstObjectIndexes.count > nextSection) {
        NSNumber *const nextFirstIndexNumber =
        _sectionFirstObjectIndexes[nextSection];
        NSUInteger const nextFirstIndex =
        nextFirstIndexNumber.unsignedIntegerValue;
        NSAssert(firstIndex < nextFirstIndex,
                 @"next section must start after section");
        range = NSMakeRange(firstIndex, nextFirstIndex - firstIndex);
    } else {
        range = NSMakeRange(firstIndex, self.fetchedObjects.count - firstIndex);
    }
    
    return range;
}

// Notifies the section changes to the delegate.
- (void)mr_forwardSectionChanges:(NSArray *const)oldSections
{
    id<MRRealmResultsControllerDelegate> const delegate = self.delegate;
    NSMutableArray *const deletedSections = oldSections.mutableCopy;
    
    __weak typeof(self) const weakSelf = self;
    [self.sections enumerateObjectsUsingBlock:
     ^(id<MRRealmSectionInfo> const section, NSUInteger const idx, BOOL *const stop) {
         __strong typeof(self) const strongSelf = weakSelf;
         __block NSUInteger oldIdx = NSNotFound;
         [oldSections enumerateObjectsUsingBlock:
          ^(id<MRRealmSectionInfo> const oldSection, NSUInteger const idx, BOOL *const stop) {
              if (oldSection.name == section.name ||
                  [oldSection.name isEqualToString:section.name]) {
                  oldIdx = idx;
              }
          }];
         if (oldIdx == NSNotFound) {
             [delegate controller:strongSelf
                 didChangeSection:section
                          atIndex:idx
                    forChangeType:MRRealmResultsChangeInsert];
         } else {
             id<MRRealmSectionInfo> const oldSection = oldSections[oldIdx];
             if (oldIdx != idx) {
                 [delegate controller:strongSelf
                     didChangeSection:oldSection
                              atIndex:oldIdx
                        forChangeType:MRRealmResultsChangeDelete];
                 [delegate controller:strongSelf
                     didChangeSection:section
                              atIndex:idx
                        forChangeType:MRRealmResultsChangeInsert];
             } else if (oldSection.numberOfObjects != section.numberOfObjects) {
                 [delegate controller:strongSelf
                     didChangeSection:section
                              atIndex:idx
                        forChangeType:MRRealmResultsChangeCount];
             }
             [deletedSections removeObject:oldSection];
         }
     }];
    
    [deletedSections enumerateObjectsUsingBlock:
     ^(id<MRRealmSectionInfo> const oldSection, NSUInteger const idx, BOOL *const stop) {
         __strong typeof(self) const strongSelf = weakSelf;
         [delegate controller:strongSelf
             didChangeSection:oldSection
                      atIndex:idx
                forChangeType:MRRealmResultsChangeDelete];
     }];
}

#pragma mark Accessors

- (void)setDelegate:(id<MRRealmResultsControllerDelegate> const)delegate
{
    [self willChangeValueForKey:@"delegate"];
    
    _delegate = delegate;
    
    _willChangeContentDelegate =
    [delegate respondsToSelector:@selector(controllerWillChangeContent:)];
    _didChangeContentDelegate =
    [delegate respondsToSelector:@selector(controllerDidChangeContent:)];
    _didChangeSectionDelegate =
    [delegate respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)];
    _sectionIndexTitleDelegate =
    [delegate respondsToSelector:@selector(controller:sectionIndexTitleForSectionName:)];
    
    [self didChangeValueForKey:@"delegate"];
}

- (NSArray *)sectionIndexTitles
{
    if (_sectionIndexTitles == nil) {
        NSArray *const sections = self.sections;
        
        NSUInteger const count = sections.count;
        _sectionIndexTitles = [NSMutableArray arrayWithCapacity:count];
        _sectionIndexTitlesSections = [NSMutableArray arrayWithCapacity:count];
        
        
        NSMutableArray *const names =
        [NSMutableArray arrayWithCapacity:sections.count];
        for (id<MRRealmSectionInfo> const section in sections) {
            NSString *const name = section.name;
            [names addObject:(name ?: NSNull.null)];
        }

        [names enumerateObjectsUsingBlock:
         ^(NSString *const candidate, NSUInteger const index, BOOL *const stop) {
             if (NSNull.null != (id)candidate) {
                 NSString *const indexTitle =
                 [self sectionIndexTitleForSectionName:candidate];
                 if (indexTitle) {
                     [_sectionIndexTitles addObject:indexTitle];
                     [_sectionIndexTitlesSections addObject:@(index)];
                 }
             }
         }];
    }
    
    return _sectionIndexTitles;
}

#pragma mark - NSObject

- (void)dealloc
{
    if (self.notification) {
        [self mr_removeNotification];
    }
}

@end