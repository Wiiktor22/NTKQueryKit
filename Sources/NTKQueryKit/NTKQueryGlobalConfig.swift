//
//  NTKQueryGlobalConfig.swift
//
//
//  Created by Wiktor Szlegier on 20/10/2023.
//

import Foundation

final class NTKQueryGlobalConfig {
    typealias QueriesConfigDictionary = [String: QueryConfig]
    typealias MutationsConfigDictionary = [String: MutationConfig]
    typealias GlobalOnErrorFunction = (_ payload: GlobalErrorParameters) -> Void
    
    static let shared = NTKQueryGlobalConfig()
    
    private var isInitialized = false
    internal var queriesConfig: QueriesConfigDictionary = [:]
    internal var globalOnErrorQuery: GlobalOnErrorFunction?
    internal var mutationsConfig: MutationsConfigDictionary = [:]
    internal var globalOnErrorMutation: GlobalOnErrorFunction?
    
    private init() {}
    
    func initializeWithConfiguration(
        queriesConfig: QueriesConfigDictionary? = nil,
        globalOnErrorQuery: GlobalOnErrorFunction? = nil,
        mutationsConfig: MutationsConfigDictionary? = nil,
        globalOnErrorMutation: GlobalOnErrorFunction? = nil
    ) {
        if (isInitialized == false) {
            self.queriesConfig = queriesConfig ?? [:]
            self.mutationsConfig = mutationsConfig ?? [:]
            self.globalOnErrorQuery = globalOnErrorQuery
            self.globalOnErrorMutation = globalOnErrorMutation
            
            self.isInitialized = true
        }
    }
    
    // NOTE: Only used for testing purposes
    internal func deinitializeConfiguration() {
        self.isInitialized = false
        self.queriesConfig = [:]
        self.mutationsConfig = [:]
        self.globalOnErrorQuery = nil
        self.globalOnErrorMutation = nil
    }
}
