//
//  ViewController.swift
//  duet
//
//  Created by ilan leventhal on 10/4/20.
//

import UIKit
import SafariServices
@_exported import AVFoundation

class ViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate{
    
    var auth = SPTAuth.defaultInstance()!
    var session: SPTSession!
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    var myplaylists = [SPTPartialPlaylist]()

    @IBOutlet var logButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        print("setup cleared")
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessful"), object: nil)
    }
    
    func setup () {
        // insert redirect your url and client ID below
        let redirectURL = "duet://returnAfterLogin" // put your redirect URL here
        let clientID = "657378f09f154f149c34d740f03930a6" // put your client ID here
        auth.redirectURL     = URL(string: redirectURL)
        auth.clientID        = clientID
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope]
        loginUrl = auth.spotifyWebAuthenticationURL()
    }
    
    func initializePlayer(authSession:SPTSession){
        print("player initialized")
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player?.start(withClientId: auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken)
        }
    }
    
    @objc func updateAfterFirstLogin () {
        print("updated after first login")
        let userDefaults = UserDefaults.standard
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            do{
                let firstTimeSession = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(sessionDataObj) as! SPTSession
                self.session = firstTimeSession
                initializePlayer(authSession: session)
                logButton.isHidden = true
                AuthService.instance.sessiontokenId = session.accessToken!
                print(AuthService.instance.sessiontokenId!)
                SPTUser.requestCurrentUser(withAccessToken: session.accessToken) { (error, data) in
                    guard let user = data as? SPTUser else { print("Couldn't cast as SPTUser"); return }
                    AuthService.instance.sessionuserId = user.canonicalUserName
                    
                    print(AuthService.instance.sessionuserId!)
                    
                }
                // Method 1 : To get current user's playlist
                SPTPlaylistList.playlists(forUser: session.canonicalUsername, withAccessToken: session.accessToken, callback: { (error, response) in
                    if let listPage = response as? SPTPlaylistList, let playlists = listPage.items as? [SPTPartialPlaylist] {
                        print(playlists)   // or however you want to parse these
                        //  self.myplaylists = playlists
                        self.myplaylists.append(contentsOf: playlists)
                        print(self.myplaylists)
                    }
                })
            } catch{
                print("failed bub")
            }
        }
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // after a user authenticates a session, the SPTAudioStreamingController is then initialized and this method called
        print("audio streaming logged in")
//        self.player?.playSpotifyURI("spotify:track:7KXjTSCq5nL1LoYtL7XAwS", startingWith: 0, startingWithPosition: 0, callback: { (error) in
//            if(error != nil){
//                print("playing")
//            }
//        })
        
    }
    
    @IBAction func loginTapped(_ sender: Any) {
        UIApplication.shared.open(loginUrl!, options: [:], completionHandler: { (x) in
            if self.auth.canHandle(self.auth.redirectURL) {
                // To do - build in error handling
            }
        })
        print("login tapped")
    }
}

class SecondViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate{
    
}



