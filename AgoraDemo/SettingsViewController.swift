//
//  SettingsViewController.swift
//  AgoraDemo
//
//  Created by Jonathan Fotland on 9/17/19.
//  Copyright © 2019 Jonathan Fotland. All rights reserved.
//

import UIKit
import Firebase

class SettingsViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                self.nameTextField.text = user?.displayName
            } else {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func showErrorAlert(error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
        
        let alert = UIAlertController(title: "Error", message: "Something went wrong. Please try again.", preferredStyle: .alert)
        self.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
            alert.dismiss(animated: true)
        })
    }
    
    @IBAction func didTapLogout(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func didTapSave(_ sender: Any) {
        guard let user = Auth.auth().currentUser else {
            showErrorAlert(error: nil)
            return
        }
        
        let newName = nameTextField.text
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newName
        changeRequest.commitChanges { (error) in
            if let error = error {
                self.showErrorAlert(error: error)
            } else {
                let ref = Database.database().reference()
                ref.child("users/\(user.uid)/username").setValue(newName?.lowercased())
                ref.child("users/\(user.uid)/displayname").setValue(newName)
                
                let alert = UIAlertController(title: "Success", message: "Your changes have been saved.", preferredStyle: .alert)
                self.present(alert, animated: true)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                    alert.dismiss(animated: true, completion: {
                        self.navigationController?.popViewController(animated: true)
                    })
                })
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
