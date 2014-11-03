//
//  LoginService.swift
//  LoginSample
//
//  Created by Dave Green on 03/11/2014.
//  Copyright (c) 2014 DeveloperDave. All rights reserved.
//

import UIKit

public class LoginService : NSObject {
    
    // MARK: Properties
    
    internal let session:NSURLSession!
    private var tokenInfo:OAuthInfo!
    
    
    // MARK: Types
    
    struct OAuthInfo {
        let token: String!
        let tokenExpiresAt: NSDate!
        let refreshToken: String!
        let refreshTokenExpiresAt: NSDate!
        
        
        // MARK: Initializers
        
        init(issuedAt: NSTimeInterval, refreshTokenIssuedAt: NSTimeInterval, tokenExpiresIn: NSTimeInterval, refreshToken: String, token: String, refreshTokenExpiresIn: Double, refreshCount: Int) {
            
            // Store OAuth token and associated data
            self.refreshTokenExpiresAt = NSDate(timeInterval: refreshTokenExpiresIn, sinceDate: NSDate(timeIntervalSince1970: issuedAt))
            self.tokenExpiresAt = NSDate(timeInterval: tokenExpiresIn, sinceDate: NSDate(timeIntervalSince1970: issuedAt))
            self.token = token
            self.refreshToken = refreshToken
            
            // Persist the OAuth token and associated data to NSUserDefaults
            NSUserDefaults.standardUserDefaults().setObject(self.refreshTokenExpiresAt, forKey: "refreshTokenExpiresAt")
            NSUserDefaults.standardUserDefaults().setObject(self.tokenExpiresAt, forKey: "tokenExpiresAt")
            NSUserDefaults.standardUserDefaults().setObject(self.token, forKey: "token")
            NSUserDefaults.standardUserDefaults().setObject(self.refreshToken, forKey: "refreshToken")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        init() {
            // Retrieve OAuth info from NSUserDefaults if available
            if let refreshTokenExpiresAt = NSUserDefaults.standardUserDefaults().valueForKey("refreshTokenExpiresAt") as? NSDate {
                self.refreshTokenExpiresAt = refreshTokenExpiresAt
            }
            if let tokenExpiresAt = NSUserDefaults.standardUserDefaults().valueForKey("tokenExpiresAt") as? NSDate {
                self.tokenExpiresAt = tokenExpiresAt
            }
            if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
                self.token = token
            }
            if let refreshToken = NSUserDefaults.standardUserDefaults().valueForKey("refreshToken") as? String {
                self.refreshToken = refreshToken
            }
        }
        
        
        // MARK: Sign Out
        
        func signOut() -> () {
            
            // Clear OAuth Info from NSUserDefaults
            NSUserDefaults.standardUserDefaults().removeObjectForKey("refreshTokenExpiresAt")
            NSUserDefaults.standardUserDefaults().removeObjectForKey("tokenExpiresAt")
            NSUserDefaults.standardUserDefaults().removeObjectForKey("token")
            NSUserDefaults.standardUserDefaults().removeObjectForKey("refreshToken")
        }
    }
    
    
    // MARK: Singleton Support
    
    class var sharedInstance : LoginService {
        struct Singleton {
            static let instance = LoginService()
        }
        
        // Check whether we already have an OAuthInfo instance
        // attached, if so don't initialiaze another one
        if Singleton.instance.tokenInfo == nil {
            // Initialize new OAuthInfo object
            Singleton.instance.tokenInfo = OAuthInfo()
        }
        
        // Return singleton instance
        return Singleton.instance
    }
    
    
    // MARK: Initializers
    
    override init() {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        super.init()
        
        session = NSURLSession(configuration: sessionConfig)
        
        // Ensure we only have one instance of this class and that it is the Singleton instance
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(0.1 * Double(NSEC_PER_SEC))
            ), dispatch_get_main_queue()) {
                assert(self === LoginService.sharedInstance, "Only one instance of LoginManager allowed!")
        }
    }
    
    
    // MARK: Login Utilities
    
    public func loginWithCompletionHandler(username: String, password: String, completionHandler: ((error: String?) -> Void)!) -> () {
        
        // Try and get an OAuth token
        exchangeTokenForUserAccessTokenWithCompletionHandler(username, password: password) { (oauthInfo, error) -> () in
            if (error == nil) {
                
                // Everything worked and OAuthInfo was returned
                self.tokenInfo = oauthInfo!
                completionHandler(error: nil)
            } else {
                
                // Something went wrong
                self.tokenInfo = nil
                completionHandler(error: error)
            }
        }
    }
    
    public func signOut() {
        
        // Clear the OAuth Info
        self.tokenInfo.signOut()
        self.tokenInfo = nil
    }
    
    public func isLoggedIn() -> Bool {
        var loggedIn:Bool = false
        if let info = self.tokenInfo {
            if let tokenExpiresAt = info.tokenExpiresAt {
                
                // Check to see OAuth token is still valid
                if fabs(tokenExpiresAt.timeIntervalSinceNow) > 60 {
                    loggedIn = true
                }
            }
        }
        
        return loggedIn
    }
    
    
    // MARK: Token Utilities
    
    public func token() -> String {
        if isLoggedIn() {
            return self.tokenInfo.token
        } else {
            return ""
        }
    }
    
    public func refreshToken() -> String {
        var refreshToken: String = ""
        
        if self.tokenInfo != nil {
            if fabs(self.tokenInfo.refreshTokenExpiresAt.timeIntervalSinceNow) > 60 {
                refreshToken = self.tokenInfo.refreshToken
            }
        }
        
        return refreshToken
    }
    
    
    // MARK: Private Methods
    
    private func exchangeTokenForUserAccessTokenWithCompletionHandler(username: String, password: String, completion: (OAuthInfo?, error: String?) -> ()) {
        
        let path = "/oauthfake/token/"
        let url = ConnectionSettings.apiURLWithPathComponents(path)
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        
        var params =  "client_id=\(ConnectionSettings.clientId)&client_secret=\(ConnectionSettings.clientSecret)&grant_type=password&login=\(username)&password=\(password)"
        
        var err: NSError?
        request.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        
        let task = session.dataTaskWithRequest(request) {data, response, error -> Void in
            
            var err: NSError?
            var json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &err) as? NSDictionary
            
            if (err != nil) {
                
                // Something went wrong, log the error to the console.
                println(err!.localizedDescription)
                let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                println("Something went wrong: '\(jsonStr)")
                
                
                completion(nil, error: err?.localizedDescription)
            } else {
                if let parseJSON = json {
                    if let token = parseJSON.valueForKey("access_token") as? String {
                        if var issuedAt = parseJSON.valueForKey("issued_at") as? String {
                            if var tokenExpiresIn = parseJSON.valueForKey("expires_in") as? String {
                                if var refreshTokenIssuedAt = parseJSON.valueForKey("refresh_token_issued_at") as? String {
                                    if let refreshToken = parseJSON.valueForKey("refresh_token") as? String {
                                        if var refreshTokenExpiresIn = parseJSON.valueForKey("refresh_token_expires_in") as? String {
                                            if let refreshCount = parseJSON.valueForKey("refresh_count") as? String {
                                                
                                                let epochIssuedAt:Double = (issuedAt as NSString).doubleValue / 1000.0
                                                let epochRefreshTokenIssuedAt:Double = (refreshTokenIssuedAt as NSString).doubleValue / 1000.0
                                                
                                                let oauthInfo = OAuthInfo(issuedAt: epochIssuedAt, refreshTokenIssuedAt: epochRefreshTokenIssuedAt, tokenExpiresIn: (tokenExpiresIn as NSString).doubleValue, refreshToken: refreshToken, token: token, refreshTokenExpiresIn: (refreshTokenExpiresIn as NSString).doubleValue, refreshCount: (refreshCount as NSString).integerValue)
                                                
                                                completion(oauthInfo, error: err?.localizedDescription)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if let error = parseJSON["error"] as? String {
                        completion(nil, error: error)
                    }
                }
            }
        }
        task.resume()
    }
    
}
