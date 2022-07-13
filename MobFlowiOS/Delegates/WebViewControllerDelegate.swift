//
//  WebViewControllerDelegate.swift
//  HTML-SDK
//
//  Created by Maarouf on 6/10/22.
//

import Foundation
import UIKit


extension MobiFlowSwift: WebViewControllerDelegate
{
   func present(dic: [String : Any])
   {
    requestPremission()
       self.delegate?.present(dic: dic)
   }
   
   func set(schemeURL: String, addressURL: String)
   {
       self.schemeURL = schemeURL
       self.addressURL = addressURL
   }
   
   func startApp()
   {
       
       DispatchQueue.main.async {
           if (self.isShowingNotificationLayout) {
               return
           }
           
           if self.isDeeplinkURL == 0 || (self.isDeeplinkURL == 1 && UserDefaults.standard.object(forKey: "deeplinkURL") != nil)
           {
               if self.schemeURL.isEmpty
               {
                   if self.customURL.isEmpty
                   {
                       self.createParamsURL()
                       //(self.isDeeplinkURL == 1) ? self.creteCustomURLWithDeeplinkParam() : self.createCustomURL()
                   }
                   let webView = self.initWebViewURL()
                   self.present(webView: webView)
               }
               else
               {
                   self.showNativeWithPermission(dic: [String : Any]())
                   let url = URL(string: self.schemeURL)
                   if UIApplication.shared.canOpenURL(url!)
                   {
                       UIApplication.shared.open(url!)
                   }
               }
           }
           else
           {
               self.showNativeWithPermission(dic: [String : Any]())
           }
       }
   }
}

