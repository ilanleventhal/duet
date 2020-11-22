//
//  AppDelegate.swift
//  duet
//
//  Created by ilan leventhal on 10/4/20.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var auth = SPTAuth()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        auth.redirectURL     = URL(string: "duet://returnAfterLogin") // insert your redirect URL here
        auth.sessionUserDefaultsKey = "current session"
        print("part 1 chillin")
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("application")
        
        // called when user signs into spotify. Session data saved into user defaults, then notification posted to call updateAfterFirstLogin in ViewController.swift. Modeled off recommneded auth flow suggested by Spotify documentation
        
        
        if auth.canHandle(auth.redirectURL) {
            auth.handleAuthCallback(withTriggeredAuthURL: url, callback: { (error, session) in
                if error != nil {
                    print("error!")
                }
                print("auth can handle")
                let userDefaults = UserDefaults.standard
                do{
                    let sessionData = try NSKeyedArchiver.archivedData(withRootObject: session!, requiringSecureCoding: false)
                    print(sessionData)
                    userDefaults.set(sessionData, forKey: "SpotifySession")
                    userDefaults.synchronize()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "loginSuccessful"), object: nil)
                    print("notif center")
                } catch{
                    print("failed bub")
                }
            })
            return true
        }
        return false
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

