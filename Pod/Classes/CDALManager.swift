//
//  CDALManager.swift
//  Pods
//
//  Created by Ali Gangji on 3/27/16.
//
//

import CoreData

public class CDALManager: NSObject {

    let configuration:CDALConfigurationProtocol
    let alerts = CDALAlerts()
    
    var local:CDALBackendProtocol?
    var cloud:CDALCloudEnabledBackendProtocol?
    
    var persistentStoreCoordinator: NSPersistentStoreCoordinator? = nil

    init(configuration:CDALConfigurationProtocol) {
        self.configuration = configuration
    }
    
    convenience init(modelName:String) {
        self.init(configuration:CDALConfiguration(modelName:modelName))
    }
    
    public func setLocalBackend(backend:CDALBackendProtocol) {
        local = backend
    }
    
    public func setCloudBackend(backend:CDALCloudEnabledBackendProtocol) {
        cloud = backend
    }
    
    public func setup(completion:(() -> Void)?) {
        if let available = cloud?.isAvailable() {
            configuration.setCloudAvailable(available)
        }
        configuration.update()
        
        //1. Do we have a saved preference?
        if configuration.isCloudPreferenceSelected() {
            initializePreferredBackend(completion)
        } else if configuration.isCloudAvailable() {
            print("cloud available")    
            //available but not selected - prompt to ask
            configuration.setFirstInstall(true)
            choosePreferredBackend(completion)
        } else {
            //not selected and not available
            initializeLocalBackend(completion)
        }
    }
    
    /**
     * Prompt the user to choose a preferred backend and initialize it
     */
    func choosePreferredBackend(completion:(() -> Void)?) {
        alerts.cloudPreference() { choice in
            if choice == 1 {
                self.configuration.shouldUseCloud(false)
                self.initializeLocalBackend(completion)
            } else {
                self.configuration.shouldUseCloud(true)
                self.initializeCloudBackend(completion)
            }
        }
    }
    
    /**
     * Initialize a backend based on the users saved preference
     */
    func initializePreferredBackend(completion:(() -> Void)?) {
        if configuration.shouldUseCloud() {
            //user chose to use cloud
            if configuration.isCloudAvailable() {
                //enable cloud
                initializeCloudBackend(completion)
            } else {
                ///The cloud connection is no longer available
                
                //alert them we are switching to local storage, and
                //clear saved preference so they are prompted next time
                configuration.clearCloudPreference()
                //prompt user that they should sign in
                alerts.cloudSignout() { _ in
                    self.initializeLocalBackend(completion)
                }
            }
        } else {
            //user chose local only
            if configuration.isCloudAvailable() && cloudStoreExists() && !localStoreExists() {
                //prompt about migration
                alerts.cloudDisabled() { choice in
                    if choice == 1 {
                        self.configuration.shouldUseCloud(true)
                        self.initializeCloudBackend(completion)
                    } else if choice == 2 {
                        //keep data
                        self.configuration.shouldMigrateData(true)
                        self.initializeLocalBackend(completion)
                    } else if choice == 3 {
                        //delete data
                        self.configuration.shouldMigrateData(false)
                        self.initializeLocalBackend(completion)
                    }
                }
            } else {
                initializeLocalBackend(completion)
            }
        }
    }
    
    func initializeLocalBackend(completion:(() -> Void)?) {
        configuration.setCloudEnabled(false)
    }
    
    func initializeCloudBackend(completion:(() -> Void)?) {
        configuration.setCloudEnabled(true)
        cloud?.authenticate() { changed in
            if changed {
                self.alerts.cloudSignout() {
                    self.createStack(completion)
                }
            } else {
                self.createStack(completion)
            }
        }
    }
    
    func createStack(completion:(() -> Void)?) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            self.migrateFilesIfRequired() { Void in
                self.openPersistentStore(nil)
                self.configuration.setFirstInstall(false)
            }
            
        })
    }
    
    private func localStoreExists() -> Bool {
        if let exists = local?.storeExists() {
            return exists
        }
        return false
    }
    
    private func cloudStoreExists() -> Bool {
        if let exists = cloud?.storeExists() {
            return exists
        }
        return false
    }
    
    // MARK: - Core Data Stack
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource(self.configuration.getModelName(), withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            //FLOG(" Error getting managedObjectContext because persistentStoreCoordinator is nil")
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        // Set the MergePolicy to prioritise external inputs
        let mergePolicy = NSMergePolicy(mergeType:NSMergePolicyType.MergeByPropertyStoreTrumpMergePolicyType )
        managedObjectContext.mergePolicy = mergePolicy
        return managedObjectContext
    }()
    
    /**
     * Creates a backup of the Local store
     * @return Returns YES of file was migrated or NO if not.
     */
    func saveBackup(backend:CDALBackendProtocol) -> Bool {
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        return backend.saveBackup(coordinator)
    }
}
