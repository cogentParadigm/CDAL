//
//  CDALDatabase.swift
//  Pods
//
//  Created by Ali Gangji on 4/28/16.
//
//
import CoreData

public class CDALDatabase: NSObject {
    
    let context:NSManagedObjectContext
    
    public init(context:NSManagedObjectContext) {
        self.context = context
    }
    
    public func create<EntityType: NSManagedObject>() -> EntityType {
        let item = NSEntityDescription.insertNewObjectForEntityForName("\(EntityType.self)", inManagedObjectContext: context) as! EntityType
        return item
    }
    // MARK: - FETCH
    public func query<EntityType: NSManagedObject>(request:NSFetchRequest) -> [EntityType]? {
        let entity = NSEntityDescription.entityForName("\(EntityType.self)".componentsSeparatedByString(".").last!, inManagedObjectContext: context)
        request.entity = entity
        return (try? context.executeFetchRequest(request)) as? [EntityType]
    }
    
    // MARK: - SAVING
    public func save() {
        saveContext(context)
    }
    public func save(object:NSManagedObject) {
        faultObject(object, moc: context)
    }
    public func saveContext(moc:NSManagedObjectContext) {
        moc.performBlockAndWait {
            
            if moc.hasChanges {
                
                do {
                    try moc.save()
                    //print("SAVED context \(moc.description)")
                } catch {
                    print("ERROR saving context \(moc.description) - \(error)")
                }
            } else {
                //print("SKIPPED saving context \(moc.description) because there are no changes")
            }
            if let parentContext = moc.parentContext {
                self.saveContext(parentContext)
            }
        }
    }
    public func faultObject(object:NSManagedObject, moc:NSManagedObjectContext) {
        moc.performBlockAndWait {
            if object.hasChanges {
                self.saveContext(moc)
            }
            if object.fault == false {
                moc.refreshObject(object, mergeChanges: false)
            }
            if let parentMoc = moc.parentContext {
                self.faultObject(object, moc: parentMoc)
            }
        }
    }
}
