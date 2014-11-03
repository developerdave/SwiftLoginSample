//
//  WelcomeViewController.swift
//  LoginSample
//
//  Created by Dave Green on 03/11/2014.
//  Copyright (c) 2014 DeveloperDave. All rights reserved.
//

import UIKit

class WelcomeViewController : UIViewController {
  @IBOutlet weak var signOutButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  @IBAction func signOut(sender: AnyObject) {
    LoginService.sharedInstance.signOut()
    
    let controllerId = LoginService.sharedInstance.isLoggedIn() ? "Welcome" : "Login";
    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let initViewController: UIViewController = storyboard.instantiateViewControllerWithIdentifier(controllerId) as UIViewController
    self.presentViewController(initViewController, animated: true, completion: nil)
  }
}
