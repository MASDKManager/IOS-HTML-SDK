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
        printMobLog(description: "attribution adid", value: attribution?.adid ?? "")
        _ = Adjust.adid();
        logEvent(eventName: "adid_received", log: "")
    }
    
    public func adjustEventTrackingSucceeded(_ eventSuccessResponseData: ADJEventSuccess?)
    {
        printMobLog(description: "adjust Event Tracking Succeeded", value: eventSuccessResponseData?.jsonResponse.description ?? "")
//        print(eventSuccessResponseData?.jsonResponse ?? [:])
        logEvent(eventName: "adjustEventTrackingSucceeded", log: eventSuccessResponseData?.message ?? "")
    }

    public func adjustEventTrackingFailed(_ eventFailureResponseData: ADJEventFailure?)
    {
        printMobLog(description: "adjust Event Tracking Failed", value: eventFailureResponseData?.jsonResponse.description ?? "")
//      print(eventFailureResponseData?.jsonResponse ?? [:])
        logEvent(eventName: "adjustEventTrackingFailed", log: eventFailureResponseData?.message ?? "")
    }
    
    public func adjustSessionTrackingSucceeded(_ sessionSuccessResponseData: ADJSessionSuccess?)
    {
        printMobLog(description: "adjust Session Tracking Succeeded", value: sessionSuccessResponseData?.jsonResponse?.description ?? "")
//        print(sessionSuccessResponseData?.jsonResponse ?? [:])
        logEvent(eventName: "adjustSessionTrackingSucceeded", log: sessionSuccessResponseData?.message ?? "")
    }
    
    public func adjustSessionTrackingFailed(_ sessionFailureResponseData: ADJSessionFailure?)
    {
        printMobLog(description: "adjust Session Tracking Failed", value: sessionFailureResponseData?.jsonResponse?.description ?? "")
//      print(sessionFailureResponseData?.jsonResponse ?? [:])
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
        printMobLog(description: "handle Deeplink", value: url?.description ?? "")
        UserDefaults.standard.setValue(url?.absoluteString, forKey: "deeplinkURL")
        UserDefaults.standard.synchronize()

    }
}
