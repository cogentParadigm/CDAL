//
//  CDALManager.swift
//  Pods
//
//  Created by Ali Gangji on 3/27/16.
//
//

import CoreData

public struct CDALNotificationType {
    static let StoreOpened = "CDALStoreOpened"
    static let StoreChanged = "CDALStoreChanged"
    static let UnhandledException = "CDALUnhandledException"
}

public class CDALManager: NSObject {

    let configuration:CDALConfigurationProtocol
    let alerts = CDALAlerts()
    
    var local:CDALBackendProtocol?
    var cloud:CDALCloudEnabledBackendProtocol?

    public init(configuration:CDALConfigurationProtocol) {
        self.configuration = configuration
    }
    
    convenience init(modelName:String) {
        self.init(configuration:CDALConfiguration(modelName:modelName))
    }
    
    //MARK: Property Setters
    public func setLocalBackend(backend:CDALBackendProtocol) {
        local = backend
    }
    
    public func setCloudBackend(backend:CDALCloudEnabledBackendProtocol) {
        cloud = backend
    }
    
    //MARK: Property Getters
    public func backend() -> CDALBackendProtocol {
        if configuration.isCloudEnabled() {
            return cloud!
        }
        return local!
    }
    public func mainContext() -> NSManagedObjectContext {
        return context
    }
    
    //MARK: Initialization Sequence
    public func setup(completion:(() -> Void)?) {
        if let available = cloud?.isAvailable() {
            configuration.setCloudAvailable(available)
        }
        configuration.update()
        
        //Do we have a saved preference?
        if configuration.isCloudPreferenceSelected() {
            initializePreferredBackend(completion)
        } else if configuration.isCloudAvailable() {
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
        self.createStack(completion)
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
    
    private func migrateDataIfRequired(completion:() -> Void) {
        if (configuration.isCloudEnabled()) {
            //using cloud
            if (localStoreExists()) {
                if (cloudStoreExists()) {
                    //prompt about merge
                    alerts.cloudMerge() { choice in
                        if choice == 1 {
                            //merge
                            if (self.migrate(self.local!, destination: self.cloud!, shouldDelete: true, shouldBackup: true)) {
                                self.configuration.hasJustMigrated(true)
                            }
                            completion()
                        } else if choice == 2 {
                            //don't merge
                            completion()
                        }
                    }
                } else {
                    if (migrate(local!, destination: cloud!, shouldDelete: true, shouldBackup: true)) {
                        configuration.hasJustMigrated(true)
                    }
                    completion()
                }
            } else {
                //using cloud but no local store to migrate
                completion()
            }
        } else {
            //using local
            if (!configuration.isFirstInstall() && cloudStoreExists()) {
                if (configuration.shouldMigrateData()) {
                    if (localStoreExists()) {
                        if (migrate(cloud!, destination: local!, shouldDelete:true, shouldBackup: true)) {
                            configuration.hasJustMigrated(true)
                        }
                    } else {
                        //not prompting about merge
                    }
                } else {
                    cloud?.delete()
                    deregisterForStoreChanges()
                }
            }
            completion()
        }
    }
    
    func createStack(completion:(() -> Void)?) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            self.migrateDataIfRequired() { Void in
                self.open(completion)
                self.configuration.setFirstInstall(false)
            }
            
        })
    }
    
    //MARK: - OPERATIONS
    func open(completion:(() -> Void)?) {
        if configuration.isStoreOpen() {
            completion?()
            return
        }
        configuration.isStoreOpening(true)
        registerForStoreChanges(coordinator)
        do {
            try backend().addToCoordinator(coordinator)
            configuration.isStoreOpening(false)
            configuration.isStoreOpen(true)
            completion?()
            postStoreOpenedNotification()
        } catch {
            completion?()
        }
    }
    
    public func migrate(source:CDALBackendProtocol, destination:CDALBackendProtocol, shouldDelete:Bool, shouldBackup:Bool) -> Bool {
        if (shouldBackup && source.storeExists()) {
            saveBackup(source)
        }
        
        let coordinator = createCoordinator()
        let sourceStore:NSPersistentStore?
        
        do {
            sourceStore = try source.addToCoordinator(coordinator)
        } catch _ {
            sourceStore = nil
        }
        
        if (sourceStore == nil) {
            return false
        } else {
            let newStore:NSPersistentStore?
            do {
                newStore = try destination.migrateStore(sourceStore!, coordinator: coordinator)
            } catch _ {
                newStore = nil
            }
            
            if (newStore != nil) {
                deregisterForStoreChanges()
                if (shouldDelete) {
                    destination.delete()
                }
                return true
            } else {
                return false
            }
        }
    }
    
    // MARK: - MODEL
    lazy var model: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource(self.configuration.getModelName(), withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    // MARK: - CONTEXT
    lazy var parentContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.PrivateQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.coordinator
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    lazy var context: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.MainQueueConcurrencyType)
        moc.parentContext = self.parentContext
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    lazy var importContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.PrivateQueueConcurrencyType)
        moc.parentContext = self.context
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    lazy var sourceContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.PrivateQueueConcurrencyType)
        moc.parentContext = self.context
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    lazy var seedContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.PrivateQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.seedCoordinator
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    
    // MARK: - COORDINATOR
    lazy var coordinator: NSPersistentStoreCoordinator = {
        return NSPersistentStoreCoordinator(managedObjectModel:self.model)
    }()
    lazy var sourceCoordinator:NSPersistentStoreCoordinator = {
        return NSPersistentStoreCoordinator(managedObjectModel:self.model)
    }()
    lazy var seedCoordinator:NSPersistentStoreCoordinator = {
        return NSPersistentStoreCoordinator(managedObjectModel:self.model)
    }()
    
    //MARK: - HELPERS
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
    
    /**
     * Creates a backup of the specified backend
     * @return Returns YES of file was migrated or NO if not.
     */
    private func saveBackup(backend:CDALBackendProtocol) -> Bool {
        return backend.saveBackup(createCoordinator())
    }
    
    private func createCoordinator() -> NSPersistentStoreCoordinator {
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        return coordinator
    }
    
    private func registerForStoreChanges(storeCoordinator: NSPersistentStoreCoordinator) {
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(storesWillChange(_:)), name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: storeCoordinator)
        nc.addObserver(self, selector: #selector(storesDidChange(_:)), name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: storeCoordinator)
        nc.addObserver(self, selector: #selector(storesDidImport(_:)), name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: storeCoordinator)
    }
    
    private func deregisterForStoreChanges() {
        let nc = NSNotificationCenter.defaultCenter()
        nc.removeObserver(self,  name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object:nil)
        nc.removeObserver(self, name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object:nil)
        nc.removeObserver(self, name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object:nil)
        
    }
    
    private func postStoreOpenedNotification() {
        NSNotificationCenter.defaultCenter().postNotificationName(CDALNotificationType.StoreOpened,
                object:self)
    }
    
    private func postStoreChangedNotification() {
        NSNotificationCenter.defaultCenter().postNotificationName(CDALNotificationType.StoreChanged,
                object:self)
    }
    
    func storesWillChange(n:NSNotification) {
        self.sourceContext.performBlockAndWait {
            do {
                try self.sourceContext.save()
                self.sourceContext.reset()
            } catch {print("ERROR saving sourceContext \(self.sourceContext.description) - \(error)")}
        }
        self.importContext.performBlockAndWait {
            do {
                try self.importContext.save()
                self.importContext.reset()
            } catch {print("ERROR saving importContext \(self.importContext.description) - \(error)")}
        }
        self.context.performBlockAndWait {
            do {
                try self.context.save()
                self.context.reset()
            } catch {print("ERROR saving context \(self.context.description) - \(error)")}
        }
        self.parentContext.performBlockAndWait {
            do {
                try self.parentContext.save()
                self.parentContext.reset()
            } catch {print("ERROR saving parentContext \(self.parentContext.description) - \(error)")}
        }
    }
    
    func storesDidChange(n:NSNotification) {
        postStoreChangedNotification()
    }
    
    func storesDidImport(n:NSNotification) {
        self.context.mergeChangesFromContextDidSaveNotification(n)
        self.postStoreChangedNotification()
    }
}
