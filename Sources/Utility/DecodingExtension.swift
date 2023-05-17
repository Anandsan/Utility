//
//  DecodingExtension.swift
//  
//
//  Created by Sankaran, Anand on 12/10/20.
//  Copyright © 2020 Sankaran, Anand. All rights reserved.

import Foundation

// MARK: - decode with string key
public extension KeyedDecodingContainer {
    
    /// Decode a value for a given key, specified as a string.
    func decode<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T {
        return try decode(type, forKey: AnyCodingKey(key) as! K)
    }

    /// Decode an optional value for a given key, specified as a string. Throws an error if the
    /// specified key exists but is not able to be decoded as the inferred type.
    func decodeIfPresent<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T? {
        return try decodeIfPresent(type, forKey: AnyCodingKey(key) as! K)
    }
}

// MARK: - decode date format
public extension KeyedDecodingContainer {
    
    private func formatDate<F: AnyDateFormatter>(from rawString: String, using formatter: F, forKey key:K ) throws -> Date {
        
        guard let date = formatter.date(from: rawString) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Unable to format date string(\(rawString)) for \(key.stringValue)"
            )
        }
        return date
    }

    /// Decode a date from a string for a given key (specified as a string), using a
    /// specific formatter. To decode a date using the decoder's default settings,
    /// simply decode it like any other value instead of using this method.
    func decode<F: AnyDateFormatter>(_ key: String, using formatter: F) throws -> Date {
        let key = AnyCodingKey(key) as! K
        let rawString = try decode(String.self, forKey: key )
        return try formatDate(from: rawString, using: formatter, forKey: key)
    }
    
    /// Decode a date from a string for a given key (specified as a string), using a
    /// specific formatter. To decode a date using the decoder's default settings,
    /// simply decode it like any other value instead of using this method.
    func decodeIfPresent<F: AnyDateFormatter>(_ key: String, using formatter: F) throws -> Date? {
        let key = AnyCodingKey(key) as! K
        if let rawString = try decodeIfPresent(String.self, forKey: key ) {
            return try formatDate(from: rawString, using: formatter, forKey: key)
        }
        
        return nil
    }
}

// MARK: - decode with keyPath
public extension KeyedDecodingContainer {

    /// Decode a value for a given keyPath, specified as a string.
    func decode<T: Decodable>(keyPath: String, as type: T.Type = T.self) throws -> T {
        var keys = keyPath.split(separator: ".")
        let firstKey = String(keys.removeFirst())
        if keys.count == 0 {
            return try decode(type, forKey: AnyCodingKey(firstKey) as! K)
        } else {
            let nextedContainer = try nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey(firstKey) as! K)
            let newKeyPath = keys.joined(separator: ".")
            return try nextedContainer.decode(keyPath: newKeyPath, as: type)
        }
    }
    
    /// Decode an optional value for a given keyPath, specified as a string. Throws an error if the
    /// specified key exists but is not able to be decoded as the inferred type.
    func decodeIfPresent<T: Decodable>(keyPath: String, as type: T.Type = T.self) throws -> T? {
        
        var keys = keyPath.split(separator: ".")
        var newKeyPath = ""
        var nextedContainer: KeyedDecodingContainer<AnyCodingKey>
        let firstKey = String(keys.removeFirst())
        if keys.count == 0 {
            return try decodeIfPresent(type, forKey: AnyCodingKey(firstKey) as! K)
        } else {
            do {
                nextedContainer = try nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey(firstKey) as! K)
                newKeyPath = keys.joined(separator: ".")
                
            } catch {
                return nil
            }
            return try nextedContainer.decodeIfPresent(keyPath: newKeyPath, as: type)
        }
    }
    
    /// Decode a date from a string for a given key (specified as a string), using a
    /// specific formatter. To decode a date using the decoder's default settings,
    /// simply decode it like any other value instead of using this method.
    func decode<F: AnyDateFormatter>(keyPath: String, using formatter: F) throws -> Date {
        var keys = keyPath.split(separator: ".")
        let firstKey = String(keys.removeFirst())
        if keys.count == 0 {
            return try decode(firstKey, using: formatter)
        } else {
            let nextedContainer = try nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey(firstKey) as! K)
            let newKeyPath = keys.joined(separator: ".")
            return try nextedContainer.decode(keyPath: newKeyPath, using: formatter)
        }
    }
    
    /// Decode a date from a string for a given key (specified as a string), using a
    /// specific formatter. To decode a date using the decoder's default settings,
    /// simply decode it like any other value instead of using this method.
    func decodeIfPresent<F: AnyDateFormatter>(keyPath: String, using formatter: F) throws -> Date? {
        var keys = keyPath.split(separator: ".")
        var newKeyPath = ""
        var nextedContainer: KeyedDecodingContainer<AnyCodingKey>
        let firstKey = String(keys.removeFirst())
        if keys.count == 0 {
            return try decodeIfPresent(firstKey, using: formatter)
        } else {
            do {
                nextedContainer = try nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey(firstKey) as! K)
                newKeyPath = keys.joined(separator: ".")
                
            } catch {
                return nil
            }
            return try nextedContainer.decodeIfPresent(keyPath: newKeyPath, using: formatter)
            
        }
    }
}

// MARK: - Date formatters
/// Protocol acting as a common API for all types of date formatters,
/// such as `DateFormatter` and `ISO8601DateFormatter`.
public protocol AnyDateFormatter {
    /// Format a string into a date
    func date(from string: String) -> Date?
    /// Format a date into a string
    func string(from date: Date) -> String
}

extension DateFormatter: AnyDateFormatter {}
extension ISO8601DateFormatter: AnyDateFormatter {}


// MARK: - Decoder container without Key
public extension Decoder {
    func container() throws -> KeyedDecodingContainer<AnyCodingKey> {
        try self.container(keyedBy: AnyCodingKey.self)
    }
}

// MARK: - Supporting types
public struct AnyCodingKey: CodingKey {
    public var stringValue: String
    public var intValue: Int?

    public init(_ string: String) {
        stringValue = string
    }

    public init?(stringValue: String) {
        self.stringValue = stringValue
    }

    public init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}

// MARK: - Decode Dictionary and Array
public extension KeyedDecodingContainer {

    func decode(_ keyString: String? = nil, as type: [String: Any].Type = Dictionary<String, Any>.self) throws -> [String: Any] {
        var key:K? = nil
        if let keyString = keyString {
            key = AnyCodingKey(keyString) as? K
        }
        return try decode([String: Any].self, forKey: key)
    }
    
    func decodeIfPresent(_ key: String, type: [String: Any].Type = [String: Any].self) throws -> [String: Any]? {
        let key = AnyCodingKey(key) as! K
        return try decodeIfPresent(type, forKey: key)
    }
    

    func decode(_ key: String, as type: [Any].Type = [Any].self) throws -> [Any] {
        let key = AnyCodingKey(key) as! K
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ key: String, as type: [Any].Type = [Any].self) throws -> [Any]? {
        let key = AnyCodingKey(key) as! K
        return try decodeIfPresent(type, forKey: key)
    }
    
    fileprivate func decode(_ type: [String: Any].Type, forKey key: K? = nil) throws -> [String: Any] {
        if let key = key {
            let container = try self.nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
            return try container.decode(type)
        } else {
            return try decode(type)
        }
    }
    
    fileprivate func decodeIfPresent(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any]? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    fileprivate func decode(_ type: [Any].Type, forKey key: K) throws -> [Any] {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }

    fileprivate func decodeIfPresent(_ type: [Any].Type, forKey key: K) throws -> [Any]? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }

    fileprivate func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        var dictionary = [String: Any]()

        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let nestedDictionary = try? decode([String: Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode([Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode(_ type: [Any].Type) throws -> [Any] {
        var array: [Any] = []
        
        while isAtEnd == false {
            if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Int.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode([String: Any].self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decodeNestedArray([Any].self) {
                array.append(nestedArray)
            } else if let isValueNil = try? decodeNil(), isValueNil == true {
                array.append(Optional<Any>.none as Any)
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Unable to decode value"))
            }
        }
        return array
    }
    
    mutating func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        let container = try nestedContainer(keyedBy: AnyCodingKey.self)
        return try container.decode(type)
    }
    
    mutating func decodeNestedArray(_ type: [Any].Type) throws -> [Any] {
        var container = try nestedUnkeyedContainer()
        return try container.decode(type)
    }
}

// MARK: - Decode Dictionary and Array keyPath
public extension KeyedDecodingContainer {
    
    func decode(keyPath: String, as type: [String: Any].Type = [String: Any].self) throws -> [String: Any] {
        var keys = keyPath.split(separator: ".")
        let firstKey = String(keys.removeFirst())
        if keys.count == 0 {
            return try decode(firstKey)
        } else {
            let nextedContainer = try nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey(firstKey) as! K)
            let newKeyPath = keys.joined(separator: ".")
            return try nextedContainer.decode(keyPath: newKeyPath, as: type)
        }
    }
    
    func decodeIfPresent(keyPath: String, as type: [String: Any].Type = [String: Any].self) throws -> [String: Any]? {
        var keys = keyPath.split(separator: ".")
        let firstKey = String(keys.removeFirst())
        if keys.count == 0 {
            return try decodeIfPresent(firstKey)
        } else {
            do {
                let nextedContainer = try nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey(firstKey) as! K)
                let newKeyPath = keys.joined(separator: ".")
                return try nextedContainer.decodeIfPresent(keyPath: newKeyPath, as: type)
            } catch {
                return nil
            }
        }
    }
    

    func decode(keyPath: String, as type: [Any].Type = [Any].self) throws -> [Any] {
        var keys = keyPath.split(separator: ".")
        let firstKey = String(keys.removeFirst())
        if keys.count == 0 {
            return try decode(firstKey)
        } else {
            let nextedContainer = try nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey(firstKey) as! K)
            let newKeyPath = keys.joined(separator: ".")
            return try nextedContainer.decode(keyPath: newKeyPath, as: type)
        }
    }

    func decodeIfPresent(keyPath: String, as type: [Any].Type = [Any].self) throws -> [Any]? {
        var keys = keyPath.split(separator: ".")
        let firstKey = String(keys.removeFirst())
        if keys.count == 0 {
            return try decodeIfPresent(firstKey)
        } else {
            do {
                let nextedContainer = try nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey(firstKey) as! K)
                let newKeyPath = keys.joined(separator: ".")
                return try nextedContainer.decodeIfPresent(keyPath: newKeyPath, as: type)
            } catch {
                return nil
            }
        }
    }
}
