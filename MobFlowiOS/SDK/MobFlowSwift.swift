import UIKit
import AppTrackingTransparency
import AdSupport
import FirebaseCore
import FirebaseAnalytics
import YandexMobileMetrica
 
public class MobiFlowSwift: NSObject
{
    
    let mob_sdk_version = "1.6.1"
    var isAppmetrica = false
    var isDeeplinkURL = false
    var isUnityApp = false
    var endpoint = ""
    var rcAdjust : RCAdjust!
    var appmetricaKey = ""
    var referrerURL = ""
    var customURL = ""
    var schemeURL = ""
    var addressURL = ""
    var faid = ""
    var params = ""
    var delay = 0.0
    var run = true
    var use_only_deeplink = false
    var AppMetricaDeviceID = ""
    public var hideToolbar = false
    var isShowingNotificationLayout = false
    var timer = Timer()
    public var delegate : MobiFlowDelegate? = nil
    public var backgroundColor = UIColor.white
    public var tintColor = UIColor.black
 
    let nc = NotificationCenter.default
    
    
    @objc public init(initDelegate: MobiFlowDelegate, isUnityApp: Bool)
    {
        super.init()
        self.isUnityApp = isUnityApp
        self.delegate = initDelegate
        self.initialiseSDK()
    }
    
    public init(initDelegate: MobiFlowDelegate) {
        super.init()
        self.delegate = initDelegate
        self.initialiseSDK()
    }
    
    private func initialiseSDK() {
        
        FirebaseApp.configure()
        
        if RCValues.sharedInstance.fetchComplete {
            getRC()
        }else{
            RCValues.sharedInstance.loadingDoneCallback = getRC
        }
        
    }
    
    func getRC() {

        if(RCValues.sharedInstance.string(forKey: .sub_endu) != ""){
            self.isAppmetrica = RCValues.sharedInstance.getAppmetrica().enabled
            self.appmetricaKey = RCValues.sharedInstance.getAppmetrica().key
            self.rcAdjust = RCValues.sharedInstance.getAdjust()
            self.isDeeplinkURL =   RCValues.sharedInstance.getDeeplink().adjustDeeplinkEnabled ||  RCValues.sharedInstance.getDeeplink().dynamicLinksEnabled
            self.endpoint = RCValues.sharedInstance.string(forKey: .sub_endu)
            self.params = RCValues.sharedInstance.string(forKey: .params)
            self.delay = RCValues.sharedInstance.double(forKey: .delay)
            self.use_only_deeplink = RCValues.sharedInstance.bool(forKey: .use_only_deeplink)
            self.run = RCValues.sharedInstance.bool(forKey: .run)
            self.faid = Analytics.appInstanceID() ?? ""
            
            printMobLog(description: "self.isAppmetrica", value: String(self.isAppmetrica))
            printMobLog(description: "self.appmetricaKey", value: self.appmetricaKey)
            printMobLog(description: "self.isDeeplinkURL", value: String(self.isDeeplinkURL))
            printMobLog(description: "self.endpoint", value: self.endpoint.description)
            printMobLog(description: "self.params", value: self.params.description)
            printMobLog(description: "self.delay", value: String(self.delay))
            printMobLog(description: "self.use_only_deeplink", value: String(self.use_only_deeplink))
            printMobLog(description: "self.run", value: String(self.run))
            printMobLog(description: "self.faid", value: self.faid)
            
            self.initialTrackingAndSetup()
        }else{
            self.showNativeWithPermission(dic: [String : Any]())
        }
    }
    
    
    private func initialTrackingAndSetup() {
        
        if self.isAppmetrica
        {
            
            printMobLog(description: "App Metrica initiate called with key", value: self.appmetricaKey)
            nc.addObserver(self, selector: #selector(onDataReceived), name: Notification.Name("AppMetricaDeviceIDReceived"), object: nil)
            
            let configuration = YMMYandexMetricaConfiguration.init(apiKey: self.appmetricaKey)
            configuration?.preloadInfo?.setAdditional(generateUserUUID(), forKey: "uuid")
            YMMYandexMetrica.activate(with: configuration!)
            
            YMMYandexMetrica.requestAppMetricaDeviceID(withCompletionQueue: .main) { [unowned self] id, error in
                self.AppMetricaDeviceID = id ?? ""
                nc.post(name: Notification.Name("AppMetricaDeviceIDReceived"), object: nil)
                
            }
            
        }
        
        if self.rcAdjust.enabled
        {
            printMobLog(description: "Adjust initiate called with token", value: self.rcAdjust.appToken)
            let adjustConfig = ADJConfig(appToken: self.rcAdjust.appToken, environment: ADJEnvironmentProduction)
            
            adjustConfig?.sendInBackground = true
            adjustConfig?.delegate = self
            adjustConfig?.linkMeEnabled = true
            
            adjustConfig?.delayStart = Double(self.rcAdjust.callbackDelay)
            
            Adjust.appDidLaunch(adjustConfig)
            
            Adjust.addSessionCallbackParameter("m_sdk_ver", value: mob_sdk_version)
            Adjust.addSessionCallbackParameter("click_id", value: generateUserUUID())
            Adjust.addSessionCallbackParameter("firebase_instance_id", value: self.faid)
            
            let adjustEvent = ADJEvent(eventToken: self.rcAdjust.appInstanceIDEventToken)
            adjustEvent?.addCallbackParameter("eventValue", value: self.faid) //firebase Instance Id
            adjustEvent?.addCallbackParameter("click_id", value: generateUserUUID())
            
            Adjust.trackEvent(adjustEvent)
            
        }
        
        if !self.isAppmetrica
        {
            self.onDataReceived()
        }
    }
    
    @objc private func onDataReceived(){
        if (endpoint != "") {
            let packageName = Bundle.main.bundleIdentifier ?? ""
            let apiString = "\(endpoint.hasPrefix("http") ? endpoint : "https://" + endpoint)?package=\(packageName)"
            
            printMobLog(description: "fetch endpoint url", value: apiString)
            self.checkIfEndPointAvailable(endPoint: apiString)
        } else {
            self.showNativeWithPermission(dic: [:])
        }
    }
    
    private func checkIfEndPointAvailable(endPoint: String) {
        
        if (endpoint == "") {
            printMobLog(description: "check If EndPoint Available", value: "")
            self.showNativeWithPermission(dic: [:])
        } else {
            self.endpoint = endpoint.hasPrefix("http") ? endpoint : "https://" + endpoint
            printMobLog(description: "check If EndPoint Available", value: self.endpoint)
            DispatchQueue.main.async {
                self.start()
            }
        }
        
    }
    
    @objc public func start()
    {
   
        let deeplinkURLQueue = DispatchQueue(label: "deeplinkURLQueue", attributes: .concurrent)
        deeplinkURLQueue.async { [self] in
                
            sleep(UInt32(delay))
            
            if  self.isDeeplinkURL
            {
     
                if RCValues.sharedInstance.getDeeplink().adjustDeeplinkEnabled {
                    self.referrerURL = UserDefaults.standard.string(forKey: "deeplinkURL") ?? ""
                    printMobLog(description: "RCValues getDeeplink adjustDeeplinkEnabled", value: self.referrerURL)
                }
                
                if RCValues.sharedInstance.getDeeplink().dynamicLinksEnabled{
                    self.referrerURL = UserDefaults.standard.string(forKey: "dynamiclinkURL") ?? ""
                    printMobLog(description: "RCValues getDeeplink dynamicLinksEnabled", value: self.referrerURL)
                }
                
            }
            
            if (self.use_only_deeplink && self.referrerURL == "") || !self.run {
                self.showNativeWithPermission(dic: [String : Any]())
                return
            }
             
            startApp()
        
        }
      
    }
    
    
    @objc public func shouldShowPButton() -> Bool
    {
        if !self.addressURL.isEmpty
        {
            return true
        }
        return false
    }
    
    @objc public func showAds() -> Bool
    {
        if !self.isDeeplinkURL
        {
            if self.addressURL.isEmpty
            {
                return true
            }
        }
        else if UserDefaults.standard.value(forKey: "deeplinkURL") == nil
        {
            return true
        }
        
        return false
    }
    
    @objc public func getSTitle() -> String
    {
        let urlToOpen = URL(string: self.addressURL.removingPercentEncoding!)
        if(urlToOpen?.query != nil)
        {
            if (urlToOpen?.queryDictionary!["sName"] != nil)
            {
                return (urlToOpen?.queryDictionary!["sName"] as? String)!
            }
        }
        
        return ""
    }
    
    @objc public func getAddressURL() -> String
    {
        return self.addressURL.removingPercentEncoding!
    }
    
    
    func createParamsURL()
    {
        
        let adjustAttributes = Adjust.attribution()?.description ?? ""
        let encodedAdjustAttributes = adjustAttributes.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        
        
        let encodedwithURLHost = self.referrerURL.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        var encodedReferrerURL = ""
        if encodedwithURLHost != ""
        {
            encodedReferrerURL = encodedwithURLHost
            encodedReferrerURL = encodedReferrerURL.replacingOccurrences(of: "=", with: "%3D", options: .literal, range: nil)
            encodedReferrerURL = encodedReferrerURL.replacingOccurrences(of: "&", with: "%26", options: .literal, range: nil)
        }
        
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        printMobLog(description: "GPS_ADID", value: idfa)
        
        let idfv = UIDevice.current.identifierForVendor!.uuidString
        printMobLog(description: "Device ID", value: idfv)
        
        printMobLog(description: "self.params before changing macro", value: self.params.description)
        
        let paramsQuery = self.params
                            .replacingOccurrences(of: "$adjust_campaign_name", with: Adjust.attribution()?.campaign ?? "")
                            .replacingOccurrences(of: "$idfa", with: idfa)
                            .replacingOccurrences(of: "$idfv", with: idfv)
                            .replacingOccurrences(of: "$adjust_id", with: Adjust.adid() ?? "")
                            .replacingOccurrences(of: "$deeplink", with: encodedReferrerURL)
                            .replacingOccurrences(of: "$firebase_instance_id", with: self.faid)
                            .replacingOccurrences(of: "$package_id", with: Bundle.main.bundleIdentifier ?? "")
                            .replacingOccurrences(of: "$click_id", with: generateUserUUID())
                            .replacingOccurrences(of: "$adjust_attribution", with: encodedAdjustAttributes)
                            .replacingOccurrences(of: "$appmetrica_device_id", with: self.AppMetricaDeviceID)

        printMobLog(description: "self.params after changing macro", value: self.params.description)
        
        let customString =  self.endpoint + "/?"  + paramsQuery
        
        printMobLog(description: "create Params URL String", value: customString)
        
        self.customURL = customString
        
    }
     
    
    func initWebViewURL() -> WebViewController
    {
        let urlToOpen = URL(string: self.customURL)
        let frameworkBundle = Bundle(for: Self.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("MobFlowiOS.bundle")
        let bundle = Bundle(url: bundleURL!)
        let storyBoard = UIStoryboard(name: "Main", bundle:bundle)
        let webView = storyBoard.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
        webView.urlToOpen = urlToOpen!
        webView.schemeURL = self.schemeURL
        webView.addressURL = self.addressURL
        webView.delegate = self
        webView.tintColor = self.tintColor
        webView.backgroundColor = self.backgroundColor
        webView.hideToolbar = self.hideToolbar
        
        return webView
    }
    
    @objc public func openWebView()
    {
        let urlToOpen = URL(string: self.addressURL.removingPercentEncoding!)
        if (urlToOpen != nil)
        {
            guard let webView = getWebView() else { return }
            self.present(webView: webView)
        }
    }
    
    public func getWebView() -> WebViewController?
    {
        let urlToOpen = URL(string: self.addressURL.removingPercentEncoding!)
        if (urlToOpen != nil)
        {
            let frameworkBundle = Bundle(for: Self.self)
            let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("MobFlowiOS.bundle")
            let bundle = Bundle(url: bundleURL!)
            let storyBoard = UIStoryboard(name: "Main", bundle:bundle)
            let webView = storyBoard.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
            webView.urlToOpen = urlToOpen!
            webView.schemeURL = self.schemeURL
            webView.addressURL = self.addressURL
            webView.delegate = self
            webView.tintColor = self.tintColor
            webView.backgroundColor = self.backgroundColor
            webView.hideToolbar = self.hideToolbar
            
            return webView
        }
        
        return nil
    }
    
    func present(webView: WebViewController)
    {
        UIApplication.shared.windows.first?.rootViewController = webView
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    public func showNativeWithPermission(dic: [String : Any]) {
        printMobLog(description: "show Native With Permission", value: "")
        self.delegate?.present(dic: dic)
        requestPremission()
    }
}
