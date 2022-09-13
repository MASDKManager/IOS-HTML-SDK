//
//  Deeplink.swift
//  MobFlowiOS
//
//  Created by Maarouf on 8/17/22.
//

import Foundation

// MARK: - Deeplink
struct Deeplink  : Codable {
    let adjustDeeplinkEnabled: Bool
    let dynamicLinksEnabled: Bool
}
 
// MARK: - Appmetrica
struct Appmetrica  : Codable {
    let enabled: Bool
    let key: String
}

// MARK: - RCAdjust
struct RCAdjust : Codable {
    let enabled: Bool
    let appToken: String
    let appInstanceIDEventToken: String
    let callbackDelay: Int
}
