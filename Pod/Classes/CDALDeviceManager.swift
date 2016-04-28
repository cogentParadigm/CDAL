//
//  CDALDeviceManager.swift
//  Pods
//
//  Created by Ali Gangji on 4/13/16.
//
//

public class CDALDeviceManager: NSObject {
    private struct Constants {
        static let appID = NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as? NSString
        static let iCloudUUIDKey = ".\(Constants.appID).iCloudUUID"
    }
    
    var uuids = [String]()
    var deviceList:CDALDeviceList?
    var deviceListName = "CDALKnownDevices.plist"
    var query:NSMetadataQuery?
    
    let backgroundQueue = dispatch_queue_create("CDALDeviceManager.BackgroundQueue", nil)
    
    public override init() {
        super.init()
        if ((NSUserDefaults.standardUserDefaults().objectForKey(Constants.iCloudUUIDKey) as? String) == nil) {
            NSUserDefaults.standardUserDefaults().setObject(NSUUID().UUIDString, forKey: Constants.iCloudUUIDKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    func getDeviceID() -> String {
        return NSUserDefaults.standardUserDefaults().objectForKey(Constants.iCloudUUIDKey) as! String
    }
    
    func setup() {
        uuids.removeAll()
        deviceList = CDALDeviceList(url: deviceListURL(), queue: NSOperationQueue())
        NSFileCoordinator.addFilePresenter(deviceList!)
        query = NSMetadataQuery()
        query?.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        query?.predicate = NSPredicate(format: "%K LIKE %@", argumentArray: [NSMetadataItemFSNameKey, deviceListName])
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(deviceListChanged(_:)), name: NSMetadataQueryDidUpdateNotification, object: query!)
        dispatch_async(dispatch_get_main_queue()) {
            self.query?.startQuery()
        }
    }
    
    func teardown() {
        if deviceList != nil {
            NSFileCoordinator.removeFilePresenter(deviceList!)
            deviceList = nil
            uuids.removeAll()
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NSMetadataQueryDidUpdateNotification, object: self.query!)
            dispatch_async(dispatch_get_main_queue()) {
                self.query?.stopQuery()
                self.query = nil
            }
        }
    }
    
    func deviceListChanged(notification:NSNotification) {
        dispatch_async(backgroundQueue) {
            self.query?.disableUpdates()
            self.refreshDeviceList(false) { deviceListExisted, currentDevicePresent in
                self.query?.enableUpdates()
            }
        }
    }
    
    func refreshDeviceList(canAddCurrentDevice:Bool, completion:(deviceListExisted:Bool, currentDevicePresent:Bool) -> Void) {
        uuids.removeAll()
        let uuid = NSUserDefaults.standardUserDefaults().stringForKey(Constants.iCloudUUIDKey)!
        
        download(deviceListURL(), dispatchQueue: backgroundQueue) { syncCompleted, error in
            var err:NSError? = nil
            let coordinator = NSFileCoordinator(filePresenter: self.deviceList)
            var deviceListExisted = false
            var currentDevicePresent = false
            coordinator.coordinateReadingItemAtURL(self.deviceListURL(), options: .WithoutChanges, error: &err) { url in
                let dict = NSDictionary(contentsOfURL: url)
                if let devices = dict?.objectForKey("DeviceUUIDs") as? [String] {
                    self.uuids = devices
                    if devices.count > 0 {
                        deviceListExisted = true
                        currentDevicePresent = devices.contains(uuid)
                    }
                }
            }
            
            if (!currentDevicePresent && canAddCurrentDevice) {
                var err2:NSError? = nil
                self.uuids.append(uuid)
                let newList = NSDictionary()
                newList.setValue(self.uuids, forKey: "DeviceUUIDs")
                let baseURL = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)!
                coordinator.coordinateWritingItemAtURL(baseURL, options: NSFileCoordinatorWritingOptions.ContentIndependentMetadataOnly, error: &err2) { url in
                    do {
                        try NSFileManager.defaultManager().createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        
                    }
                }
                
                var err3:NSError? = nil
                coordinator.coordinateWritingItemAtURL(self.deviceListURL(), options: .ForReplacing, error: &err3) { url in
                    newList.writeToURL(url, atomically: false)
                }
            }
            
            completion(deviceListExisted: deviceListExisted, currentDevicePresent: currentDevicePresent)
        }
    }
    
    private func deviceListURL() -> NSURL {
        let iCloudURL:NSURL = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)!
        return iCloudURL.URLByAppendingPathComponent(deviceListName)
    }
    
    private func download(url:NSURL, dispatchQueue:dispatch_queue_t, completion:(syncCompleted:Bool, error:NSError?) -> Void) {
        
        //check if the file is already downloaded
        var isDownloaded:AnyObject? = nil
        do {
            try url.getResourceValue(&isDownloaded, forKey: NSURLUbiquitousItemDownloadingStatusKey)
        } catch _ {
            
        }
        if isDownloaded as? String == NSURLUbiquitousItemDownloadingStatusCurrent {
            completion(syncCompleted: true, error: nil)
            return
        }
        
        //check if the file is currently downloading
        var isDownloading:AnyObject? = nil
        do {
            try url.getResourceValue(&isDownloading, forKey: NSURLUbiquitousItemIsDownloadingKey)
        } catch _ {
            
        }
        if (isDownloading as? NSNumber)?.boolValue == true {
            //do nothing - wait for next run
        } else {
            do {
                try NSFileManager.defaultManager().startDownloadingUbiquitousItemAtURL(url)
            } catch {
                completion(syncCompleted: false, error: nil)
            }
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC))), dispatchQueue) {
            self.download(url, dispatchQueue: dispatchQueue, completion: completion)
        }
    }
}
