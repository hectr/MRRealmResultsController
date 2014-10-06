# MRRealmResultsController

*This is untested and undocumented code not suitable for production use.*

`MRRealmResultsController` is an alternative to `NSFetchedResultsController` for use with **[realm-cocoa](https://github.com/realm/realm-cocoa/)**.

I've made it because I wanted to check how well could **[Realm](http://realm.io)** perform when used as a replacement to **Core Data** in an existing application with as few changes as possible made to the application code.

The *MRRealmResultsControllerExample* project is essentially the *TableView* from *[RealmExamples](https://github.com/realm/realm-cocoa/tree/master/examples/ios/objc)* with some modifications to demonstrate the use of `MRRealmResultsController`.
