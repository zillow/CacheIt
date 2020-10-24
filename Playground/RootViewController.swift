//
//  RootViewController.swift
//  CacheIt Example
//
//  Created by Brett Hamlin on 2/18/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import CacheIt

class RootViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        cacheIt()
    }

    private func cacheIt() {        
        // Lets store a dictionary in memory cache using the default parameters
        TransientCache["MyName"] = ["Brett" : "Hamlin"]

        // Fetch MyName from in memory cache
        let myName: [String:String]? = TransientCache["MyName"]
        print("Value of in memory MyName = \(myName ?? ["Some thing went wrong":"Assert()!?!?! Fail()!! doesNotCompute(@)!???"])")

        // Now lets store an array to disk.  Note this is a blocking call.
        PersistentCache["ev0lutionOfApp"] = ["NextOS", "Objective-C", "Swift", "???"]

        // Fetch ev0lutionOfApp from in disk cache.  Note this is a blocking call.
        let evo: [String]? = PersistentCache["ev0lutionOfApp"]
        print("Value of persistent cache ev0lutionOfApp = \(evo ?? ["Some thing went wrong Assert()!?!?! Fail()!! doesNotCompute(@)!???"])")

        // Lets store an image to disk with a custom expiration time of 60 seconds
        if #available(iOS 13.0, *) {
            var persistentCache = PersistentCache(expiration: 60)
            let image = UIImage(systemName: "multiply.circle.fill")
            persistentCache["image"] = image

            let loadedImage: UIImage? = persistentCache["image"]
            print("Value of persistent cache image = \(loadedImage?.description ?? "Some thing went wrong Assert()!?!?! Fail()!! doesNotCompute(@)!???")")
        }

        // We can also store a value to disk with a call that does not block.
        PersistentCache.setValue(value: "This is a non blocking call", forKey: "nonBlockingKey") {

            // We are guaranteed that the write has finished so now we can fetch the value with a non-blocking fetch.
            PersistentCache.value(forKey: "nonBlockingKey") { (value: String?) in
                print("Value of persistent cache nonBlockingKey = \(value ?? "Some thing went wrong")")
            }
        }
    }
}
