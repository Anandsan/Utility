//
//  URLDataEncoderImpl.swift
//  
//
//  Created by Sankaran, Anand on 6/15/20.
//  Copyright © 2020 Sankaran, Anand. All rights reserved.

import Foundation

class URLDataEncoderImpl: URLDataEncoder, URLEncoder {
    
    init() {}
    
    func encode<T>(_ value: T) throws -> Data where T : URLEncodable {
        try value.encode(self)
    }
    
    func encode(dict: [String : String]) -> Data {
        let jsonString = dict.reduce("") { "\($0)\($1.0)=\($1.1)&" }.dropLast()
        return jsonString.data(using: .utf8, allowLossyConversion: false)!
    }
}
