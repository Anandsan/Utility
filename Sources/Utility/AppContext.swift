//
//  AppContext.swift
//
//
//  Created by Sankaran, Anand on 11/12/20.
//  Copyright © 2020 Sankaran, Anand. All rights reserved.

import Foundation

// Enum to hold the App status
public enum AppStatus {
    /**
     inactive - Inactive state from given date
     */
    case inactive(Date)
    /**
     active -  Active state from given date
     */
    case active(Date)
}

public let kAppStatusKey = "appstatus"

public protocol AppContextChangeObserver: AnyObject  {
    /**
    This method is used to delegate the context change event

    - parameter for: context key

    - parameter newValue: changed value
     
    - parameter oldValue: old value

    */
    func changeContext(for key:String, newValue: Any?, oldValue: Any?)
}

public protocol AppContext {
    /**
    This method is used to set the app level context

    - parameter value: context value

    - parameter forKey: context's key

    */
    func setContext(_ value:Any?, forKey key: String)
    
    /**
    This method is used to get the app level context value for given key

    - parameter forKey: context's key

    */
    func getContext<T>(forKey key:String, as type: T.Type) -> T?
    
    /**
    This method is used to register the observer for context change event

    - parameter obsever: AppContextChangeObserver object
    - parameter forKey: context's key

    */
    func register(_ observer: AppContextChangeObserver, forContentChange key:String)
}

fileprivate struct ObservingComponent {
    weak var observer: AppContextChangeObserver?
    let key: String
    
    init(_ observer: AppContextChangeObserver, key: String) {
        self.observer = observer
        self.key = key
    }
}

class AppLevelContextHandler {
    @Inject fileprivate var persistence: Persistence
    fileprivate var register = [ObservingComponent]()
    private lazy var semaphore = DispatchSemaphore(value: 1)
}

extension AppLevelContextHandler: AppContext {
    
    func setContext(_ value: Any?, forKey key: String) {
        let oldValue: Any? = persistence.getValue(forKey: key, in: self)
        persistence.setValue(value, forKey: key, in: self)
        semaphore.wait()
        let filtered = register.filter { $0.key == key }
        var cleanupFlag = false
        var observers = [AppContextChangeObserver]()
        filtered.forEach { (component) in
            if let observer = component.observer {
                observers.append(observer)
            } else {
                cleanupFlag = true
            }
        }
        if cleanupFlag {
            register = register.filter { $0.observer != nil }
        }
        semaphore.signal()

        DispatchQueue.global().async {
            observers.forEach { (observer) in
                observer.changeContext(for: key, newValue: value, oldValue: oldValue)
            }
        }
    }
    
    func getContext<T>(forKey key: String, as type: T.Type = T.self) -> T? {
        return persistence.getValue(forKey: key, in: self)
        
    }
    
    func register(_ observer: AppContextChangeObserver, forContentChange key: String) {
        semaphore.wait()
        register.append(ObservingComponent(observer, key: key))
        semaphore.signal()
    }
}

extension AppStatus: Equatable {
    public static func == (lhs: AppStatus, rhs: AppStatus) -> Bool {
        switch (lhs, rhs) {
        case (.inactive, .inactive ): return true
        case (.active, .active ): return true
        default: return false
        }
    }
}
