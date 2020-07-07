//
//  ChatViewController.swift
//  AgoraDemo
//
//  Created by Jonathan  Fotland on 6/11/20.
//  Copyright © 2020 Jonathan Fotland. All rights reserved.
//

import UIKit
import AgoraRtmKit
import Firebase

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    weak var agoraRtm: AgoraRtmKit?
    var channelName: String?
    var channel: AgoraRtmChannel?
    
    var handle: AuthStateDidChangeListenerHandle?
    var currentUser: User?
    
    var messageList: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        textField.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            self.currentUser = user
            if user != nil, let channelName = self.channelName {
                self.channel = self.agoraRtm?.createChannel(withId: channelName, delegate: self)
                self.channel?.join(completion: { (error) in
                    if error != .channelErrorOk {
                        print("Error joining channel: ", error.rawValue)
                    }
                })
            } else {
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardFrame = keyboardSize.cgRectValue
        
        bottomConstraint.constant = 20 + keyboardFrame.height
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        bottomConstraint.constant = 20
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath)
        
        if let chatCell = cell as? ChatTableViewCell {
            let message = messageList[indexPath.row]
            chatCell.messageLabel.text = message
        }
        
        return cell
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text, text != "" {
            channel?.send(AgoraRtmMessage(text: text), completion: { (error) in
                if error != .errorOk {
                    print("Failed to send message: ", error)
                }
            })
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ChatViewController: AgoraRtmChannelDelegate {
    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        let message = "\(member.userId): \(message.text)"
        messageList.append(message)
        self.tableView.insertRows(at: [IndexPath(row: self.messageList.count-1, section: 0)], with: UITableView.RowAnimation.automatic)
    }
}
