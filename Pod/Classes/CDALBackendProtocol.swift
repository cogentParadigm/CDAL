//
//  CDALBackendProtocol.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

protocol CDALBackendProtocol {
    func isAvailable() -> Bool
    func storeExists() -> Bool
    func setConfiguration(configuration:CDALConfiguration)
}

protocol CDALCloudEnabledBackendProtocol: CDALBackendProtocol {
    func authenticate()
}
