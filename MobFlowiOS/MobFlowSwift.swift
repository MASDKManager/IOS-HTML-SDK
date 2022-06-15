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
   
public class MobiFlowSwift: NSObject
{
    var isAppmetrica = 0
    var isAdjust = 0
    var isDeeplinkURL = 0
    var isUnityApp = 0
    var scheme = ""
    var endpoint = ""
    var adjAppToken = ""
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
    
    @objc public init(isAppmetrica: Int , isAdjust: Int, isDeeplinkURL: Int, scheme: String, endpoint: String, adjAppToken: String, firebaseToken: String, appmetricaKey: String, initDelegate: MobiFlowDelegate, isUnityApp: Int)
    {
        super.init()
        
        self.isUnityApp = isUnityApp
        self.delegate = initDelegate
        self.initialiseSDK(isAppmetrica: isAppmetrica, isAdjust: isAdjust, isDeeplinkURL: isDeeplinkURL, scheme: scheme, endpoint: endpoint, adjAppToken: adjAppToken, firebaseToken: firebaseToken ,  appmetricaKey : appmetricaKey)
    }
    
    public init(isAppmetrica: Int,isBranch: Int, isAdjust: Int, isDeeplinkURL: Int, scheme: String, endpoint: String, adjAppToken: String, firebaseToken: String  ,appmetricaKey: String,  initDelegate: MobiFlowDelegate) {
        super.init()
        self.delegate = initDelegate
        self.initialiseSDK(isAppmetrica: isAppmetrica  , isAdjust: isAdjust, isDeeplinkURL: isDeeplinkURL, scheme: scheme, endpoint: endpoint, adjAppToken: adjAppToken, firebaseToken: firebaseToken , appmetricaKey: appmetricaKey)
    }
    
    private func initialiseSDK(isAppmetrica : Int , isAdjust: Int, isDeeplinkURL: Int, scheme: String, endpoint: String, adjAppToken: String, firebaseToken: String, appmetricaKey: String) {
        
        self.isAppmetrica = isAppmetrica
        self.isAdjust = isAdjust
        self.isDeeplinkURL = isDeeplinkURL
        self.scheme = scheme
        self.adjAppToken = adjAppToken
        self.appmetricaKey = appmetricaKey
        self.endpoint = endpoint
        self.firebaseToken = firebaseToken
        FirebaseApp.configure()
        
        self.faid = Analytics.appInstanceID() ?? ""
        
        Adjust.addSessionCallbackParameter("Firebase_App_InstanceId", value: self.faid)
        self.callFirebaseCallBack()
        
        //resumes the delayed adjust install session
        Adjust.sendFirstPackages()
          
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
         
        if self.isAdjust == 1
        {
            let environment = ADJEnvironmentProduction
            let adjustConfig = ADJConfig(appToken: self.adjAppToken, environment: environment)
            adjustConfig?.sendInBackground = true
            adjustConfig?.delegate = self
            
            //delays the Adjust SDK from sending the initial install session and any event created for mentioned seconds
            adjustConfig?.delayStart = 2
            
            Adjust.addSessionCallbackParameter("user_uuid", value: self.generateUserUUID())
            
            Adjust.appDidLaunch(adjustConfig)
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
    
    func showNativeWithPermission(dic: [String : Any]) {
        self.requestPremission()
        self.delegate?.present(dic: dic)
    }
} 
