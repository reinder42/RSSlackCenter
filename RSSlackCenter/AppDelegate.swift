//
//  AppDelegate.swift
//  RSSlackCenter
//
//  Created by Reinder de Vries on 10-08-15.
//  Copyright (c) 2015 LearnAppMaking. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?;

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        var msgVC:RSMessageCenterViewController = RSMessageCenterViewController();
        msgVC.title = "Message Center";
        
        var navigationVC:UINavigationController = UINavigationController(rootViewController: msgVC);
        
        let frame = UIScreen.mainScreen().bounds;
        window = UIWindow(frame: frame);
        
        window!.rootViewController = navigationVC;
        window!.makeKeyAndVisible();
    
        return true;
    }

    
    func applicationWillResignActive(application: UIApplication)
    {
        RSSocketAPI.sharedInstance.disconnect();
    }

    func applicationDidEnterBackground(application: UIApplication) {
        
    }

    func applicationWillEnterForeground(application: UIApplication) {
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        
    }

    func applicationWillTerminate(application: UIApplication)
    {
        
    }
}

