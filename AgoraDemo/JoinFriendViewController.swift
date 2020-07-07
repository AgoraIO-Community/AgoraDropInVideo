//
//  JoinFriendViewController.swift
//  AgoraDemo
//
//  Created by Jonathan  Fotland on 6/10/20.
//  Copyright © 2020 Jonathan Fotland. All rights reserved.
//

import UIKit
import Firebase

protocol JoinFriendViewControllerDelegate: NSObject {
    func didJoinFriend(uid: String)
}

class JoinFriendViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var userRef: DatabaseReference!
    var friendsRef: DatabaseReference!
    var resultsArray = [String]()
    
    var handle: AuthStateDidChangeListenerHandle?
    var currentUser: User?
    
    weak var delegate: JoinFriendViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userRef = Database.database().reference(withPath: "users")
        friendsRef = Database.database().reference(withPath: "friends")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            self.currentUser = user
            self.resultsArray.removeAll()
            self.tableView.reloadData()
            if let user = user {
                //Create an observer that will let us know when friends are added.
                self.friendsRef.child(user.uid).observe(.childAdded) { (snapshot) in
                    self.resultsArray.append(snapshot.key)
                    self.tableView.insertRows(at: [IndexPath(row: self.resultsArray.count-1, section: 0)], with: UITableView.RowAnimation.none)

                }
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
        
        if let userCell = cell as? UserTableViewCell {
            let uid = resultsArray[indexPath.row]
            userRef.child(uid).child("displayname").observeSingleEvent(of: .value) { (snapshot) in
                userCell.displayName.text = snapshot.value as? String
            }
            userRef.child(uid).child("locked").observe(.value) { (snapshot) in
                if let lockState = snapshot.value as? String, lockState == "true" {
                    userCell.detailLabel.alpha = 1
                } else {
                    userCell.detailLabel.alpha = 0
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let uid = resultsArray[indexPath.row]
        
        userRef.child(uid).child("locked").observeSingleEvent(of: .value) { (snapshot) in
            if let lockState = snapshot.value as? String, lockState == "true" {
                DispatchQueue.main.async {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                    let alert = UIAlertController(title: "Locked", message: "That user's room is currently locked.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                self.delegate?.didJoinFriend(uid: uid)
                
                self.dismiss(animated: true, completion: nil)
            }
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
