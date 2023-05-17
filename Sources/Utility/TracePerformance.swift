//
//  TracePerformance.swift
//  
//
//  Created by Sankaran, Anand on 6/15/20.
//  Copyright © 2020 Sankaran, Anand. All rights reserved.

import Foundation

public protocol TracePerformance {
    /**
    This method is used for stop the trace
    */
    func stop()

    /**
    This method is used for start the trace with the given name

    - parameter name: Name of the trace
    
    */
    func start(name: String)
    
    /**
    This method is used for set additional attributes for the trace

    - parameter value: Value of the attribute

    - parameter forAttribute: Attribute name

    */
    func setValue(_ value:String, forAttribute:String)
    
    /**
    This method is used to increase the metric count

    - parameter key: The metric key

    - parameter by: Number of value to be increased

    */
    func incrementMetric(_ key:String, by: Int)
}

public protocol DecoderTracePerformance {
    /**
     performaneAttribute -  additional performance attraibutes
    */
    var performaneAttribute: [String:String]? {get}
}
