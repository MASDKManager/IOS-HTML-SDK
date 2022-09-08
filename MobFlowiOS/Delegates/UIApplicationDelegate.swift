//
//  UIApplicationDelegate.swift
//  HTML-SDK
//
//  Created by Maarouf on 6/10/22.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseDynamicLinks

extension MobiFlowSwift : UIApplicationDelegate
{
     
    // MARK: UISceneSession Lifecycle
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
          
      let handled = DynamicLinks.dynamicLinks()
        .handleUniversalLink(userActivity.webpageURL!) { dynamiclink, error in
         
        }

        
      return handled
    }
    
    
    @available(iOS 9.0, *)
    public func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
          
      return application(app, open: url,
                         sourceApplication: options[UIApplication.OpenURLOptionsKey
                           .sourceApplication] as? String,
                         annotation: "")
    }

    public func application(_ application: UIApplication, open url: URL, sourceApplication: String?,
                     annotation: Any) -> Bool {
      if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
          
          //print(dynamicLink.url?.absoluteString)
          UserDefaults.standard.setValue(dynamicLink.url?.absoluteString ?? "", forKey: "dynamiclinkURL")
          UserDefaults.standard.synchronize()
           
        return true
      }
      return false
    }
     
    
}
