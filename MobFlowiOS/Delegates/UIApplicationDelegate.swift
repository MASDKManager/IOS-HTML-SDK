//
//  UIApplicationDelegate.swift
//  HTML-SDK
//
//  Created by Maarouf on 6/10/22.
//

import Foundation
import UIKit

extension MobiFlowSwift: UIApplicationDelegate
{
   
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    {
        
        self.referrerURL = userActivity.referrerURL?.absoluteString ?? ""
      
        return false
    }
}
