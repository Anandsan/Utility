//
//  CommonProtocols.swift
//  
//
//  Created by Sankaran, Anand on 6/17/20.
//  Copyright © 2020 Sankaran, Anand. All rights reserved.

import Foundation
import UIKit

public protocol DataEncoder {
    func encode<T>(_ value: T) throws -> Data where T : Encodable
}

public protocol DataDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}

public protocol URLDataEncoder {
    func encode<T>(_ value: T) throws -> Data where T : URLEncodable
}

public protocol URLEncodable {
    func encode<T>(_ value: T) throws -> Data where T : URLEncoder
}

public protocol URLEncoder {
    func encode(dict: [String: String]) throws -> Data
}
