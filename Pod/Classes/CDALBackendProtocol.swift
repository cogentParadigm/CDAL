//
//  CDALBackendProtocol.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

public protocol CDALBackendProtocol {
    func isAvailable() -> Bool
    func storeExists() -> Bool
}

public protocol CDALCloudEnabledBackendProtocol: CDALBackendProtocol {
    func authenticate(completion:((Bool) -> Void)?)
}
