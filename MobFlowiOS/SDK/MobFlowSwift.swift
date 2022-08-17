import UIKit
import AppTrackingTransparency
import AdSupport
import FirebaseCore
import FirebaseAnalytics
import YandexMobileMetrica

public class MobiFlowSwift: NSObject
{
    var isAppmetrica = false
    var isAdjust = false
    var isDeeplinkURL = false
    var isUnityApp = false
    var endpoint = ""
    var adjAppToken = ""
    var appmetricaKey = ""
    var referrerURL = ""
    var customURL = ""
    var schemeURL = ""
    var addressURL = ""
    var faid = ""
    var adjEventToken = ""
    var AppMetricaDeviceID = ""
    public var delegate : MobiFlowDelegate? = nil
    var counter = 0
    var timer = Timer()
    public var backgroundColor = UIColor.white
    public var tintColor = UIColor.black
    public var hideToolbar = false
    var isShowingNotificationLayout = false
    private var attributeTimerSleepSeconds = 0
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
        
        if RCValues.sharedInstance.fetchComplete {}
        
        RCValues.sharedInstance.loadingDoneCallback = getRC
    }
    
    func getRC() {
        
        self.isAppmetrica = RCValues.sharedInstance.getAppmetrica().enabled
        self.appmetricaKey = RCValues.sharedInstance.getAppmetrica().key
        self.isAdjust = RCValues.sharedInstance.getAdjust().enabled
        self.adjAppToken = RCValues.sharedInstance.getAdjust().appToken
        self.adjEventToken =  RCValues.sharedInstance.getAdjust().appInstanceIDEventToken
        self.isDeeplinkURL =   RCValues.sharedInstance.getDeeplink().adjustDeeplinkEnabled ||  RCValues.sharedInstance.getDeeplink().dynamicLinksEnabled
        self.endpoint = RCValues.sharedInstance.string(forKey: .sub_endu)
        
        self.attributeTimerSleepSeconds = RCValues.sharedInstance.getAdjust().delay
        
        self.faid = Analytics.appInstanceID() ?? ""
        self.initialTrackingAndSetup()
    }
    
    
    private func initialTrackingAndSetup() {
        
        if self.isAppmetrica
        {
            nc.addObserver(self, selector: #selector(onAppMetricaDeviceIDReceived), name: Notification.Name("AppMetricaDeviceIDReceived"), object: nil)
            
            let configuration = YMMYandexMetricaConfiguration.init(apiKey: self.appmetricaKey)
            configuration?.preloadInfo?.setAdditional(generateUserUUID(), forKey: "uuid")
            YMMYandexMetrica.activate(with: configuration!)
            
            YMMYandexMetrica.requestAppMetricaDeviceID(withCompletionQueue: .main) { [unowned self] id, error in
                self.AppMetricaDeviceID = id ?? ""
                nc.post(name: Notification.Name("AppMetricaDeviceIDReceived"), object: nil)
                
            }
            
        }
        
        if self.isAdjust
        {
            let environment = ADJEnvironmentProduction
            let adjustConfig = ADJConfig(appToken: self.adjAppToken, environment: environment)
            
            adjustConfig?.sendInBackground = true
            adjustConfig?.delegate = self
            
            Adjust.appDidLaunch(adjustConfig)
            
            let mob_sdk_version = "1.4.3"
            Adjust.addSessionCallbackParameter("mob_sdk_version", value: mob_sdk_version)
            Adjust.addSessionCallbackParameter("user_uuid", value: generateUserUUID())
            Adjust.addSessionCallbackParameter("Firebase_App_InstanceId", value: self.faid)
            
            let adjustEvent = ADJEvent(eventToken: adjEventToken)
            adjustEvent?.addCallbackParameter("eventValue", value: self.faid) //firebase Instance Id
            adjustEvent?.addCallbackParameter("user_uuid", value: generateUserUUID())
            
            Adjust.trackEvent(adjustEvent)
            
        }
        
        if !self.isAppmetrica
        {
            self.onAppMetricaDeviceIDReceived()
        }
    }
    
    @objc private func onAppMetricaDeviceIDReceived(){
        if (endpoint != "") {
            let packageName = Bundle.main.bundleIdentifier ?? ""
            let apiString = "\(endpoint.hasPrefix("http") ? endpoint : "https://" + endpoint)?package=\(packageName)"
            self.checkIfEndPointAvailable(endPoint: apiString)
        } else {
            self.showNativeWithPermission(dic: [:])
        }
    }
    
    private func checkIfEndPointAvailable(endPoint: String) {
          
        if (endpoint == "") {
            // print("no endpoint found in json")
            self.showNativeWithPermission(dic: [:])
        } else {
            self.endpoint = endpoint.hasPrefix("http") ? endpoint : "https://" + endpoint
            DispatchQueue.main.async {
                self.start()
            }
        }
         
    }
 
    @objc public func start()
    {
        if  self.isDeeplinkURL
        {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCounting), userInfo: nil, repeats: true)
        }
        else
        {
            self.startApp()
        }
    }
    
    
    @objc func updateCounting()
    {
        NSLog("counting..")
        if (UserDefaults.standard.value(forKey: "deeplinkURL") as? String) != nil
        {
            timer.invalidate()
            self.startApp()
        }
        else if counter < 10
        {
            counter = counter + 1
        }
        else
        {
            timer.invalidate()
            self.startApp()
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
        var components = URLComponents()
        
        let adjustAttributes = fetchAdjustAttributes()
        let encodedAdjustAttributes = adjustAttributes.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        let encodedReferrerURL = self.referrerURL.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        
        let gpsadid = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        
        components.queryItems = [
            URLQueryItem(name: "click_id", value: generateUserUUID()),
            URLQueryItem(name: "package_id", value: Bundle.main.bundleIdentifier ?? ""),
            URLQueryItem(name: "gps_adid", value: gpsadid),
            URLQueryItem(name: "adjust_attribution", value: encodedAdjustAttributes ),
            URLQueryItem(name: "referringLink", value: encodedReferrerURL),
            URLQueryItem(name: "firebase_instance_id", value: self.faid),
            URLQueryItem(name: "appmetrica_device_id", value: self.AppMetricaDeviceID)
        ]
        
        let customString =  self.endpoint  + (components.string ?? "")
        
        //print("generated custom string : \(customString)")
        self.customURL = customString
        
    }
    
    private func fetchAdjustAttributes() -> String {
        let miliSeconds = UInt32(attributeTimerSleepSeconds)
        
        if (!UserDefaults.standard.bool(forKey: USERDEFAULT_DidWaitForAdjustAttribute)) {
            //only call sleep for the first time
            sleep(miliSeconds)
        }
        
        let adjustAttributes = Adjust.attribution()?.description ?? ""
        
        if (adjustAttributes != "") {
            //setting userdefault value to true only if adjust Attributes are not empty
            UserDefaults.standard.set(true, forKey: USERDEFAULT_DidWaitForAdjustAttribute)
        }
        
        return adjustAttributes
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
        requestPremission()
        self.delegate?.present(dic: dic)
    }
}
