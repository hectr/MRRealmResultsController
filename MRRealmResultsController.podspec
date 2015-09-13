
Pod::Spec.new do |s|

  s.name         = "MRRealmResultsController"
  s.version      = "0.0.1"
  s.summary      = "MRRealmResultsController is an alternative to NSFetchedResultsController for use with realm-cocoa."
  s.description  = <<-DESC
                   *This is untested ~~and undocumented~~ code not suitable for production use.*

                   `MRRealmResultsController` is an alternative to `NSFetchedResultsController` for use with **[realm-cocoa](https://github.com/realm/realm-cocoa/)**.

                   I've made it because I wanted to check how well could **[Realm](http://realm.io)** perform when used as a replacement to **Core Data** in an existing application with as few changes as possible made to the application code.
                   DESC
  s.homepage     = "https://github.com/hectr/MRRealmResultsController"
  s.license      = "MIT"
  s.author       = { "hectr" => "h@mrhector.me" }
  s.source       = { :git => "https://github.com/hectr/MRRealmResultsController.git", :tag => s.version.to_s }
  s.social_media_url = "https://twitter.com/hectormarquesra"

  s.source_files = "MRRealmResultsController"
  # s.library    = "libc++"
  s.dependency   "Realm", "0.90.5"
  s.requires_arc = true
  s.platform     = :ios, '6.0'

end
