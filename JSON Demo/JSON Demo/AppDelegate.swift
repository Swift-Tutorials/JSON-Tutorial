//
//  AppDelegate.swift
//  JSON Demo
//
//  Created by Yogesh Bharate on 14/08/15.
//  Copyright (c) 2015 Yogesh Bharate. All rights reserved.
//

import UIKit
import Foundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var nameAndAvatar : NSMutableDictionary?
    var plist : String?
    var isSave : Bool = false


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask,true)
        let documentDirectory : AnyObject = paths[0]
        plist = documentDirectory.stringByAppendingPathComponent("applicationInfo.plist")
        if !NSFileManager.defaultManager().fileExistsAtPath(plist!){
            NSFileManager.defaultManager().createFileAtPath(plist!, contents: nil, attributes: nil)
        } else {
            nameAndAvatar = NSMutableDictionary(contentsOfFile: plist!)
        }
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        
        if (nameAndAvatar != nil){
//            print("\n\n\n path = > \(plist)")
            isSave = true
            nameAndAvatar?.writeToFile(plist!, atomically: false)
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        if (nameAndAvatar != nil) {
            //            print("\n\n\n path = > \(plist)")
            nameAndAvatar?.writeToFile(plist!, atomically: false)
        }
    }


}

