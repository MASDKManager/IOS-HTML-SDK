import UIKit
import Adjust
import AppTrackingTransparency
import Branch
import AdSupport
import CryptoKit
import FirebaseCore
import FirebaseInstallations
import FirebaseAnalytics
import YandexMobileMetrica


@objc public protocol MobiFlowDelegate
{
    func present(dic: [String: Any])
    func unloadUnityOnNotificationClick()
}

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

public class MobiFlowSwift: NSObject
{
    var isAppmetrica = 0
    var isBranch = 0
    var isAdjust = 0
    var isDeeplinkURL = 0
    var isUnityApp = 0
    var scheme = ""
    var endpoint = ""
    var adjAppToken = ""
    var branchKey = ""
    var appmetricaKey = ""
    var referrerURL = ""
    var customURL = ""
    var schemeURL = ""
    var addressURL = ""
    var faid = ""
    var firebaseToken = ""
    var AppMetricaDeviceID = ""
    public var delegate : MobiFlowDelegate? = nil
    var counter = 0
    var timer = Timer()
    public var backgroundColor = UIColor.white
    public var tintColor = UIColor.black
    public var hideToolbar = false
    var isShowingNotificationLayout = false
    private let USERDEFAULT_CustomUUID = "USERDEFAULT_CustomUUID"
    private let USERDEFAULT_DidWaitForAdjustAttribute = "USERDEFAULT_DidWaitForAdjustAttribute"
    private var attributeTimerSleepSeconds = 5
    
    @objc public init(isAppmetrica: Int, isBranch: Int, isAdjust: Int, isDeeplinkURL: Int, scheme: String, endpoint: String, adjAppToken: String, firebaseToken: String, branchKey: String,appmetricaKey: String, initDelegate: MobiFlowDelegate, isUnityApp: Int)
    {
        super.init()
        
        self.isUnityApp = isUnityApp
        self.delegate = initDelegate
        self.initialiseSDK(isAppmetrica: isAppmetrica, isBranch: isBranch, isAdjust: isAdjust, isDeeplinkURL: isDeeplinkURL, scheme: scheme, endpoint: endpoint, adjAppToken: adjAppToken, firebaseToken: firebaseToken ,branchKey: branchKey, appmetricaKey : appmetricaKey)
    }
    
    public init(isAppmetrica: Int,isBranch: Int, isAdjust: Int, isDeeplinkURL: Int, scheme: String, endpoint: String, adjAppToken: String, firebaseToken: String, branchKey: String,appmetricaKey: String,  initDelegate: MobiFlowDelegate) {
        super.init()
        self.delegate = initDelegate
        self.initialiseSDK(isAppmetrica: isAppmetrica, isBranch: isBranch, isAdjust: isAdjust, isDeeplinkURL: isDeeplinkURL, scheme: scheme, endpoint: endpoint, adjAppToken: adjAppToken, firebaseToken: firebaseToken ,branchKey: branchKey, appmetricaKey: appmetricaKey)
    }
    
    private func initialiseSDK(isAppmetrica : Int, isBranch: Int, isAdjust: Int, isDeeplinkURL: Int, scheme: String, endpoint: String, adjAppToken: String, firebaseToken: String, branchKey: String, appmetricaKey: String) {
        
        self.isAppmetrica = isAppmetrica
        self.isBranch = isBranch
        self.isAdjust = isAdjust
        self.isDeeplinkURL = isDeeplinkURL
        self.scheme = scheme
        self.adjAppToken = adjAppToken
        self.branchKey = branchKey
        self.appmetricaKey = appmetricaKey
        self.endpoint = endpoint
        self.firebaseToken = firebaseToken
        FirebaseApp.configure()
        
        self.faid = Analytics.appInstanceID() ?? ""
         
        self.initialTrackingAndSetup()
    }
    
    private func initialTrackingAndSetup() {
        
        if self.isAppmetrica == 1
        {
            let configuration = YMMYandexMetricaConfiguration.init(apiKey: self.appmetricaKey)
            YMMYandexMetrica.activate(with: configuration!)
            
            YMMYandexMetrica.requestAppMetricaDeviceID(withCompletionQueue: .main) { [unowned self] id, error in
                self.AppMetricaDeviceID = id ?? ""
            }
        }
        
        if self.isBranch == 1
        {
            Branch.setUseTestBranchKey(true)
            Branch.getInstance(self.branchKey).enableLogging()
            let uuid = UIDevice.current.identifierForVendor!.uuidString
            Branch.getInstance(self.branchKey).setRequestMetadataKey("app_to_branch_device_id", value: uuid)
            let bundleIdentifier = Bundle.main.bundleIdentifier
            Branch.getInstance(self.branchKey).setRequestMetadataKey("package_id", value: bundleIdentifier)
        }
        
        if self.isAdjust == 1
        {
            let environment = ADJEnvironmentProduction
            let adjustConfig = ADJConfig(appToken: self.adjAppToken, environment: environment)
            adjustConfig?.sendInBackground = true
            adjustConfig?.delegate = self
            
            //delays the Adjust SDK from sending the initial install session and any event created for mentioned seconds
            adjustConfig?.delayStart = 2
            
            let mob_sdk_version = "1.1.6"
            Adjust.addSessionCallbackParameter("mob_sdk_version", value: mob_sdk_version)
            Adjust.addSessionCallbackParameter("user_uuid", value: self.generateUserUUID())
            Adjust.addSessionCallbackParameter("Firebase_App_InstanceId", value: self.faid)
            Adjust.appDidLaunch(adjustConfig)
            
            self.callFirebaseCallBack()
            
            //resumes the delayed adjust install session
            Adjust.sendFirstPackages()
        }

        if (endpoint != "") {
            let packageName = Bundle.main.bundleIdentifier ?? ""
            let apiString = "\(endpoint.hasPrefix("http") ? endpoint : "https://" + endpoint)?package=\(packageName)"
            self.checkIfEndPointAvailable(endPoint: apiString)
        } else {
            self.showNativeWithPermission(dic: [:])
        }
    }
    
    private func callFirebaseCallBack() {
        let adjustEvent = ADJEvent(eventToken: firebaseToken)
        adjustEvent?.addCallbackParameter("eventValue", value: self.faid) //firebase Instance Id
        adjustEvent?.addCallbackParameter("user_uuid", value: self.generateUserUUID())
        
        Adjust.trackEvent(adjustEvent)
    }
    
    private func checkIfEndPointAvailable(endPoint: String) {
        
        fetchDataWithUrl(urlString: endPoint) { response, isSuccess in
            if (isSuccess) {
                if let endpoint = response?["cf"] as? String {
                    print("endpoint: \(endpoint)")
                    if let delayTime = response?["second"] as? Int {
                        self.attributeTimerSleepSeconds = delayTime
                    }
                    
                    if (endpoint == "") {
                        print("no endpoint found in json")
                        self.showNativeWithPermission(dic: [:])
                    } else {
                        self.endpoint = endpoint.hasPrefix("http") ? endpoint : "https://" + endpoint
                        DispatchQueue.main.async {
                            self.start()
                        }
                    }
                } else {
                    print("no endpoint found in json")
                    self.showNativeWithPermission(dic: [:])
                }
            } else {
                print("failure in api")
                self.showNativeWithPermission(dic: [:])
            }
        }
    }
    
    private func fetchDataWithUrl(urlString: String, completionHendler:@escaping (_ response:Dictionary<String,AnyObject>?, _ success: Bool)-> Void) {
        
        if let url = URL(string: urlString) {
            
            var urlRequest = URLRequest(url: url)
            urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
            urlRequest.timeoutInterval = 60
            urlRequest.httpMethod = "GET"
            urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
            
            let session = URLSession.shared
            let task = session.dataTask(with: urlRequest, completionHandler: { data, response, error -> Void in
                do {
                    if (data == nil){
                        completionHendler([:],false)
                    } else {
                        if let json = try JSONSerialization.jsonObject(with: data!) as? Dictionary<String, AnyObject> {
                            completionHendler(json,true)
                        } else {
                            completionHendler([:],false)
                        }
                    }
                } catch {
                    completionHendler([:],false)
                }
            })
            
            task.resume()
        }
    }
    
    @objc public func start()
    {
        if self.isDeeplinkURL == 0
        {
            self.startApp()
        }
        else if self.isDeeplinkURL == 1
        {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCounting), userInfo: nil, repeats: true)
        }
    }
    
    func requestPremission()
    {
        if #available(iOS 14, *)
        {
            ATTrackingManager.requestTrackingAuthorization { (authStatus) in
                switch authStatus
                {
                case .notDetermined:
                    print("Not Determined")
                case .restricted:
                    print("Restricted")
                case .denied:
                    print("Denied")
                case .authorized:
                    print("Authorized")
                @unknown default:
                    break
                }
            }
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
        if self.isDeeplinkURL == 0
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
    
    private func generateUserUUID() -> String {
        
        var md5UUID = getUserUUID()
        
        if (md5UUID == "") {
            var uuid = ""
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
            let customTimeStamp = currentTimeInMilliSeconds()
            
            uuid = deviceId + customTimeStamp
            
            md5UUID = uuid.md5()
            saveUserUUID(value: md5UUID)
        }
        
        return md5UUID
    }
    
    private func getUserUUID() -> String {
        return UserDefaults.standard.string(forKey: USERDEFAULT_CustomUUID) ?? ""
    }
    
    private func saveUserUUID(value:String) {
        return UserDefaults.standard.set(value, forKey: USERDEFAULT_CustomUUID)
    }
    
    func currentTimeInMilliSeconds() -> String {
        let currentDate = Date()
        let since1970 = currentDate.timeIntervalSince1970
        let intTimeStamp = Int(since1970 * 1000)
        return "\(intTimeStamp)"
    }
    
    func createParamsURL()
    {
        var components = URLComponents()
         
        let adjustAttributes = fetchAdjustAttributes()
        let encodedAdjustAttributes = adjustAttributes.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        let encodedReferrerURL = self.referrerURL.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
         
        let gpsadid = ASIdentifierManager.shared().advertisingIdentifier.uuidString

        components.queryItems = [
            URLQueryItem(name: "val1", value: generateUserUUID()),
            URLQueryItem(name: "val2", value: Bundle.main.bundleIdentifier ?? ""),
            URLQueryItem(name: "val3", value: self.faid),
            URLQueryItem(name: "val4", value: encodedAdjustAttributes ),
            URLQueryItem(name: "val5", value: gpsadid),
            URLQueryItem(name: "val6", value: encodedReferrerURL),
            URLQueryItem(name: "val7", value: self.AppMetricaDeviceID)
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
    
    @objc public func openWebView()
    {
        self.present(webView: getWebView())
    }
    
    public func getWebView() -> WebViewController
    {
        let urlToOpen = URL(string: self.addressURL.removingPercentEncoding ?? "")
        
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
    
    func present(webView: WebViewController)
    {
        UIApplication.shared.windows.first?.rootViewController = webView
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    private func showNativeWithPermission(dic: [String : Any]) {
        self.requestPremission()
        self.delegate?.present(dic: dic)
    }
}

private extension String {
    
    func md5() -> String {
        return Insecure.MD5.hash(data: self.data(using: .utf8)!).map { String(format: "%02hhx", $0) }.joined()
    }
    
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
    func utf8DecodedString()-> String {
        let data = self.data(using: .utf8)
        let message = String(data: data!, encoding: .nonLossyASCII) ?? ""
        return message
    }
    
    func utf8EncodedString()-> String {
        let messageData = self.data(using: .nonLossyASCII)
        let text = String(data: messageData!, encoding: .utf8) ?? ""
        return text
    }
}

private extension URL
{
    var queryDictionary: [String: Any]? {
        var queryStrings = [String: String]()
        guard let query = self.query else { return queryStrings }
        for pair in query.components(separatedBy: "&")
        {
            if (pair.components(separatedBy: "=").count > 1)
            {
                let key = pair.components(separatedBy: "=")[0]
                let value = pair
                    .components(separatedBy: "=")[1]
                    .replacingOccurrences(of: "+", with: " ")
                    .removingPercentEncoding ?? ""
                
                queryStrings[key] = value
            }
        }
        return queryStrings
    }
}

private extension Int {
    var msToSeconds: Double { Double(self) / 1000 }
}

extension MobiFlowSwift: UIApplicationDelegate
{
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        if self.isBranch == 1
        {
            Branch.getInstance(self.branchKey).initSession(launchOptions: launchOptions) { (params, error) in
                let referringParams = Branch.getInstance(self.branchKey).getLatestReferringParams()
                let referringLink = referringParams!["~referring_link"] as? String ?? ""
                if !referringLink.isEmpty
                {
                    UserDefaults.standard.set(referringLink, forKey: "deeplinkURL")
                }
            }
        }
        
        return true
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool
    {
        if self.isBranch == 1
        {
            return Branch.getInstance(self.branchKey).application(app, open: url, options: options)
        }
        return false
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        if self.isBranch == 1
        {
            Branch.getInstance(self.branchKey).handlePushNotification(userInfo)
        }
    }
    
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    {
        if self.isBranch == 1
        {
            return Branch.getInstance(self.branchKey).continue(userActivity)
        }
        
        self.referrerURL = userActivity.referrerURL?.absoluteString ?? ""
      
        return false
    }
}

extension MobiFlowSwift : NotificationLayoutDelegate
{
    func closeNotificationLayout() {
        print("close Notification Layout received in MobFlow Swift SDK.")
        isShowingNotificationLayout = false
        self.startApp()
    }
    
}

extension MobiFlowSwift: AdjustDelegate
{
    public func adjustAttributionChanged(_ attribution: ADJAttribution?)
    {
        print(attribution?.adid ?? "")
    }
    
    public func adjustEventTrackingSucceeded(_ eventSuccessResponseData: ADJEventSuccess?)
    {
      print(eventSuccessResponseData?.jsonResponse ?? [:])
    }

    public func adjustEventTrackingFailed(_ eventFailureResponseData: ADJEventFailure?)
    {
      print(eventFailureResponseData?.jsonResponse ?? [:])
    }

    public func adjustSessionTrackingFailed(_ sessionFailureResponseData: ADJSessionFailure?)
    {
      print(sessionFailureResponseData?.jsonResponse ?? [:])
    }
    
    public func adjustDeeplinkResponse(_ deeplink: URL?) -> Bool
    {
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

extension MobiFlowSwift: WebViewControllerDelegate
{
    func present(dic: [String : Any])
    {
        self.requestPremission()
        self.delegate?.present(dic: dic)
    }
    
    func set(schemeURL: String, addressURL: String)
    {
        self.schemeURL = schemeURL
        self.addressURL = addressURL
    }
    
    func startApp()
    {
        
        DispatchQueue.main.async {
            if (self.isShowingNotificationLayout) {
                return
            }
            
            if self.isDeeplinkURL == 0 || (self.isDeeplinkURL == 1 && UserDefaults.standard.object(forKey: "deeplinkURL") != nil)
            {
                if self.schemeURL.isEmpty
                {
                    if self.customURL.isEmpty
                    {
                        self.createParamsURL()
                        //(self.isDeeplinkURL == 1) ? self.creteCustomURLWithDeeplinkParam() : self.createCustomURL()
                    }
                    let webView = self.getWebView()
                    self.present(webView: webView)
                }
                else
                {
                    self.showNativeWithPermission(dic: [String : Any]())
                    let url = URL(string: self.schemeURL)
                    if UIApplication.shared.canOpenURL(url!)
                    {
                        UIApplication.shared.open(url!)
                    }
                }
            }
            else
            {
                self.showNativeWithPermission(dic: [String : Any]())
            }
        }
    }
}

