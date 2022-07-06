//
//  MobiFlowDelegate.swift
//  HTML-SDK
//
//  Created by Maarouf on 6/10/22.
//

import Foundation

@objc public protocol MobiFlowDelegate
{
    func present(dic: [String: Any])
    func unloadUnityOnNotificationClick()
}
