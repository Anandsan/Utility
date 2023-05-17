//
//  NetworkSession.swift
//
//
//  Created by Sankaran, Anand on 6/16/20.
//  Copyright © 2020 Sankaran, Anand. All rights reserved.

import Foundation
import Combine

fileprivate let concurrentThreadCount = 5
fileprivate let contextTypeKey = "Content-Type"
fileprivate let contextTypeJSONValue = "application/json"
fileprivate let contextTypeXMLValue = "application/xml"
fileprivate let contextTypeURLEncodedValue = "application/x-www-form-urlencoded"

public enum NetworkError: Error {
    /**
        emptyData - No data found in the response payload
    */
    case emptyData
    /**
        unknowError - unknow error
    */
    case unknownError
    /**
        customError - Custom error defined by the program, which has message and error code
    */
    case customError(String, Int)
    
    /**
        customError - Custom error defined by the program, which has message, error code and addtionalAttributes
    */
    case customErrorWithAttributes(String, Int, [String:String])
    
    /**
        encoderNotAvailable - Encoder is not available
    */
    case encoderNotAvailable
    
    /**
        decoderNotAvailable - Decoder is not available
    */
    case decoderNotAvailable
    
    /**
        statusError - status error code
    */
    case statusError(Int)
}

extension NetworkError: Equatable {
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case ( .emptyData, .emptyData ):
            return true
        case ( .unknownError, .unknownError ):
            return true
        case (let .customError(lstringValue, lintValue), let .customError(rstringValue, rintValue) ):
            return lstringValue == rstringValue && lintValue == rintValue
        case (let .customErrorWithAttributes(lstringValue, lintValue, lattributes), let .customErrorWithAttributes(rstringValue, rintValue, rattributes) ):
            return lstringValue == rstringValue && lintValue == rintValue && lattributes == rattributes
        case (let .statusError(lintValue), let .statusError(rintValue) ):
            return lintValue == rintValue
        default:
            return false
        }
    }
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyData:
            return "Network Error: Empty data in response"
        case .unknownError:
            return "Network Error: Unknown"
        case .customError(let message, let code):
            return "Network Error: \(message) - \(code)"
        case .customErrorWithAttributes(let message, let code, _):
            return "Network Error: \(message) - \(code)"
        case .statusError(let code):
            return "Network Error: Status error - \(code)"
        case .decoderNotAvailable:
            return "Network Error: Decoder not available"
        case .encoderNotAvailable:
            return "Network Error: Encoder not available"
        }
    }
}

extension NetworkError: DecoderTracePerformance {
    public var performaneAttribute: [String : String]? {
        switch self {
        case .customErrorWithAttributes(_,_, let attributes):
            return attributes
        default:
            return nil
        }
    }
}

public enum NetworkResult<Value> {
    /**
       success - Network call success with generic Value and HTTP URL Response
    */
    case success(Value, HTTPURLResponse)
    /**
       failure - Network call failed with error and HTTP URL Response if available
    */
    case failure(Error, HTTPURLResponse?)
}

extension NetworkResult: Equatable where Value: Equatable {
    
    public static func == (lhs: NetworkResult<Value>, rhs: NetworkResult<Value>) -> Bool {
        switch (lhs, rhs) {
        case (let .success(lhsValue, _), let .success(rhsValue, _) ):
            return lhsValue == rhsValue
        case (let .failure(lhsError, _), let .failure(rhsError, _) ):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

public enum NetworkMethod: String {
    /**
     GET - Get HTTP call
     */
    case GET
    /**
     POST -  Post HTTP Call
     */
    case POST
}

public enum MIMEType {
    /**
       GET - Get HTTP call
    */
    case JSON
    /**
       POST -  Post HTTP Call
    */
    case XML
    /**
       POST -  Post HTTP Call
    */
    case URLEncoding
}

public enum NetworkCachePolicy {
    /**
       UseProtocol - Default network cache policy in url load request
    */
    case USEPROTOCOL
    /**
       ReloadIgnoringLocalCache - Used to download data from the origin source ignorning local cache data
    */
    case RELOADIGNORINGLOCALCACHE
}

public protocol NetworkRequest: Encodable, URLEncodable {
    /**
       url -  network request URL
    */
    var url: URL {get}
    /**
       method -  network method
    */
    var method: NetworkMethod {get}
    /**
       header -  network call HTTP header key and values
    */
    var header: [String:String] {get}
    /**
    This method is used for get the request MIMEType

    - returns MIMEType
    */
    func getMIMEType() -> MIMEType
    /**
    This method is used for get the request cache policy

    - returns NetworkCachePolicy
    */
    func getCachePolicy() -> NetworkCachePolicy
        
}

public enum NetworkSessionConfigurationType {
    /**
       Default -  Used to set default session configuration
    */
    case DEFAULT
    /**
       Ephermal -  Used to set  no persistent storage for caches, cookies, or credentials in session configuration
    */
    case EPHEMERAL
}

public protocol NetworkSessionConfiguration {
    /**
     timeOutForRequest -  Used to set timeOutIntervalForRequest
    */
    var timeOutForRequest: TimeInterval {get}
    /**
     timeOutForResource -  Used to set timeOutIntervalForResource
    */
    var timeOutForResource: TimeInterval {get}
    /**
     getNetworkSessionConfigType -  Used to get session configuration type
    */
    func getNetworkSessionConfigType() -> NetworkSessionConfigurationType
}

extension NetworkSessionConfiguration {
    public var timeOutForRequest: TimeInterval {
        return 60
    }
    
    public var timeOutForResource: TimeInterval {
        return 60
    }
    
    public func getNetworkSessionConfigType() -> NetworkSessionConfigurationType {
        return .DEFAULT
    }
}

extension NetworkRequest   {
    func body(resolver: Resolver ) throws -> Data {
        if getMIMEType() == .JSON {
            if let jsonEncoder: DataEncoder = resolver.component(for: "JSONEncoder") {
                return try jsonEncoder.encode(self)
            } else {
                throw NetworkError.encoderNotAvailable
            }
        } else if getMIMEType() == .URLEncoding {
            if let urlEncoder: URLDataEncoder = resolver.component(for: "URLDataEncoder") {
                return try urlEncoder.encode(self)
            } else {
                throw NetworkError.encoderNotAvailable
            }
        } else {
            // Handle the XML Encoder
            if let xmlEncoder: DataEncoder = resolver.component(for: "XMLEncoder") {
                return try xmlEncoder.encode(self)
            } else {
                throw NetworkError.encoderNotAvailable
            }

        }
    }
    
    public func  getMIMEType() -> MIMEType {
        return .JSON
    }
    
    public func getCachePolicy() -> NetworkCachePolicy {
        return .USEPROTOCOL
    }
    
    public func encode<T>(_ value: T) throws -> Data where T : URLEncoder {
        return "".data(using: .utf8)!
    }
}

public protocol NetworkSession {
    func dataPublisher<T>(request: NetworkRequest, type: T.Type) -> AnyPublisher<T, Error>  where T: Decodable
    func dataPublisher(request: URLRequest) -> AnyPublisher<Data, Error>
}

extension HTTPURLResponse {
    func isResponseOK() -> Bool {
        return (200...299).contains(self.statusCode)
    }
}

public class NetworkSessionImpl {
    
    let statusCodeOverRide : Bool
    let commonHeader:[String:String]
    let session: URLSession
    let delegateQueue = OperationQueue()
    private var sessionConfig:URLSessionConfiguration = .default
    
    @Inject fileprivate var resolver: Resolver
    
    public init(commonHeader:[String:String] = [:], statusCodeOverRide:Bool = false, networkSessionConfiguration: NetworkSessionConfiguration? = nil, _ session: URLSession? = nil) {
        self.commonHeader = commonHeader
        self.statusCodeOverRide = statusCodeOverRide
        if let session = session {
            self.session = session
        }
        else {
            if let tempNetworkSessionConfig = networkSessionConfiguration {
                switch tempNetworkSessionConfig.getNetworkSessionConfigType() {
                case .DEFAULT:
                    sessionConfig = .default
                case .EPHEMERAL:
                    sessionConfig = .ephemeral
                }
                sessionConfig.timeoutIntervalForRequest = tempNetworkSessionConfig.timeOutForRequest
                sessionConfig.timeoutIntervalForResource = tempNetworkSessionConfig.timeOutForResource
            }
            delegateQueue.qualityOfService = .utility
            delegateQueue.maxConcurrentOperationCount = concurrentThreadCount
            self.session = URLSession(
                configuration: sessionConfig,
                delegate: nil,
                delegateQueue: delegateQueue)
        }
    }
    
    deinit {
        session.finishTasksAndInvalidate()
    }
    
    fileprivate func getRequestCachePolicy(_ networkCachePolicy: NetworkCachePolicy) -> URLRequest.CachePolicy {
        switch networkCachePolicy {
        case .USEPROTOCOL:
            return .useProtocolCachePolicy
        case .RELOADIGNORINGLOCALCACHE:
            return .reloadIgnoringLocalCacheData
        }
    }
    
    fileprivate func requestObjectForPOSTCall(request r: NetworkRequest) throws -> URLRequest {
        var request = URLRequest(url:r.url)
        request.httpMethod = NetworkMethod.POST.rawValue
        switch r.getMIMEType() {
        case .XML:
            request.addValue(contextTypeXMLValue, forHTTPHeaderField: contextTypeKey)
        case .URLEncoding:
            request.addValue(contextTypeURLEncodedValue, forHTTPHeaderField: contextTypeKey)
        default:
            request.addValue(contextTypeJSONValue, forHTTPHeaderField: contextTypeKey)
        }
        request.cachePolicy = getRequestCachePolicy(r.getCachePolicy())
        request.httpBody = try r.body(resolver: self.resolver)
        return request
    }
    
    fileprivate func requestObjectForGETCall(request r: NetworkRequest) throws -> URLRequest {
        var request = URLRequest(url:r.url)
        request.httpMethod = NetworkMethod.GET.rawValue
        request.cachePolicy = getRequestCachePolicy(r.getCachePolicy())
        return request
    }
    
    fileprivate func track(errorMessage: String, in tracker: TracePerformance?) {
        tracker?.setValue(errorMessage, forAttribute: "Error")
        tracker?.stop()
    }
    
    fileprivate func data<T>(request: NetworkRequest, type: T.Type, callback: @escaping((NetworkResult<T>) -> Void)) where T: Decodable {
        let tracker: TracePerformance? = self.resolver.component()
        var urlRequest: URLRequest!
        let urlString = (request.url.host ?? "") + request.url.path
        tracker?.start(name: urlString)
        tracker?.setValue("NA", forAttribute: "Error")
        
        do {
            switch request.method {
            case .POST:
                urlRequest = try requestObjectForPOSTCall(request: request)
            case .GET:
                urlRequest = try requestObjectForGETCall(request: request)
            }
            request.header.forEach { (key, value) in
                urlRequest.addValue(value, forHTTPHeaderField: key)
            }
        }
        catch {
            tracker?.setValue(error.localizedDescription, forAttribute: "Error")
            tracker?.stop()
            callback(NetworkResult.failure(error, nil))
            return
        }
        
        self.data(request: urlRequest, type: type, callback: callback)
        
    }
    
    fileprivate func data<T>(request: URLRequest, type: T.Type, callback: @escaping((NetworkResult<T>) -> Void)) where T: Decodable {
        data(request: request) { [weak self] (result, tracker) in
            
            guard let strongself = self else {return}
            switch result {
            case .failure(let error, let response):
                callback(NetworkResult.failure(error, response))
                
            case .success(let data, let response):
                do {
                    let contectType: String = response.allHeaderFields["Content-Type"]  as? String ?? contextTypeJSONValue
                    var decoder:DataDecoder?
                    if contectType.caseInsensitiveCompare(contextTypeXMLValue) == .orderedSame {
                        decoder = strongself.resolver.component(for: "XMLDecoder")
                    } else {
                        decoder = strongself.resolver.component(for: "JSONDecoder")
                    }
                    
                    if let decoder = decoder {
                        let object:T = try decoder.decode(T.self, from: data)
                        if let additionalAttribute = (object as? DecoderTracePerformance)?.performaneAttribute {
                            additionalAttribute.forEach {
                                key, value in
                                tracker?.setValue(value, forAttribute: key)
                            }
                        }
                        callback(NetworkResult.success(object, response))
                    } else {
                        throw NetworkError.decoderNotAvailable
                    }
                    self?.track(errorMessage: "NA", in: tracker)
                    
                } catch {
                    
                    var errorMessage = error.localizedDescription
                    switch error {
                    case DecodingError.dataCorrupted(let context):
                        print("data corrupted")
                        errorMessage = context.debugDescription
                    case DecodingError.keyNotFound(let key, let context):
                        print("key not found")
                        if let key = key as? AnyCodingKey {
                            errorMessage = "Key \(key.stringValue) not found in \(context.codingPath )"
                        } else {
                            errorMessage = "Key \(key) not found in \(context.codingPath )"
                        }
                    case DecodingError.valueNotFound(let value, let context):
                        print("value not found")
                        errorMessage = "Value \(value) not found in \(context.codingPath )"
                    case DecodingError.typeMismatch(let type, let context):
                        print("type mismatch")
                        errorMessage = "Type \(type) mismatch in \(context.codingPath )"
                    default: break
                    }
                    
                    if let additionalAttribute = (error as? DecoderTracePerformance)?.performaneAttribute {
                        additionalAttribute.forEach {
                            key, value in
                            tracker?.setValue(value, forAttribute: key)
                        }
                        
                    }
                    self?.track(errorMessage: errorMessage, in: tracker)
                    callback(NetworkResult.failure(error, response))
                }
            }
        }
    }
    
    fileprivate func data(request: URLRequest, callback: @escaping((NetworkResult<Data>, TracePerformance?) -> Void))  {
        let tracker: TracePerformance? = self.resolver.component()
        let urlString = (request.url?.host ?? "") + (request.url?.path ?? "")
        tracker?.start(name: urlString)
        tracker?.setValue("NA", forAttribute: "Error")
        
        let resultBlock:((NetworkResult<Data>) -> Void) =  { (result) in
            switch result {
            case .failure(let error, _):
                tracker?.setValue(error.localizedDescription, forAttribute: "Error")
            case .success(_, _): break
            }
            callback(result, tracker)
            tracker?.stop()
        }
        
        var urlRequest = request
        let header = commonHeader.merging(urlRequest.allHTTPHeaderFields ?? [:]) { (_, new) in new }
        
        header.forEach { (key, value) in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                resultBlock(NetworkResult.failure(error, nil))
            } else if let response = response as? HTTPURLResponse{
                if self.statusCodeOverRide || response.isResponseOK() {
                    if let data = data {
                        resultBlock(NetworkResult.success(data, response))
                    } else {
                        resultBlock(NetworkResult.failure(NetworkError.emptyData, response))
                    }
                } else {
                    resultBlock(NetworkResult.failure(NetworkError.statusError(response.statusCode), response))
                }
            }
        }
        task.resume()
    }
}

extension NetworkSessionImpl: NetworkSession {
    public func dataPublisher(request: URLRequest) -> AnyPublisher<Data, Error> {
        let future = Future<Data, Error> { promise in
            self.data(request: request) { (result, _) in
                switch result {
                case .failure(let error, _):
                    promise(.failure(error))
                case .success(let value, _):
                    promise(.success(value))
                }
            }
        }
        return AnyPublisher(future)
    }
    
    public func dataPublisher<T>(request: NetworkRequest, type: T.Type) -> AnyPublisher<T, Error>  where T: Decodable {
        let future = Future<T, Error> { promise in
            self.data(request: request, type: type) { result in
                switch result {
                case .failure(let error, _):
                    promise(.failure(error))
                case .success(let value, _):
                    promise(.success(value))
                }
            }
        }
        return AnyPublisher(future)
    }
}
