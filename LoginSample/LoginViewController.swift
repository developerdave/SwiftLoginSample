//
//  LoginViewController.swift
//  LoginSample
//
//  Created by Dave Green on 16/10/2014.
//  Copyright (c) 2014 DeveloperDave. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
  @IBOutlet weak var loginTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var loginButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
    
  @IBAction func login(sender: AnyObject) {
    var username = self.loginTextField.text
    var password = self.passwordTextField.text
    
    LoginService.sharedInstance.loginWithCompletionHandler(username, password: password) { (error) -> Void in
      
      if ((error) != nil) {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          var alert = UIAlertController(title: "Why are you doing this to me?!?", message: error, preferredStyle: .Alert)
          alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.Default, handler: nil))
          self.presentViewController(alert, animated: true, completion: nil)
        })
        
      } else {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          let controllerId = LoginService.sharedInstance.isLoggedIn() ? "Welcome" : "Login";
          
          let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
          let initViewController: UIViewController = storyboard.instantiateViewControllerWithIdentifier(controllerId) as UIViewController
          self.presentViewController(initViewController, animated: true, completion: nil)
        })
      }
    }
  }
}
