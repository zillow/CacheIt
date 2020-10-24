<p align="center">
    <img width="1210px" src="Media/comic.jpg">
</p>
 
**CacheIt** makes it easy to add caching capabilities to your iOS app! 
<br>

[![pipeline status](https://gitlab.zgtools.net/itx/zillow-docs/zdocs-ios/cachekit/badges/development/pipeline.svg)](https://gitlab.zgtools.net/itx/zillow-docs/zdocs-ios/cachekit/commits/development)


## Features

- [x] Fast and lightweight
- [x] Ability to store 'Any' data type
- [x] Operates similar to a Dictionary using key/value pairs
- [x] Support for both in memory and to disk cache
- [x] Each piece of data cached can have its own expiration

## Requirements

- Swift 5.0
- iOS 10.0+


## Installation
### Swift Package Manager

To integrate **CacheIt** into your Xcode project using SPM:
1.  In xCode select File → Add Package Dependency
2.  Enter the repository URL - git@gitlab.zgtools.net:itx/zillow-docs/zdocs-ios/cachekit.git
3.  Under "version" select the latest version


### Cocoapods

To integrate **CacheIt** into your Xcode project using CocoaPods, specify it in your `Podfile`:

```rubygi
source 'git@gitlab.zgtools.net:itx/zillow-docs/zdocs-ios/pod-spec.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'CacheIt'
end
```

Then, run the following command:

```bash
$ pod install
```

## Using default parameters

1. Import CacheIt Module

```swift
import CacheIt
```

2. Store data to disk using the static class function referencing the data by the key "names" using the default storage parameters. 
```swift
// Blocking call
PersistentCache["names"] = ["Brett" : "Hamlin"]
//
// Non blocking call
PersistentCache.setValue(value: TestData.cacheTestDataValue, forKey: TestData.cacheTestDataKey) { }
```

3. Retrieve data from disk using the static class function referencing it by the key "names".
```swift
// Blocking call
let myNames: [String:String]? = PersistentCache["names"]
//
// Non blocking call
PersistentCache.value(forKey: TestData.cacheTestDataKey) { (val: String?) in }
```



## Using custom parameters

1. Import CacheIt Module

```swift
import CacheIt
```

2. Create a custom cache type with your own parameters.
```swift
var cache = PersistentCache(expiration: 30)
```

3. Store data in memory referencing the data by the key "names" using custom storage parameters.
```swift
cache["names"] = ["Brett", "Art", "Dan"]
```

3. Retrieve data from memory referencing it by the key "names".
```swift
let myNames: [String]? = cache["names"]
```



## Configure Logging
Logging utilizes Apple's native OSLog.  You can enable logging by setting a logging level of `.debug`, `.info`, or `.none`.
```swift
CacheController.shared.loggingLevel = .debug
```



## Objective-C Support
CacheIt provides two static class types to store and retrieve data - NSPersistentCache & NSTransientCache

1. Import CacheIt Module

```objc
@import CacheIt;
```

2. Store data to disk using the static class function referencing the data by the key "names" using the default storage parameters. 
```objc
// Blocking call
[NSPersistentCache setValue:@"Brett Hamlin" forKey:@"name"];
```

3. Retrieve data from disk using the static class function referencing it by the key "names".
```objc
// Blocking call
NSString *myName = [NSPersistentCache valueForKey:@"name"];
```

## Details, details, details
**Caching Types:** CacheIt supports Transient (to memory) and Persistent (to disk) caching.  You can reference the static class subscript methods using default parameters or create your own instance of the class to pass in your own default parameters.  The two classes are: PersistentCache and TransientCache respectively.



## License

**CacheIt** is available under the Apache License, Version 2.0.

