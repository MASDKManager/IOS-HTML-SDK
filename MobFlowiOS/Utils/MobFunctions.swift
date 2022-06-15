//
//  MobFunctions.swift
//  MobFlowiOS
//
//  Created by Maarouf on 6/15/22.
//

import Foundation

func currentTimeInMilliSeconds() -> String {
    let currentDate = Date()
    let since1970 = currentDate.timeIntervalSince1970
    let intTimeStamp = Int(since1970 * 1000)
    return "\(intTimeStamp)"
}
