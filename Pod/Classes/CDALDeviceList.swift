//
//  CDALDeviceList.swift
//  Pods
//
//  Created by Ali Gangji on 4/13/16.
//
//

class CDALDeviceList: NSObject, NSFilePresenter {
    
    var presentedItemURL: NSURL?
    var presentedItemOperationQueue: NSOperationQueue
    
    public init(url:NSURL, queue:NSOperationQueue) {
        presentedItemURL = url
        presentedItemOperationQueue = queue
        super.init()
    }
    
    func presentedItemDidChange() {
        
    }
    
    func accommodatePresentedItemDeletionWithCompletionHandler(completionHandler: (NSError?) -> Void) {
        completionHandler(nil)
    }
    
}
