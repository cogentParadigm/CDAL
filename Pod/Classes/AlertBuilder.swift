//
//  AlertBuilder.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

class AlertBuilder: NSObject {
    
    let controller:UIAlertController
    var completion:(()->Void)?
    
    init(title:String, message:String) {
        controller = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        super.init()
    }
    
    convenience init(title:String, message:String, handler:(()->Void)?) {
        self.init(title:title, message:message)
        setCompletionHandler(handler)
    }
    
    func setCompletionHandler(handler:(()->Void)?) -> AlertBuilder {
        completion = handler
        return self
    }
    
    func addAction(title:String, handler:(UIAlertAction)->Void) -> AlertBuilder {
        let action = UIAlertAction(title: title, style: UIAlertActionStyle.Default) { (alert:UIAlertAction!) in
            handler(alert)
            if (self.completion != nil) {
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.completion!()
                }
            }
        }
        controller.addAction(action)
        return self
    }
    
    func show() -> AlertBuilder {
        if let target = UIApplication.sharedApplication().keyWindow?.rootViewController {
            
            
            if let view:UIView = UIApplication.sharedApplication().keyWindow?.subviews.last {
                
                controller.popoverPresentationController?.sourceView = view
                
                target.presentViewController(controller, animated: true, completion: nil)
            }
        }
        return self
    }

}
