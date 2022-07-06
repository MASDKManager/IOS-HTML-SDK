//
//  NotificationLayoutDelegate.swift
//  HTML-SDK
//
//  Created by Maarouf on 6/10/22.
//

import Foundation


extension MobiFlowSwift : NotificationLayoutDelegate
{
    func closeNotificationLayout() {
        print("close Notification Layout received in MobFlow Swift SDK.")
        isShowingNotificationLayout = false
        self.startApp()
    }
    
}
