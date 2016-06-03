//
//  CDALQuery.swift
//  Pods
//
//  Created by Ali Gangji on 5/1/16.
//
//

import CoreData

public class CDALQuery: NSObject {
    
    var entityName:String
    var predicates = [NSPredicate]()
    var sorts = [NSSortDescriptor]()
    var distinct = false
    var properties = [String]()
    
    public init(entityName:String) {
        self.entityName = entityName
    }
    
    public func from(entityName:String) -> CDALQuery {
        self.entityName = entityName
        return self
    }
    
    public func sort(key:String, ascending:Bool) -> CDALQuery {
        sorts.append(NSSortDescriptor(key: key, ascending: ascending))
        return self
    }
    
    public func condition(predicate:NSPredicate) -> CDALQuery {
        predicates.append(predicate)
        return self
    }
    
    public func distinct(value:Bool) {
        distinct = value
    }
    
    public func properties(list:[String]) {
        properties.appendContentsOf(list)
    }
    
    public func build() -> NSFetchRequest {
        let request = NSFetchRequest(entityName: entityName)
        request.sortDescriptors = sorts
        if distinct {
            request.returnsDistinctResults = true
            request.resultType = .DictionaryResultType
        }
        if properties.count > 0 {
            request.propertiesToFetch = properties
        }
        if !predicates.isEmpty {
            let conditions = NSCompoundPredicate(type: .AndPredicateType, subpredicates: predicates)
            request.predicate = conditions
        }
        return request
    }
}
