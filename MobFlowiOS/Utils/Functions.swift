//
//  Functions.swift
//  MobFlowiOS
//
//  Created by Maarouf on 7/6/22.
//

import Foundation
import AppTrackingTransparency
import FirebaseCore
import FirebaseAnalytics
  
let USERDEFAULT_CustomUUID = "USERDEFAULT_CustomUUID"
let USERDEFAULT_DidWaitForAdjustAttribute = "USERDEFAULT_DidWaitForAdjustAttribute"

func currentTimeInMilliSeconds() -> String {
    let currentDate = Date()
    let since1970 = currentDate.timeIntervalSince1970
    let intTimeStamp = Int(since1970 * 1000)
    return "\(intTimeStamp)"
}

func fetchDataWithUrl(urlString: String, completionHendler:@escaping (_ response:Dictionary<String,AnyObject>?, _ success: Bool)-> Void) {
    
    if let url = URL(string: urlString) {
        
        var urlRequest = URLRequest(url: url)
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.timeoutInterval = 60
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest, completionHandler: { data, response, error -> Void in
            do {
                if (data == nil){
                    completionHendler([:],false)
                } else {
                    if let json = try JSONSerialization.jsonObject(with: data!) as? Dictionary<String, AnyObject> {
                        completionHendler(json,true)
                    } else {
                        completionHendler([:],false)
                    }
                }
            } catch {
                completionHendler([:],false)
            }
        })
        
        task.resume()
    }
}

func requestPremission()
{
    if #available(iOS 14, *)
    {
        ATTrackingManager.requestTrackingAuthorization { (authStatus) in
            switch authStatus
            {
            case .notDetermined:
                print("Not Determined")
            case .restricted:
                print("Restricted")
            case .denied:
                print("Denied")
            case .authorized:
                print("Authorized")
            @unknown default:
                break
            }
        }
    }
}

func generateUserUUID() -> String {
    
    var md5UUID = getUserUUID()
    
    if (md5UUID == "") {
        var uuid = ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let customTimeStamp = currentTimeInMilliSeconds()
        
        uuid = deviceId + customTimeStamp
        
        md5UUID = uuid.md5()
        saveUserUUID(value: md5UUID)
    }
    
    return md5UUID
}

func getUserUUID() -> String {
    return UserDefaults.standard.string(forKey: USERDEFAULT_CustomUUID) ?? ""
}

func saveUserUUID(value:String) {
    return UserDefaults.standard.set(value, forKey: USERDEFAULT_CustomUUID)
}

func logEvent(eventName : String, log : String){
    
    let parameter = [
        "parameter": log as NSObject
    ]
    
    Analytics.logEvent(eventName, parameters: parameter)
    
}
