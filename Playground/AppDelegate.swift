//
//  AppDelegate.swift
//  CacheKit Example
//
//  Created by Brett Hamlin on 2/17/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let rootViewController = RootViewController(nibName: nil, bundle: nil)
        let navigationController = UINavigationController(rootViewController: rootViewController)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }
}
