//
//  CDALConfiguration.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

public protocol CDALConfigurationProtocol {
    func isFirstInstall() -> Bool
    func setFirstInstall(first:Bool)
    
    func isCloudAvailable() -> Bool
    func isCloudEnabled() -> Bool
    func shouldUseCloud() -> Bool
    func isCloudPreferenceSelected() -> Bool
    func shouldMigrateData() -> Bool
    func hasJustMigrated() -> Bool
    func isStoreOpening() -> Bool
    func isStoreOpen() -> Bool
    
    func setCloudAvailable(available:Bool)
    func setCloudEnabled(enabled:Bool)
    func shouldUseCloud(should:Bool)
    func clearCloudPreference()
    func shouldMigrateData(should:Bool)
    func hasJustMigrated(has:Bool)
    func isStoreOpening(open:Bool)
    func isStoreOpen(open:Bool)
    
    func update()
    
    func getModelName() -> String
}

public class CDALConfiguration: NSObject, CDALConfigurationProtocol {
    
    private struct Constants {
        static let appID = NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as? NSString
        static let iCloudPreferenceKey = ".\(Constants.appID).UseICloudStorage"
        static let iCloudPreferenceSelected = ".\(Constants.appID).iCloudStoragePreferenceSelected"
    }
    
    var _firstInstall = false
    var _cloudAvailable = false
    var _cloudEnabled = false
    var _shouldUseCloud = false
    var _cloudPreferenceSelected = false
    var _shouldMigrateData = true
    var _hasJustMigrated = false
    var _isStoreOpen = false
    var _isStoreOpening = false
    let modelName:String
    
    let uuids = [String]()
    
    init(modelName:String) {
        self.modelName = modelName
        super.init()
    }
    
    public func isFirstInstall() -> Bool {
        return _firstInstall
    }
    public func setFirstInstall(first: Bool) {
        _firstInstall = true
    }
    public func isCloudAvailable() -> Bool {
        return _cloudAvailable
    }
    public func setCloudAvailable(available: Bool) {
        _cloudAvailable = available
    }
    public func isCloudEnabled() -> Bool {
        return _cloudEnabled
    }
    public func setCloudEnabled(enabled: Bool) {
        _cloudEnabled = enabled
    }
    public func shouldUseCloud() -> Bool {
        return _shouldUseCloud
    }
    public func isCloudPreferenceSelected() -> Bool {
        return _cloudPreferenceSelected
    }
    public func shouldMigrateData() -> Bool {
        return _shouldMigrateData
    }
    public func shouldUseCloud(should: Bool) {
        _shouldUseCloud = should
        NSUserDefaults.standardUserDefaults().setBool(should, forKey:Constants.iCloudPreferenceKey)
        NSUserDefaults.standardUserDefaults().setValue("YES", forKey:Constants.iCloudPreferenceSelected)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    public func hasJustMigrated() -> Bool {
        return _hasJustMigrated
    }
    public func shouldMigrateData(should: Bool) {
        _shouldMigrateData = should
    }
    public func hasJustMigrated(has: Bool) {
        _hasJustMigrated = has
    }
    public func isStoreOpen() -> Bool {
        return _isStoreOpen
    }
    public func isStoreOpening() -> Bool {
        return _isStoreOpening
    }
    public func isStoreOpen(open: Bool) {
        _isStoreOpen = open
    }
    public func isStoreOpening(open: Bool) {
        _isStoreOpening = open
    }
    public func clearCloudPreference() {
        shouldUseCloud(false)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(Constants.iCloudPreferenceSelected)
    }
    
    public func update() {
        setVersion()
        checkCloudPreference()
    }
    
    public func getModelName() -> String {
        return modelName
    }
    

    /**
     * save the version and build number to user defaults
     */
    func setVersion() {
        // this function detects what is the CFBundle version of this application and set it in the settings bundle
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()  // transfer the current version number into the defaults so that this correct value will be displayed when the user visit settings page later
        
        let version: NSString? = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? NSString
        
        let build: NSString? = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as? NSString
        
        defaults.setObject(version, forKey:"version")
        defaults.setObject(build, forKey:"build")
        defaults.synchronize()
    }
    
    /**
     * sets the values of isCloudPreferenceSelected and shouldUseCloud
     */
    func checkCloudPreference() {
        let cloudPreference = NSUserDefaults.standardUserDefaults().boolForKey(Constants.iCloudPreferenceKey)
        if let _ = NSUserDefaults.standardUserDefaults().stringForKey(Constants.iCloudPreferenceSelected) {
            //USER HAS SELECTED A PREFERENCE
            _cloudPreferenceSelected = true
            if cloudPreference {
                //USER SELECTED ICLOUD
                _shouldUseCloud = true
            } else {
                //USER SELECTED LOCAL STORAGE
                _shouldUseCloud = false
            }
        } else {
            //USER HAS NOT SELECTED A PREFERENCE
            _cloudPreferenceSelected = false
            _shouldUseCloud = false
        }
    }
    
    func configure(completion:(() -> Void)?) {
        setVersion()
        // 1. show background indicator
        
        // 2. backup current store if needed
        
        // 3. Check if icloud token is available
        //// 3.1. If YES
        ////// 3.1.1. List all ICLOUD documents?
        ////// 3.1.2. set available = YES
        ////// 3.1.3. if enabled notify state change
        //// 3.2. IF NO
        ////// 3.2.1. set available = NO
        
        // 4. synchronize user defaults
        
        // 5. init isCloudPreferenceSelected = false
        // 6. get preference value
        // 7. check if preference selected
        //// 7.1. If YES
        ////// 7.1.1. set isCloudPreferenceSelected = true
        ////// 7.1.2. check preference value
        //////// 7.1.2.1. If YES
        ////////// 7.1.2.1.1. set shouldUseCloud = true, if available = yes check previous token
        //////// 7.1.2.2. If NO
        ////////// 7.1.2.2.1. set shouldUseCloud = false
        //// 7.2. If NO
        ////// 7.2.1. set isCloudPreferenceSelected = false
        ////// 7.2.2. set shouldUseCloud = false
        checkCloudPreference()
        
        //if shouldUseCloud && isCloudAvailable {
            //cloud.authenticate()
        //}
        
        // 8. Check if token available
        //// 8.1. If YES
        ////// 8.1.1. check isCloudPreferenceSelected
        //////// 8.1.1.1. if YES
        ////////// 8.1.1.1.1. If using icloud call setIsCloudEnabled
        ////////// 8.1.1.1.2. If not using icloud and a local store does not exist but an icloud store 
                              //does exist then prompt user about migrating
                              //otherwise, setIsCloudEnabled to false
        //////// 8.1.1.2. if NO
        ////////// 8.1.1.2.1. set isFirstInstall = true
        ////////// 8.1.1.2.2. prompt user to choose storage option
        ////////// 8.1.1.2.3. save preferences and call setIsCloudEnabled
        //// 8.1. If NO
        ////// 8.1.1. save iCloudPreferenceKey to false
        ////// 8.1.2. save iCloudPreferenceSelected to false so they would be prompted again
        ////// 8.1.3. if useIcloud = true, set to false and prompt about signout
        ////// 8.1.4. setIsCloudEnabled false
        //setCloudEnabled() { Void in
            // 9. store token
            //self.local.setConfiguration(self)
            //self.cloud.setConfiguration(self)
            // 10. exit
            if (completion != nil) {
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    completion!()
                }
            }
        //}
    }

}
