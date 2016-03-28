//
//  CDALFactory.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

public class CDALFactory: NSObject {
    public func create() -> CDALManager {
        let local = CDALLocalBackend(name: "MarkMyWorld")
        let cloud = CDALCloudBackend(name: "MarkMyWorld_ICLOUD")
        let CDAL = CDALManager()
        CDAL.setLocalBackend(local)
        CDAL.setCloudBackend(cloud)
        return CDAL
    }
}
