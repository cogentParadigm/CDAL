//
//  CDALBackendProtocol.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//
import CoreData

public protocol CDALBackendProtocol {
    func isAvailable() -> Bool
    func storeExists() -> Bool
    func getStoreName() -> String
    func documentsDirectory() -> NSURL
    func storeURL() -> NSURL
    func storeOptions() -> NSDictionary
    func addToCoordinator(coordinator:NSPersistentStoreCoordinator) throws -> NSPersistentStore
    func migrateStore(source:NSPersistentStore, coordinator:NSPersistentStoreCoordinator) throws -> NSPersistentStore
    func delete()
}

public protocol CDALCloudEnabledBackendProtocol: CDALBackendProtocol {
    func authenticate(completion:((Bool) -> Void)?)
}

extension CDALBackendProtocol {
    func isAvailable() -> Bool {
        return true
    }
    func documentsDirectory() -> NSURL {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
    }
    func storeURL() -> NSURL {
        return documentsDirectory().URLByAppendingPathComponent(getStoreName()).URLByAppendingPathExtension("sqlite")
    }
    func storeOptions() -> NSDictionary {
        return [NSMigratePersistentStoresAutomaticallyOption:true,
                NSInferMappingModelAutomaticallyOption:true,
                NSSQLitePragmasOption:["journal_mode" : "DELETE"]]
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
    func addToCoordinator(coordinator: NSPersistentStoreCoordinator) throws -> NSPersistentStore {
        let store: NSPersistentStore = try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL(), options: (storeOptions() as! [NSObject : AnyObject]))
        return store
    }
    func migrateStore(source:NSPersistentStore, coordinator: NSPersistentStoreCoordinator) throws -> NSPersistentStore {
        let store: NSPersistentStore = try coordinator.migratePersistentStore(source, toURL:storeURL(), options:(storeOptions() as! [NSObject : AnyObject]), withType:NSSQLiteStoreType)
        return store
    }
    func saveBackup(coordinator:NSPersistentStoreCoordinator) -> Bool {
        do {
            let source: NSPersistentStore = try addToCoordinator(coordinator)
            let destination: NSPersistentStore?
            do {
                destination = try coordinator.migratePersistentStore(source, toURL:backupStoreURL(), options:(storeOptions() as! [NSObject : AnyObject]), withType:NSSQLiteStoreType)
            } catch {
                destination = nil
            }
            
            if (destination != nil) {
                return true
            } else {
                return false
            }
        } catch  {
            return false
        }
    }
    func backupStoreURL() -> NSURL {
        let dateFormatter: NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
        
        let dateString: String = dateFormatter.stringFromDate(NSDate())
        
        
        let fileName: NSString = getStoreName() + "_Backup_" + dateString
        
        return documentsDirectory().URLByAppendingPathComponent(fileName as String).URLByAppendingPathExtension("sqlite")
    }
    func delete() {
        deleteStoreFile(storeURL())
    }
    func deleteStoreFile(fileURL:NSURL) {
        if let path = fileURL.path {
            if (!NSFileManager.defaultManager().fileExistsAtPath(path)) {
                return
            }
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let fileCoordinator:NSFileCoordinator = NSFileCoordinator()
            var error: NSError? = nil
            fileCoordinator.coordinateWritingItemAtURL(fileURL, options: NSFileCoordinatorWritingOptions.ForDeleting, error: &error, byAccessor: {writingURL in
                let fileManager:NSFileManager = NSFileManager()
                var er:NSError? = nil
                let res:Bool
                do {
                    try fileManager.removeItemAtURL(writingURL)
                    res = true
                } catch var error as NSError {
                    er = error
                    res = false
                } catch {
                    fatalError()
                }
            })
            
        })
    }
}
