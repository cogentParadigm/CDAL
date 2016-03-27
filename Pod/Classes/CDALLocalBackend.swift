//
//  CDALLocalBackend.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

class CDALLocalBackend: NSObject, CDALBackendProtocol {
    
    let name:String
    
    init(name:String) {
        self.name = name
        super.init()
    }
    
    func isAvailable() -> Bool {
        return true
    }
    
    func storeExists() -> Bool {
        var isDir: ObjCBool = false
        let url = storeURL()
        if let path = url.path {    
            let fileExists: Bool = NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir)
            return fileExists
        } else {
            return false
        }
    }
    
    func setConfiguration(configuration: CDALConfiguration) {
        //nothing to do
    }
    
    private func storeURL() -> NSURL {
        return applicationDocumentsDirectory.URLByAppendingPathComponent(name).URLByAppendingPathExtension("sqlite")
    }
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
    }()
}
