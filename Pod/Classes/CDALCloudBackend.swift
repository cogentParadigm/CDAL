//
//  CDALCloudBackend.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

import CoreData

public class CDALCloudBackend: NSObject, CDALCloudEnabledBackendProtocol {
    
    private struct Constants {
        static let appID = NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as? NSString
        static let iCloudContainerID = "iCloud.\(Constants.appID)"
        static let ubiquityContainerKey = ".\(Constants.appID).ubiquityContainerID"
        static let ubiquityTokenKey = ".\(Constants.appID).ubiquityToken"
    }
    
    var ubiquityContainerID: NSString? = Constants.iCloudContainerID
    var hasCheckedCloud = false
    var cloudFileExists = false
    var rebuildFromCloud = false
    
    let name:String
    
    init(name:String) {
        self.name = name
        super.init()
    }
    
    public func isAvailable() -> Bool {
        if let _ = NSFileManager.defaultManager().ubiquityIdentityToken {
            return true
        }
        else {
            return false
        }
    }
    public func storeExists() -> Bool {
        // if iCloud container is not available just return NO
        if (!isAvailable()) {
            return false
        }
        
        if let path = containerURL()?.path {
            var isDir: Bool = false
            var fileExists: Bool = NSFileManager.defaultManager().fileExistsAtPath(path)
        }

        // This may block for some time if a _query has not returned results yet
        let icloudFileExists: Bool = doesICloudFileExist()
        
        return icloudFileExists
    }
    
    public func getStoreName() -> String {
        return name
    }
    
    public func authenticate(completion:((Bool) -> Void)?) {
        if ubiquitousTokenHasChanged() {
            completion?(true)
        } else {
            completion?(false)
        }
        storeToken()
    }
    

    public func storeOptions() -> NSDictionary {
        
        var options: NSDictionary
        
        if (rebuildFromCloud) {
            options = [NSPersistentStoreUbiquitousContentNameKey:name,
                       NSPersistentStoreRebuildFromUbiquitousContentOption:true,
                       NSMigratePersistentStoresAutomaticallyOption:true,
                       NSInferMappingModelAutomaticallyOption:true,
                       NSSQLitePragmasOption:["journal_mode" : "DELETE" ]]
            rebuildFromCloud = false
        } else {
            options = [NSPersistentStoreUbiquitousContentNameKey:name,
                       NSMigratePersistentStoresAutomaticallyOption:true,
                       NSInferMappingModelAutomaticallyOption:true,
                       NSSQLitePragmasOption:["journal_mode" : "DELETE" ]]
        }
        
        return options
    }
    
    private func storeToken() {
        if let token:protocol<NSCoding, NSCopying, NSObjectProtocol>? = NSFileManager.defaultManager().ubiquityIdentityToken {
            // Write the ubquity identity token to NSUserDefaults if it exists.
            // Otherwise, remove the key.
            if let tk = token {
                let newTokenData: NSData = NSKeyedArchiver.archivedDataWithRootObject(tk)
                NSUserDefaults.standardUserDefaults().setObject(newTokenData, forKey:Constants.ubiquityTokenKey)
            }
        }
        else {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(Constants.ubiquityTokenKey)
        }
    }
    
    private func containerURL() -> NSURL? {
        if let iCloudURL:NSURL = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(((ubiquityContainerID as! String))) {
            return iCloudURL.URLByAppendingPathComponent("CoreData").URLByAppendingPathComponent(name)
        }
        else {
            return nil
        }
    }
    
    private func doesICloudFileExist() -> Bool {
        var count: Int  = 0
        
        // Start with 10ms time boxes
        let ti: NSTimeInterval  = 2.0
        
        // Wait until delegate did callback
        while (!hasCheckedCloud) {
            //has not checked iCloud yet, waiting
            let date: NSDate = NSDate(timeIntervalSinceNow: ti)
            // Let the current run-loop do it's magif for one time-box.
            NSRunLoop.currentRunLoop().runMode(NSRunLoopCommonModes, beforeDate: date)
            // Double the time box, for next try, max out at 1000ms.
            //ti = MIN(1.0, ti * 2);
            count++
            if (count>10) {
                //given up waiting
                hasCheckedCloud = true
                cloudFileExists = true
            }
        }
        
        if (hasCheckedCloud) {
            if (cloudFileExists) {
                hasCheckedCloud = false
                return true
            } else {
                hasCheckedCloud = false
                return false
            }
        } else {
            return false
        }
    }
    

    private func ubiquitousTokenHasChanged() -> Bool {
        
        let activeToken = NSFileManager.defaultManager().ubiquityIdentityToken
        
        if let oldTokenData: NSData = NSUserDefaults.standardUserDefaults().objectForKey(Constants.ubiquityTokenKey) as? NSData {
            
            if let oldToken: protocol<NSCoding, NSCopying, NSObjectProtocol> = NSKeyedUnarchiver.unarchiveObjectWithData(oldTokenData) as? protocol<NSCoding, NSCopying, NSObjectProtocol> {
                
                if (!oldToken.isEqual(activeToken)) {
                    return true
                }
            }
        }
        return false
    }
}
