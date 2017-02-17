//
//  Helper.swift
//  GoChat
//
//  Created by Kristoffer Nielsen on 14/02/2017.
//  Copyright © 2017 Kristoffer Nielsen. All rights reserved.
//

import Foundation
import FirebaseAuth
import UIKit
import GoogleSignIn
import FirebaseDatabase

class Helper {
    
    static let helper = Helper()
    
    func loginEmail(email: String, password: String) {
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            if error == nil {
                self.switchToNavigationViewController()
            } else {
                print(error!.localizedDescription)
            }
        })
    }
    
//    func loginAnonymously() {
//        FIRAuth.auth()?.signInAnonymously(completion: { (anonymousUser, error) in
//            if error == nil {
//                let newUser = FIRDatabase.database().reference().child("users").child(anonymousUser!.uid)
//                newUser.setValue(["displayName": "Anonymous", "id": "\(anonymousUser!.uid)", "profileUrl": ""])
//                
//                self.switchToNavigationViewController()
//            } else {
//                print(error!.localizedDescription)
//            }
//        })
//        
//    }
    
    func loginGoogle(authentication: GIDAuthentication) {
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        FIRAuth.auth()?.signIn(with: credential, completion: { (user: FIRUser?, error) in
            if error == nil {
                
                let newUser = FIRDatabase.database().reference().child("users").child(user!.uid)
                newUser.setValue(["displayName": "\(user!.displayName!)", "id": "\(user!.uid)", "profileUrl": "\(user!.photoURL!)"])
                
                self.switchToNavigationViewController()
            } else {
                print(error!.localizedDescription)
            }
        })
    }
    
    public func switchToNavigationViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let naviVC = storyboard.instantiateViewController(withIdentifier: "NavigationVC") as! UINavigationController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appDelegate.window?.rootViewController = naviVC
    }
    
}
