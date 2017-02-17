//
//  LoginViewController.swift
//  GoChat
//
//  Created by Kristoffer Nielsen on 14/02/2017.
//  Copyright © 2017 Kristoffer Nielsen. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseAuth
import FirebaseStorage

class LoginViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {
    
    @IBOutlet weak var usernameInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // Create white border around login anonymously button
        
        GIDSignIn.sharedInstance().clientID = "47932553944-c1ittkl6ec7t8jatpca4mrre8l7ltfc2.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        FIRAuth.auth()?.addStateDidChangeListener( { (auth, user) in
            if user != nil {
                Helper.helper.switchToNavigationViewController()
            } else {
                
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginEmailDidTapped(_ sender: Any) {
        print("login email did tapped")
        
        Helper.helper.loginEmail(email: usernameInput.text!, password: passwordInput.text!)
    }
    
    //    @IBAction func loginAnonymouslyDidTapped(_ sender: Any) {
    //        print("login anonymously did tapped")
    //
    //        Helper.helper.loginAnonymously()
    //    }
    
    @IBAction func loginGoogleDidTapped(_ sender: Any) {
        print("login google did tapped")
        
        GIDSignIn.sharedInstance().signIn()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            print(error!.localizedDescription)
            return
        }
        print(user.authentication)
        Helper.helper.loginGoogle(authentication: user.authentication)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
