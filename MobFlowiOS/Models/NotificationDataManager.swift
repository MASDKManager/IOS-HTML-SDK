//
//  NotificationDataManager.swift
//  MobFlowiOS
//
//  Created by Maarouf on 7/6/22.
//

import Foundation

struct NotificationDataManager {
    var title = ""
    var body = ""
    var action_id = ""
    var show_landing_page : Bool
    var landing_layout = ""
    var link = ""
    var deeplink = ""
    var show_close_button : Bool
    var image = ""
    var show_toolbar_webview : Bool
    
    init(title : String, body : String, action_id : String,show_landing_page : String, landing_layout : String, link : String,  deeplink : String, show_close_button : String, image : String, show_toolbar_webview : String) {
        
        self.title = title
        self.body = body
        self.action_id = action_id
        self.deeplink = deeplink
        self.show_close_button = (show_close_button == "true")
        self.image = image
        self.show_toolbar_webview = (show_toolbar_webview == "true")
        self.show_landing_page = (show_landing_page == "true")
        self.landing_layout = landing_layout
    }
}
