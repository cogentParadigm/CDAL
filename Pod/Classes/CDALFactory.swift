//
//  CDALFactory.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

class CDALFactory: NSObject {
    func create() {
        let local = CDALLocalBackend(name: "MarkMyWorld")
        let cloud = CDALCloudBackend(name: "MarkMyWorld_ICLOUD")
        let configuration = CDALConfiguration(localBackend: local, cloudBackend: cloud)
    }
}
