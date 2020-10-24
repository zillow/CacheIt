import UIKit
import CacheIt

// Lets store a dictionary in memory cache using the default parameters
TransientCache["MyName"] = ["Brett" : "Hamlin"]

// Fetch MyName from in memory cache
let myName: [String:String]? = TransientCache["MyName"]
myName

// Now lets store an array to disk.  Note this is a blocking call.
PersistentCache["ev0lutionOfApp"] = ["NextOS", "Objective-C", "Swift", "???"]

// Fetch ev0lutionOfApp from in disk cache.  Note this is a blocking call.
let evo: [String]? = PersistentCache["ev0lutionOfApp"]
evo

// Lets store an image to disk with a custom expiration time of 60 seconds
if #available(iOS 13.0, *) {
    var persistentCache = PersistentCache(expiration: 60)
    let image = UIImage(systemName: "multiply.circle.fill")
    persistentCache["image"] = image

    let loadedImage: UIImage? = persistentCache["image"]
    loadedImage
}

// We can also store a value to disk with a call that does not block.
PersistentCache.setValue(value: "This is a non blocking call", forKey: "nonBlockingKey") {

    // We are guaranteed that the write has finished so now we can fetch the value with a non-blocking fetch.
    PersistentCache.value(forKey: "nonBlockingKey") { (value: String?) in
        print("Value of persistent cache nonBlockingKey = \(value ?? "Some thing went wrong")")
    }
}
