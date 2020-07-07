//
//  ViewController.swift
//  AgoraDemo
//
//  Created by Jonathan Fotland on 9/3/19.
//  Copyright © 2019 Jonathan Fotland. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import AgoraRtcKit
import AgoraRtmKit

class AgoraVideoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, JoinFriendViewControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var switchCameraButton: UIButton!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var addFriendButton: UIButton!
    @IBOutlet weak var inviteFriendButton: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    
    let appID = "YOUR_ID_HERE"
    
    let tempToken:String? = nil
    
    var muted = false {
        didSet {
            if muted {
                muteButton.setTitle("Unmute", for: .normal)
            } else {
                muteButton.setTitle("Mute", for: .normal)
            }
        }
    }
    
    var inCall = false {
        didSet {
            lockButton.isEnabled = inCall
        }
    }
    var callID: UInt = 0 //This tells Agora to generate an id for you. We have user IDs from Firebase, but they aren't Ints, and therefore won't work with Agora.
    
    var isLocalCall = true {
        didSet {
            updateLockTitle()
        }
    }
    var callLocked = false {
        didSet {
            updateLockTitle()
        }
    }
    
    var agoraKit: AgoraRtcEngineKit?
    var userRef: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle?
    var currentUser: User?
    var channelName: String?
    
    var agoraRtm: AgoraRtmKit?
    
    var remoteUserIDs: [UInt] = []
    
    var userName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        userRef = Database.database().reference(withPath: "users")
        
        getAgoraEngine().setChannelProfile(.communication)
        
        setUpVideo()
        
        agoraRtm = AgoraRtmKit.init(appId: appID, delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            self.currentUser = user
            if let user = user {
                self.joinChannel(channelName: user.uid)
                self.agoraRtm?.login(byToken: nil, user: "Zontan") { (error) in
                    if (error != .ok) {
                        print("Failed to login to RTM: ", error.rawValue)
                    }
                }
            } else {
                self.showFUIAuthScreen()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        leaveChannel()
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func updateLockTitle() {
        if isLocalCall {
            if callLocked {
                lockButton.setTitle("Unlock", for: .normal)
            } else {
                lockButton.setTitle("Lock", for: .normal)
            }
        } else {
            lockButton.setTitle("Exit", for: .normal)
        }
    }

    private func getAgoraEngine() -> AgoraRtcEngineKit {
        if agoraKit == nil {
            agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appID, delegate: self)
        }
        return agoraKit!
    }
    
    func setUserName(name: String?) {
        userName = name
        if let name = name {
            getAgoraEngine().registerLocalUserAccount(name, appId: appID)
        }
    }
    
    func setUpVideo() {
        getAgoraEngine().enableVideo()
        let configuration = AgoraVideoEncoderConfiguration(size:
                            AgoraVideoDimension640x360, frameRate: .fps15, bitrate: 400,
                            orientationMode: .fixedPortrait)
        getAgoraEngine().setVideoEncoderConfiguration(configuration)
    }
    
    func joinChannel(channelName: String) {
        getAgoraEngine().joinChannel(byToken: tempToken, channelId: channelName, info: nil, uid: callID) { [weak self] (sid, uid, elapsed) in
            self?.inCall = true
            self?.isLocalCall = channelName == self?.currentUser?.uid
            self?.callID = uid
            self?.channelName = channelName
        }
        
    }
    
    func leaveChannel() {
        getAgoraEngine().leaveChannel(nil)
        inCall = false
        remoteUserIDs.removeAll()
        collectionView.reloadData()
    }

    @IBAction func didTapX(_ sender: Any) {
        if inCall {
            if (isLocalCall) {
                //Toggle lock on the room
                callLocked = !callLocked
                if (callLocked) {
                    userRef.child("\(currentUser!.uid)/locked").setValue("true")
                } else {
                    userRef.child("\(currentUser!.uid)/locked").setValue("false")
                }
            } else {
                leaveChannel()
                if let user = currentUser {
                    joinChannel(channelName: user.uid)
                }
            }
        }
    }
    
    
    @IBAction func didToggleMute(_ sender: Any) {
        muted = !muted
        getAgoraEngine().muteLocalAudioStream(muted)
    }
    
    @IBAction func didTapSwitchCamera(_ sender: Any) {
        getAgoraEngine().switchCamera()
    }
    
    @IBAction func didTapChat(_ sender: Any) {
        let storyboard = UIStoryboard(name: "ChatViewController", bundle: nil)
        let chatVC = storyboard.instantiateInitialViewController()!
         
        // Use the popover presentation style for your view controller.
        chatVC.modalPresentationStyle = .popover

        if let chatVC = chatVC as? ChatViewController {
            chatVC.channelName = channelName
            chatVC.agoraRtm = agoraRtm
        }

        // Present the view controller (in a popover).
        self.present(chatVC, animated: true) {
           
        }
    }
    
    @IBAction func didTapInvite(_ sender: Any) {
        let storyboard = UIStoryboard(name: "JoinFriendViewController", bundle: nil)
        let joinVC = storyboard.instantiateInitialViewController()!
         
        // Use the popover presentation style for your view controller.
        joinVC.modalPresentationStyle = .popover

        if let joinFriendVC = joinVC as? JoinFriendViewController {
            joinFriendVC.delegate = self
        }

        // Present the view controller (in a popover).
        self.present(joinVC, animated: true) {
           
        }
    }
    
    @IBAction func didTapAddFriend(_ sender: Any) {
        let storyboard = UIStoryboard(name: "UserSearchViewController", bundle: nil)
        let searchVC = storyboard.instantiateInitialViewController()!
         
        // Use the popover presentation style for your view controller.
        searchVC.modalPresentationStyle = .popover

        // Present the view controller (in a popover).
        self.present(searchVC, animated: true) {
           
        }
    }
    
    func didJoinFriend(uid: String) {
        //TODO: Check lock
        joinFriendCallWithUID(uid: uid)
    }
    
    func joinFriendCallWithUID(uid: String) {
        leaveChannel()
        joinChannel(channelName: uid)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return remoteUserIDs.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "videoCell", for: indexPath)
    
        if indexPath.row == remoteUserIDs.count { //Put our local video last
            if let videoCell = cell as? VideoCollectionViewCell {
                let videoCanvas = AgoraRtcVideoCanvas()
                videoCanvas.uid = callID
                videoCanvas.view = videoCell.videoView
                videoCanvas.renderMode = .hidden
                getAgoraEngine().setupLocalVideo(videoCanvas)
            }
        } else {
        
            let remoteID = remoteUserIDs[indexPath.row]
            if let videoCell = cell as? VideoCollectionViewCell {
                let videoCanvas = AgoraRtcVideoCanvas()
                videoCanvas.uid = remoteID
                videoCanvas.view = videoCell.videoView
                videoCanvas.renderMode = .hidden
                getAgoraEngine().setupRemoteVideo(videoCanvas)
                
                print("Creating remote view of uid: \(remoteID)")
            }
        }
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let numFeeds = remoteUserIDs.count + 1

        let totalWidth = collectionView.frame.width - collectionView.adjustedContentInset.left - collectionView.adjustedContentInset.right
        let totalHeight = collectionView.frame.height - collectionView.adjustedContentInset.top - collectionView.adjustedContentInset.bottom
        
        if numFeeds == 1 {
            return CGSize(width: totalWidth, height: totalHeight)
        } else if numFeeds == 2 {
            return CGSize(width: totalWidth, height: totalHeight / 2)
        } else {
            if indexPath.row == numFeeds {
                return CGSize(width: totalWidth, height: totalHeight / 2)
            } else {
                return CGSize(width: totalWidth / CGFloat(numFeeds - 1), height: totalHeight / 2)
            }
        }
    } 
}

extension AgoraVideoViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        callID = uid
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("Joined call of uid: \(uid)")
        remoteUserIDs.append(uid)
        collectionView.reloadData()
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        if let index = remoteUserIDs.firstIndex(where: { $0 == uid }) {
            remoteUserIDs.remove(at: index)
            collectionView.reloadData()
        }
    }
}

extension AgoraVideoViewController: AgoraRtmDelegate {
    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        if state == .connected {
            chatButton.isEnabled = true
        } else {
            chatButton.isEnabled = false
        }
    }
}

extension AgoraVideoViewController: FUIAuthDelegate {
    func showFUIAuthScreen() {
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        
        let providers: [FUIAuthProvider] = [
            FUIGoogleAuth(),
            FUIEmailAuth()
        ]
        authUI?.providers = providers
        
        if let authViewController = authUI?.authViewController() {
            navigationController?.pushViewController(authViewController, animated: false)
        }
    }
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        } else {
            
            //Save the user to our list of users.
            if let user = authDataResult?.user {
                userRef.child(user.uid).setValue(["username" : user.displayName?.lowercased(),
                                                             "displayname" : user.displayName,
                                                             "email": user.email])
            }
        }
    }
}

