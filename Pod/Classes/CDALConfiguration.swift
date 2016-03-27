//
//  CDALConfiguration.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

struct CDConstants {
    static let ICloudStateUpdatedNotification = "ICloudStateUpdatedNotification"
    static let OSFileDeletedNotification = "OSFileDeletedNotification"
    static let OSFileCreatedNotification = "OSFileCreatedNotification"
    static let OSFileClosedNotification = "OSFileClosedNotification"
    static let OSFilesUpdatedNotification = "OSFilesUpdatedNotification"
    static let OSDataUpdatedNotification = "OSCoreDataUpdated"
    static let OSStoreChangeNotification = "OSCoreDataStoreChanged"
    static let OSJobStartedNotification = "OSBackgroundJobStarted"
    static let OSJobDoneNotification = "OSBackgroundJobCompleted"
    static let OSStoreOpenedNotification = "OSStoreOpenedNotification"
}

class CDALConfiguration: NSObject {
    
    private struct Constants {
        static let appID = NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as? NSString
        static let applicationDocumentsDirectoryName = ".\(Constants.appID)"
        static let modelName = "MMW"
        static let iCloudPreferenceKey = ".\(Constants.appID).UseICloudStorage"
        static let iCloudPreferenceSelected = ".\(Constants.appID).iCloudStoragePreferenceSelected" // Records whether user has actually selected a preference
        static let makeBackupPreferenceKey = ".\(Constants.appID).MakeBackup"
        static let iCloudStoreFilenameKey = ".\(Constants.appID).iCloudStoreFileName"
        static let timerPeriod: NSTimeInterval = 2.0
    }
    
    var modelName = "MODEL"
    
    let local:CDALBackendProtocol
    let cloud:CDALCloudEnabledBackendProtocol
    let alerts = CDALAlerts()
    
    var isFirstInstall = false
    var isCloudAvailable = false
    var isCloudEnabled = false
    var shouldUseCloud = false
    var isCloudPreferenceSelected = false
    var deleteCloudFiles = false
    
    init(localBackend:CDALBackendProtocol, cloudBackend:CDALCloudEnabledBackendProtocol) {
        local = localBackend
        cloud = cloudBackend
        super.init()
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
    }
    
    /**
     * sets the value of isCloudAvailable
     */
    func checkCloudAvailability() {
        isCloudAvailable = cloud.isAvailable()
    }
    
    /**
     * sets the values of isCloudPreferenceSelected and shouldUseCloud
     */
    func checkCloudPreference() {
        let cloudPreference = NSUserDefaults.standardUserDefaults().boolForKey(Constants.iCloudPreferenceKey)
        if let _ = NSUserDefaults.standardUserDefaults().stringForKey(Constants.iCloudPreferenceSelected) {
            //USER HAS SELECTED A PREFERENCE
            isCloudPreferenceSelected = true
            if cloudPreference {
                //USER SELECTED ICLOUD
                shouldUseCloud = true
            } else {
                //USER SELECTED LOCAL STORAGE
                shouldUseCloud = false
            }
        } else {
            //USER HAS NOT SELECTED A PREFERENCE
            isCloudPreferenceSelected = false
            shouldUseCloud = false
        }
    }
    
    func setCloudEnabled(completion:(() -> Void)?) {
        if isCloudAvailable {
            if isCloudPreferenceSelected {
                if shouldUseCloud {
                    isCloudEnabled = true
                } else {
                    if !local.storeExists() && cloud.storeExists() {
                        //prompt about migration
                        alerts.cloudDisabled() { choice in
                            if choice == 1 {
                                //keep using icloud
                                NSUserDefaults.standardUserDefaults().setBool(true, forKey:Constants.iCloudPreferenceKey)
                                NSUserDefaults.standardUserDefaults().synchronize()
                                self.shouldUseCloud = true
                                self.isCloudEnabled = true
                                self.postFileUpdateNotification()
                            } else if choice == 2 {
                                //keep data
                                self.shouldUseCloud = false
                                self.deleteCloudFiles = false;
                                self.isCloudEnabled = false
                                self.postFileUpdateNotification()
                            } else if choice == 3 {
                                //delete data
                                self.shouldUseCloud = false
                                self.deleteCloudFiles = true;
                                self.isCloudEnabled = false
                                self.postFileUpdateNotification()
                            }
                            completion?()
                        }
                        return
                    } else {
                        isCloudEnabled = false
                    }
                }
            } else {
                isFirstInstall = true
                alerts.cloudPreference() { choice in
                    if choice == 1 {
                        NSUserDefaults.standardUserDefaults().setBool(false, forKey:Constants.iCloudPreferenceKey)
                        NSUserDefaults.standardUserDefaults().setValue("YES", forKey:Constants.iCloudPreferenceSelected)
                        self.shouldUseCloud = false
                        NSUserDefaults.standardUserDefaults().synchronize()
                        self.isCloudEnabled = false
                    } else {
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: Constants.iCloudPreferenceKey )
                        NSUserDefaults.standardUserDefaults().setValue("YES", forKey:Constants.iCloudPreferenceSelected)
                        self.shouldUseCloud = true
                        NSUserDefaults.standardUserDefaults().synchronize()
                        self.isCloudEnabled = true
                    }
                    completion?()
                }
                return
            }
        } else {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey:Constants.iCloudPreferenceKey)
            NSUserDefaults.standardUserDefaults().synchronize()
            
            // Since the user is signed out of iCloud, reset the preference to not use iCloud, so if they sign in again we will prompt them to move data
            NSUserDefaults.standardUserDefaults().removeObjectForKey(Constants.iCloudPreferenceSelected)
            if shouldUseCloud {
                shouldUseCloud = false
                alerts.cloudSignout() { _ in
                    self.isCloudEnabled = false
                    completion?()
                }
                return
            } else {
                self.isCloudEnabled = false
            }
        }
        completion?()
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
        checkCloudAvailability()
        
        // 4. synchronize user defaults
        NSUserDefaults.standardUserDefaults().synchronize()
        
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
        
        if shouldUseCloud && isCloudAvailable {
            cloud.authenticate()
        }
        
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
        setCloudEnabled() { Void in
            // 9. store token
            self.local.setConfiguration(self)
            self.cloud.setConfiguration(self)
            // 10. exit
            if (completion != nil) {
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    completion!()
                }
            }
        }
    }
    
    func postFileUpdateNotification() {
        NSOperationQueue.mainQueue().addOperationWithBlock( {
            NSNotificationCenter.defaultCenter().postNotificationName(CDConstants.OSFilesUpdatedNotification,
                object:self)
        })
    }

}
