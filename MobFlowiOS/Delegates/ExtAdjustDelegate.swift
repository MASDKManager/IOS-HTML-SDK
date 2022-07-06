//
//  AdjustDelegate.swift
//  HTML-SDK
//
//  Created by Maarouf on 6/10/22.
//

import Foundation
import Adjust

extension MobiFlowSwift: AdjustDelegate
{
    public func adjustAttributionChanged(_ attribution: ADJAttribution?)
    {
        print(attribution?.adid ?? "")
        logEvent(eventName: "adid_received", log: "")
    }
    
    public func adjustEventTrackingSucceeded(_ eventSuccessResponseData: ADJEventSuccess?)
    {
        print(eventSuccessResponseData?.jsonResponse ?? [:])
        logEvent(eventName: "adjustEventTrackingSucceeded", log: eventSuccessResponseData?.message ?? "")
    }

    public func adjustEventTrackingFailed(_ eventFailureResponseData: ADJEventFailure?)
    {
      print(eventFailureResponseData?.jsonResponse ?? [:])
        logEvent(eventName: "adjustEventTrackingFailed", log: eventFailureResponseData?.message ?? "")
    }
    
    public func adjustSessionTrackingSucceeded(_ sessionSuccessResponseData: ADJSessionSuccess?)
    {
        print(sessionSuccessResponseData?.jsonResponse ?? [:])
        logEvent(eventName: "adjustSessionTrackingSucceeded", log: sessionSuccessResponseData?.message ?? "")
    }
    
    public func adjustSessionTrackingFailed(_ sessionFailureResponseData: ADJSessionFailure?)
    {
      print(sessionFailureResponseData?.jsonResponse ?? [:])
        logEvent(eventName: "adjustSessionTrackingFailed", log: sessionFailureResponseData?.message ?? "")
    }
    
    public func adjustDeeplinkResponse(_ deeplink: URL?) -> Bool
    {
        logEvent(eventName: "adjustDeeplinkResponse", log:   "")
        handleDeeplink(deeplink: deeplink)
        return true
    }
    
    // MARK: - HANDLE Deeplink response
    private func handleDeeplink(deeplink url: URL?)
    {
        print("Handling Deeplink")
        print(url?.absoluteString ?? "Not found")
        UserDefaults.standard.setValue(url?.absoluteString, forKey: "deeplinkURL")
        UserDefaults.standard.synchronize()
        startApp()
    }
}
