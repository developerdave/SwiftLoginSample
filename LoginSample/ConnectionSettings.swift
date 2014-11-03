//
//  ConnectionSettings.swift
//  LoginSample
//
//  Created by Dave Green on 03/11/2014.
//  Copyright (c) 2014 DeveloperDave. All rights reserved.
//

import Foundation

public struct ConnectionSettings {
  
  static var clientId = "yA0ac1klHaXYDJ5HPHN4sVVxpX1Vem1A"
  static var clientSecret = "zJA8WNmmxe4UXR0G"
  static var apiBaseUrl = "http://developerdave-test.apigee.net"
  
  public static func apiURLWithPathComponents(components: String) -> NSURL {
    let baseUrl = NSURL(string: ConnectionSettings.apiBaseUrl)
    let APIUrl = NSURL(string: components, relativeToURL: baseUrl)
    
    return APIUrl!
  }
}
