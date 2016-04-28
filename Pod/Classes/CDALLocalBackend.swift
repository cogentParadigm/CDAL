//
//  CDALLocalBackend.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

import CoreData

public class CDALLocalBackend: NSObject, CDALBackendProtocol {
    
    let name:String
    
    public init(name:String) {
        self.name = name
        super.init()
    }
    
    public func getStoreName() -> String {
        return name
    }

}
