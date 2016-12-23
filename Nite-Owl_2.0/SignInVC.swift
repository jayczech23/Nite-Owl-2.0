//
//  SignInVC.swift
//  Nite-Owl_2.0
//
//  Created by Jordan Cech on 12/7/16.
//  Copyright © 2016 Jordan Cech. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import FacebookLogin
import FacebookCore
import SwiftKeychainWrapper

class SignInVC: UIViewController, GIDSignInUIDelegate {

    @IBOutlet weak var emailTxtField: FancyField!
    @IBOutlet weak var passwordTxtField: FancyField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().uiDelegate = self

    }
//-----------------------------------------------------------------
    override func viewDidAppear(_ animated: Bool) {
        if let _ = KeychainWrapper.standard.string(forKey: KEY_UID) {
            print("JAY: ID FOUND IN KEYCHAIN.")
            performSegue(withIdentifier: signInSegue, sender: nil)
            
        }
        
    }
    
    
//-----------------------------------------------------------------

    @IBAction func facebookBtnTapped(_ sender: Any) {
        
        let loginManager = LoginManager()
        loginManager.logIn([ ReadPermission.publicProfile ], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login to Facebook.")
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                print("Logged in to Facebook!")
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                self.firebaseAuth(credential)
            }
        }
}
  
//-----------------------------------------------------------------
    
    @IBAction func signInBtnTapped(_ sender: Any) {
        
        guard let email = emailTxtField.text, email.characters.count > 0 && isValidEmail(testStr: email) else {
            print("Please enter valid email address.")
            return
        }
        
        guard let password = passwordTxtField.text, password.characters.count >= 6 else {
            print("Please enter a password at least 6 characters long.")
            return
        }
        
        // new user
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
            if error == nil {
                print("Successfully registered into Firebase w/ Email.")
                if let user = user {
                    let userData = ["provider": user.providerID]
                    self.completeSignIn(id: user.uid, userData: userData)
                }
            } else {
                
                // existing user
                FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
                    if error != nil {
                        print("JAY: Unable to authenticate w/ Firebase using email.")
                    } else {
                        print("JAY: Successfully SIGNED INTO FIREBASE w/ email!")
                        if let user = user {
                            let userData = ["provider": user.providerID]
                            self.completeSignIn(id: user.uid, userData: userData)
                        }
                    }
                })
            }
        })
        
    }
//-----------------------------------------------------------------
    // 2. Authenticate with Firebase.
    func firebaseAuth(_ credential: FIRAuthCredential) {
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("JAY: Unable to authenticate with Firebase.")
            
            }else {
                print("JAY: Successfully authenticated w/ Firebase!")
                if let user = user {
                    let userData = ["provider": credential.provider]
                    self.completeSignIn(id: user.uid, userData: userData)
                }
            }
        })
    }
//-----------------------------------------------------------------
    
    func isValidEmail(testStr: String) -> Bool {
        
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    
    }
//-----------------------------------------------------------------
    
    @IBAction func googleBtnTapped(_ sender: Any) {
        
        GIDSignIn.sharedInstance().signIn()
    }
//-----------------------------------------------------------------
    
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        
        DataService.ds.createFirebaseDBUser(uid: id, userData: userData)
        
        let keyChainResult = KeychainWrapper.standard.set(id, forKey: KEY_UID)
        print("JAY: data saved to keychain? \(keyChainResult)")
        performSegue(withIdentifier: signInSegue, sender: nil)
        
    }
//-----------------------------------------------------------------
    
    
    
 
}
