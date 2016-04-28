//
//  CDALFactory.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

public class CDALFactory: NSObject {
    public func create(modelName:String, localStoreName:String, cloudStoreName:String) -> CDALManager {
        let local = CDALLocalBackend(name: localStoreName)
        let cloud = CDALCloudBackend(name: cloudStoreName)
        let CDAL = CDALManager(modelName:modelName)
        CDAL.setLocalBackend(local)
        CDAL.setCloudBackend(cloud)
        return CDAL
    }
}
