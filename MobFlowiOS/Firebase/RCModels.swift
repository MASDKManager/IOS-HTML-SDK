//
//  Deeplink.swift
//  MobFlowiOS
//
//  Created by Maarouf on 8/17/22.
//

import Foundation

// MARK: - Deeplink
struct RCDeeplink  : Codable {
    let adjustDeeplinkEnabled: Bool
    let dynamicLinksEnabled: Bool
}
 
// MARK: - Appmetrica
struct RCAppmetrica  : Codable {
    let enabled: Bool
    let key: String
}

// MARK: - RCAdjust
struct RCAdjust : Codable {
    let enabled: Bool
    let appToken: String
    let appInstanceIDEventToken: String
    let attrLogEventToken: String
    let callbackDelay: Int
    let sdk_signature: String
}

// MARK: - RCTikTok
struct RCTikTok : Codable {
    let enabled: Bool
    let accessToken: String
    let appId: String
    let tiktokAppId: NSNumber
    let sdkPrefix: String
    let eventName: String
}

struct RCSdkSignature : Codable {
    let secretID : UInt
    let info1 : UInt
    let info2 : UInt
    let info3 : UInt
    let info4 : UInt
}
