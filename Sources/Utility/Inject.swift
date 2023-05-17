//
//  Inject.swift
//  
//
//  Created by Sankaran, Anand on 6/15/20.
//  Copyright © 2020 Sankaran, Anand. All rights reserved.

import Foundation

public struct Global {
    public static var inject = DIInject.globalInstance()
}


@resultBuilder public struct Builder {
    public static func buildBlock(_ component: DIComponent) -> DIComponent { component }
}

// MARK: Resolver protocol
public protocol Resolver {
    func register(@Builder _ component: () -> DIComponent)
    func unregister(_ type: Any.Type)
    func component<T>() -> T?
    func component<T>(for name:String?) -> T?
}

public class DIInject {
    private let parent: Resolver?
    fileprivate var components = [String: DIComponent]()
    
    public init(parent: Resolver? = nil) {
        self.parent = parent
    }
    
    fileprivate static func globalInstance() -> Resolver {
        let instance = DIInject()
        instance.register { DIComponent("parent", scope: .container) { instance as Resolver } }
        instance.register { DIComponent(.container) { instance as Resolver } }
        return instance
    }

}


// MARK: Inject implement Resolver
extension DIInject: Resolver {
    
    public func register(@Builder _ component: () -> DIComponent){
        let component = component()
        if components[component.name] != nil {
            print("'\(component.name)' is already registered and now overriding it")
        }
        components[component.name] = component
    }
    
    public func unregister(_ type: Any.Type) {
        components.removeValue(forKey: String(describing: type))
    }
    
    public func component<T>() -> T? {
        return component(for: String(describing: T.self))
    }
    
    
    public func component<T>(for name: String?) -> T? {
        let name = name ?? String(describing: T.self)
        let component = components[name]
        if let object:T = component?.resolveObject() {
            return object
        }
        if let object:T =  parent?.component(for: name) {
            return object
        }
        
        if T.self == Optional(T.self) {
            return nil
        }
        
        fatalError("Dependency '\(T.self)' not resolved!")
    }
}

private struct InjectValue<T> {
    private let name: String?
    private var storage: T?
    private let resolver:  Resolver
    public init<Wrapped>(_ name: String? = nil, resolveName: String? = nil ) where T == Optional<Wrapped> {
        self.name = name
        if let resolverName = resolveName {
            self.resolver = Global.inject.component(for: resolverName) ?? Global.inject
        } else {
            self.resolver = Global.inject
        }
    }
    
    public init(_ name: String? = nil, resolveName: String? = nil ) {
        self.name = name
        if let resolverName = resolveName {
            self.resolver = Global.inject.component(for: resolverName) ?? Global.inject
        } else {
            self.resolver = Global.inject
        }
    }
    
    fileprivate mutating func getValue() -> T? {
        if let value = storage {
            return value
        } else if let value: T = resolver.component(for: name) {
            self.storeValue(value: value)
            return value
        }
        return nil
    }
    private mutating func storeValue(value: T) {
        storage = value
    }
    
}

//MARK: PropertyWrapper


@propertyWrapper
public struct Inject<Value> {
    private var injectValue: InjectValue<Value>
    private var optionalFlag: Bool = false
    public var wrappedValue: Value {
        mutating get {
            return self.injectValue.getValue()!
        }
        
        mutating set {
            
        }
    }
    
    public init() {
        self.injectValue = InjectValue()
    }
    
    public init(_ name: String) {
        self.injectValue = InjectValue(name)
    }
    public init(_ name: String, resolveName: String ) {
        self.injectValue = InjectValue(name, resolveName: resolveName)
    }
    
    public init(resolveName: String ) {
        self.injectValue = InjectValue(nil, resolveName: resolveName)
    }
    
}

@propertyWrapper
public struct OptionalInject<Value> {
    private var injectValue: InjectValue<Value>
    private var optionalFlag: Bool = false
    public var wrappedValue: Value? {
        mutating get {
            return self.injectValue.getValue()
        }
    }
    
    public init() {
        self.injectValue = InjectValue()
    }
    
    public init(_ name: String) {
        self.injectValue = InjectValue(name)
    }
    public init(_ name: String, resolveName: String ) {
        self.injectValue = InjectValue(name, resolveName: resolveName)
    }
    
    public init(resolveName: String ) {
        self.injectValue = InjectValue(nil, resolveName: resolveName)
    }
    
}

//MARK: DIComponent struct
public class DIComponent {
    internal let name: String
    internal let resolve: () -> Any
    internal let scope: ObjectScope
    fileprivate weak var object: AnyObject?
    public init<T>(_ name: String, scope: ObjectScope, _ resolve: @escaping () -> T) {
        
        self.name = name
        self.resolve = resolve
        self.scope = scope
    }
    
    public convenience init<T>(_ name: String? = nil, _ resolve: @escaping () -> T) {
        self.init(name ?? String(describing: T.self), scope: .transient, resolve)
    }
    
    public convenience init<T>(_ scope: ObjectScope, _ resolve: @escaping () -> T) {
        self.init(String(describing: T.self), scope: scope, resolve)
    }
    
    public func resolveObject<T>() -> T? {
        switch scope {
        case .container:
            if let object = object {
                return object as? T
            }
            let object = resolve()
            self.object = object as AnyObject
            return object as? T
    
        case .transient:
            return resolve() as? T
        }
    }
}

//MARK: ObjectScope
public enum ObjectScope {
    case transient
    case container
}


