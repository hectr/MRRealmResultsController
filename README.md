[![Version](https://img.shields.io/cocoapods/v/MRRealmResultsController.svg?style=flat)](http://cocoadocs.org/docsets/MRRealmResultsController)
[![License](https://img.shields.io/cocoapods/l/MRRealmResultsController.svg?style=flat)](http://cocoadocs.org/docsets/MRRealmResultsController)
[![Platform](https://img.shields.io/cocoapods/p/MRRealmResultsController.svg?style=flat)](http://cocoadocs.org/docsets/MRRealmResultsController)

# MRRealmResultsController

*This is untested ~~and undocumented~~ code not suitable for production use.*

`MRRealmResultsController` is an alternative to `NSFetchedResultsController` for use with **[realm-cocoa](https://github.com/realm/realm-cocoa/)**.

I've made it because I wanted to check how well could **[Realm](http://realm.io)** perform when used as a replacement to **Core Data** in an existing application with as few changes as possible made to the application code.

The *MRRealmResultsControllerExample* project is essentially the *TableView* from *[RealmExamples](https://github.com/realm/realm-cocoa/tree/master/examples/ios/objc)* with some modifications to demonstrate the use of `MRRealmResultsController`.

---

The key differences between `NSFetchedResultsController` and `MRRealmResultsController` interfaces reside in the following methods:

```objc
// NSFetchedResultsController
- (id)initWithFetchRequest:(NSFetchRequest *)fetchRequest
      managedObjectContext: (NSManagedObjectContext *)context 
        sectionNameKeyPath:(NSString *)sectionNameKeyPath 
                 cacheName:(NSString *)name;
                 
// MRRealmResultsController
  - (id)initWithClass:(Class)objectClass
            predicate:(NSPredicate *)predicate
                realm:(RLMRealm *)realmOrNil
       sortDescriptor:(NSSortDescriptor *)sortDescriptor
sectionSortDescriptor:(NSSortDescriptor *)sectionSortDescriptorOrNil
       andNameKeyPath:(NSString *)sectionNameKeyPath;

// NSFetchedResultsControllerDelegate
- (void)controller:(NSFetchedResultsController *)controller 
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath 
     forChangeType:(NSFetchedResultsChangeType)type 
      newIndexPath:(NSIndexPath *)newIndexPath;
- (void)controller:(NSFetchedResultsController *)controller 
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo 
           atIndex:(NSUInteger)sectionIndex 
     forChangeType:(NSFetchedResultsChangeType)type;

// MRRealmResultsControllerDelegate
- (void)controller:(MRRealmResultsController *)controller
  didChangeSection:(id <MRRealmSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(MRRealmResultsChangeType)type;
```

## Usage

To run the example project, clone the repo, and run `pod install` from the *Example* directory first.

## Installation

### CocoaPods

**MRRealmResultsController** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your *Podfile*:

```ruby
pod "MRRealmResultsController"
```

### Manually

Perform the following steps:

- Add **[Realm](http://realm.io)** into your project (see <https://realm.io/docs/objc/latest/#installation>).
- Copy *MRRealmResultsController* directory into your project.

## License

**MRRealmResultsController** is available under the MIT license. See the *LICENSE* file for more info.

# Alternatives

- [RLMFetchedResultsController](https://github.com/Krivoblotsky/RealmDemo/tree/master/RealmDemo/RLMFetchedResultsController)
- [RBQFetchedResultsController](https://github.com/Roobiq/RBQFetchedResultsController)
- [RealmResultsController](https://github.com/redbooth/RealmResultsController)
