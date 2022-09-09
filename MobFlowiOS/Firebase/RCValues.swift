//
//  NotificationDataManager.swift
//  MobFlowiOS
//
//  Created by Maarouf on 7/6/22.
//

import Foundation
import FirebaseCore
import FirebaseRemoteConfig

enum ValueKey: String {
    case sub_endu
    case adjst
    case appmetrica
    case deeplink
}

class RCValues {
    static let sharedInstance = RCValues()
    var loadingDoneCallback: (() -> Void)?
    var fetchComplete = false
    //var rCAdjust :RCAdjust
    
    private init() {
        loadDefaultValues()
        fetchCloudValues()
    }
    
    func loadDefaultValues() {
        let appDefaults: [String: Any?] = [
            ValueKey.sub_endu.rawValue: "",
            ValueKey.adjst.rawValue: "",
            ValueKey.appmetrica.rawValue: "",
            ValueKey.deeplink.rawValue: ""
        ]
        RemoteConfig.remoteConfig().setDefaults(appDefaults as? [String: NSObject])
    }
    
    func fetchCloudValues() {
        activateDebugMode()
          
        RemoteConfig.remoteConfig().fetch { [weak self] (status, error) -> Void in
            if status == .success {
                print("Config fetched!")
                
                RemoteConfig.remoteConfig().activate { [weak self] changed, error in
                  
                    DispatchQueue.main.async {
                        self?.fetchComplete = true
                        self?.loadingDoneCallback?()
                    }
                }
            } else {
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "No error available.")")
            }
            
        }
        
    }
    
    func activateDebugMode() {
        let settings = RemoteConfigSettings()
        // WARNING: Don't actually do this in production!
        settings.minimumFetchInterval = 0
        RemoteConfig.remoteConfig().configSettings = settings
    }
    
    func getDeeplink() -> Deeplink {
        let deeplinkJson = RCValues.sharedInstance.string(forKey: .deeplink)
        let deeplinkData = Data(deeplinkJson.utf8)
        let deeplink = try! JSONDecoder().decode(Deeplink.self, from: deeplinkData)
         
        return deeplink
    }
    
    func getAppmetrica() -> Appmetrica {
        let appmetricaJson = RCValues.sharedInstance.string(forKey: .appmetrica)
        let appmetricaData = Data(appmetricaJson.utf8)
        let appmetrica = try! JSONDecoder().decode(Appmetrica.self, from: appmetricaData)
        return appmetrica
    }
    
    func getAdjust() -> RCAdjust {
        let rCAdjustJson = RCValues.sharedInstance.string(forKey: .adjst)
        let rCAdjustData = Data(rCAdjustJson.utf8)
        let rCAdjust = try! JSONDecoder().decode(RCAdjust.self, from: rCAdjustData)
        
        return rCAdjust
    }
     
    func bool(forKey key: ValueKey) -> Bool {
        RemoteConfig.remoteConfig()[key.rawValue].boolValue
    }
    
    func string(forKey key: ValueKey) -> String {
        RemoteConfig.remoteConfig()[key.rawValue].stringValue ?? ""
    }
    
    func double(forKey key: ValueKey) -> Double {
        RemoteConfig.remoteConfig()[key.rawValue].numberValue.doubleValue
    }
}