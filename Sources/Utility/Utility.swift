//
//  Utility.swift
//  
//
//  Created by Sankaran, Anand on 12/19/22.
//

import Foundation

public class Utility {
    
    private static let persistence = PersistenceHandler()
    static let appContext = AppLevelContextHandler()
    public static func config() {
        Global.inject.register {DIComponent("JSONDecoder") { JSONDecoder()  as DataDecoder} }
        Global.inject.register {DIComponent("JSONEncoder") { JSONEncoder()  as DataEncoder} }
        Global.inject.register {DIComponent("URLDataEncoder") { URLDataEncoderImpl() as URLDataEncoder } }
        Global.inject.register {DIComponent(.container) { persistence as Persistence } }
        Global.inject.register {DIComponent(.container) { appContext as AppContext } }
    }
    
    public static func injectDependency(@Builder _ component: () -> DIComponent) {
        Global.inject.register(component)
    }
}

