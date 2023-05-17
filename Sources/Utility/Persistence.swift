//
//  PersistenceHandler.swift
//  
//
//  Created by Sankaran, Anand on 11/12/20.
//  Copyright © 2020 Sankaran, Anand. All rights reserved.

import Foundation

public protocol Persistence {
    /**
    This method is used to set the value in the memory for given key at component

    - parameter value: context value

    - parameter forKey: context's key
     
    - parameter in: component class  which owns this value

    */
    func setValue(_ value:Any?, forKey key: String, in component: AnyObject)
    
    /**
    This method is used to get the value for given key from the component


    - parameter forKey: context's key
     
    - parameter in: component class  which owns this value

    */
    func getValue<T>(forKey key: String, in component: AnyObject) -> T?
}

class PersistenceHandler {
    var data = [String:Any]()
    private lazy var semaphore = DispatchSemaphore(value: 1)
    
}

extension PersistenceHandler: Persistence {
    
    private func keyValue(for key:String, in component:AnyObject) -> String {
        let bundle = Bundle(for: type(of: component))
        return bundle.bundleURL.lastPathComponent + "_" + key
    }
    
    func setValue(_ value:Any?, forKey key: String, in component: AnyObject) {
        semaphore.wait()
        let componentNameWithKey = keyValue(for: key, in: component)
        if let value = value {
            data[componentNameWithKey] = value
        } else {
            data.removeValue(forKey: componentNameWithKey)
        }
        semaphore.signal()
    }
    
    func getValue<T>(forKey key: String, in component: AnyObject) -> T? {
        semaphore.wait()
        defer { semaphore.signal() }
        let componentNameWithKey = keyValue(for: key, in: component)
        return data[componentNameWithKey] as? T
    }
}
