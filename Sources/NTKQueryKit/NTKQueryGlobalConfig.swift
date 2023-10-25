//
//  NTKQueryGlobalConfig.swift
//
//
//  Created by Wiktor Szlegier on 20/10/2023.
//

import Foundation

/// A class used to provide a global configuration for this library.
public final class NTKQueryGlobalConfig {
    /// The shared singleton instance to access the config class.
    public static let shared = NTKQueryGlobalConfig()
    
    private var isInitialized = false
    internal var queriesConfig: QueriesConfigDictionary = [:]
    internal var globalOnErrorQuery: GlobalOnErrorFunction?
    internal var mutationsConfig: MutationsConfigDictionary = [:]
    internal var globalOnErrorMutation: GlobalOnErrorFunction?
    
    private init() {}
    
    /// Initialize configuration used throughout the project for queries and mutations.
    ///
    /// Using this function you may configure settings for queries and mutations.
    ///
    /// In terms of queries, there is a possibility to provide settings through the  `queriesConfig`  parameter which is a dictionary of ``QueryConfig`` instances identified by keys. Thanks to that you can specify a `queryFunction` to use for the particular cache entry, default `stateTime`, and/or other configuration settings. Remember that local configuration will always be used in front of the global one, so if you wish to use a global one make sure you won't pass a local configuration for the specific query.
    ///
    /// Similar to queries, mutations can have their own global configuration as well. It is provided via the `mutationsConfig` parameter which is a dictionary of ``MutationConfig`` instances identified by keys. Thanks to that you can speficy a default `mutationFunction`, default handlers for successful and unsuccessful result through `onSuccess` and `onError` properties respectively. Remember that local configuration will always be used in front of the global one, so if you wish to use a global one make sure you won't pass a local configuration for the specific mutation.
    ///
    /// Apart from the configuration you can also specify the global onError handler that will be invoked each time some query or mutation will result in failure. There are separate handlers for queries (set by the `globalOnErrorQuery` parameter) and mutations (set by the `globalOnErrorMutation` parameter)
    ///
    /// **Configuration has a static character: it can be provided only once and there is no possibility to modify it during usage.**
    ///
    /// - Parameters:
    ///     - queriesConfig: [Optional] Configuration for queries.
    ///     - globalOnErrorQuery: [Optional] `onError` handler for all queries.
    ///     - mutationsConfig: [Optional] Configuration for mutations.
    ///     - globalOnErrorMutation: [Optional] Global `onError` handler for all mutations.
    public func initializeWithConfiguration(
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
