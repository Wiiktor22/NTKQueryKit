//
//  Query.swift
//  
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation
import SwiftUI
import Combine

/// Property wrapper that represents an interface to perform an operation which fetches and retrieves data from a specified data source.
@propertyWrapper
public struct NTKQuery<TFetchedData: Codable>: DynamicProperty {
    @StateObject private var query: Query<TFetchedData, TFetchedData>
    
    /// Creates a query instance using the provided parameters as local configuration.
    ///
    /// - Parameters:
    ///     - queryKey: Query identifier (known as key) used for connecting to cache entry, accessing global settings and debugging.
    ///     - queryFunction: Function that performs a request to retrieve data. *(Optional since it can be passed whether via local or global configuration).*
    ///     - staleTime: The time in milliseconds after data is considered stale. *(Can be set locally per property wrapper or globally via config).*
    ///     - disableInitialFetch: Option to disable automatical fetch, that is performed when query is initialized. Defaults to false.
    ///     - meta: Stores additional information about the query that can be used with error handler.
    public init(
        queryKey: String,
        queryFunction: QueryFunction<TFetchedData>? = nil,
        staleTime: Int? = nil,
        disableInitialFetch: Bool? = nil,
        meta: MetaDictionary? = nil
    ) {
        let config = QueryConfig(
            queryFunction: queryFunction,
            staleTime: staleTime,
            disableInitialFetch: disableInitialFetch,
            meta: meta
        )
        _query = StateObject(wrappedValue: Query<TFetchedData, TFetchedData>(
            queryKey: queryKey,
            config: config
        ))
    }
    
    /// The underlying query instance created by the wrapper.
    public var wrappedValue: Query<TFetchedData, TFetchedData> { query }
}

/// Property wrapper that represents an interface to perform an operation which fetches data from a specified data source and retrieves only a selected portion of it.
@propertyWrapper
public struct NTKQuerySelect<TFetchedData: Codable, TSelectedData: Codable>: DynamicProperty {
    @StateObject private var query: Query<TFetchedData, TSelectedData>
    
    /// Creates a query instance using the provided parameters as local configuration.
    ///
    /// - Parameters:
    ///     - queryKey: Query identifier (known as key) used for connecting to cache entry, accessing global settings and debugging.
    ///     - queryFunction: Function that performs a request to retrieve data. *(Optional since it can be passed whether via local or global configuration).*
    ///     - staleTime: The time in milliseconds after data is considered stale. *(Can be set locally per property wrapper or globally via config).*
    ///     - select: Function used to transform or select a part of fetched data (by queryFunction). It affects stored data in th `data` property, however it does not impact data stored in cache.
    ///     - disableInitialFetch: Option to disable automatical fetch, that is performed when query is initialized. Defaults to false.
    ///     - meta: Stores additional information about the query that can be used with error handler.
    public init(
        queryKey: String,
        queryFunction: QueryFunction<TFetchedData>? = nil,
        staleTime: Int? = nil,
        select: @escaping QuerySelector<TFetchedData, TSelectedData>,
        disableInitialFetch: Bool? = nil,
        meta: MetaDictionary? = nil
    ) {
        let config = QueryConfig(
            queryFunction: queryFunction,
            staleTime: staleTime,
            disableInitialFetch: disableInitialFetch,
            meta: meta
        )
        _query = StateObject(wrappedValue: Query<TFetchedData, TSelectedData>(
            queryKey: queryKey,
            config: config,
            select: select
        ))
    }
    
    /// The underlying query instance created by the wrapper.
    public var wrappedValue: Query<TFetchedData, TSelectedData> { query }
}

/// Represents an operation that fetches and retrieves data from a specified data source, such as API or database.
@MainActor
public class Query<TFetchedData: Codable, TSelectedData: Codable>: ObservableObject {
    // MARK: Query - Properties
    
    private typealias QueryPublisherMessageContent = (data: TFetchedData?, status: QueryStatus)
    private var cancellables: Set<AnyCancellable> = []
    
    private let queryKey: String
    private let config: QueryConfig
    private let select: QuerySelector<TFetchedData, TSelectedData>?
    
    /// Indicates whether a query was fetched at least once, not considering the result.
    @Published public var isFetched = false
    
    /// Status that represent last known result of the particular query.
    @Published public var lastStatus: QueryStatus = .Loading
    
    /// Data which is being selected from the cache entry identified by provided key. (It can be a full data, or a selected portion of it).
    @Published public var data: TSelectedData? = nil
    
    /// Error that was encountered during the query usage.
    @Published public var error: Error? = nil
    
    /// Indactes if the current status of mutation is `.Loading`.
    public var isLoading: Bool { lastStatus == .Loading }
    
    /// Indactes if the current status of mutation is `.Success`.
    public var isSuccess: Bool { lastStatus == .Success }
    
    /// Indactes if the current status of mutation is `.Error`.
    public var isError: Bool { lastStatus == .Error }
    
    private var queryFunction: DefaultQueryFunction? {
        if let localQueryFunction = self.config.queryFunction {
            return localQueryFunction
        } else {
            return NTKQueryGlobalConfig.shared.queriesConfig[queryKey]?.queryFunction as? DefaultQueryFunction
        }
    }
    
    private var staleTime: Int {
        if let localStaleTime = self.config.staleTime {
            return localStaleTime
        } else {
            return NTKQueryGlobalConfig.shared.queriesConfig[queryKey]?.staleTime ?? 0
        }
    }
    
    private var meta: MetaDictionary? {
        if let localMeta = self.config.meta {
            return localMeta
        } else {
            return NTKQueryGlobalConfig.shared.queriesConfig[queryKey]?.meta
        }
    }
    
    private func buildMetaDictonary() -> MetaDictionary {
        let defaultMeta: MetaDictionary = ["queryKey": queryKey]
        
        if let providedMeta = self.meta {
            return defaultMeta.merging(providedMeta) { (current, _) in current }
        } else {
            return defaultMeta
        }
    }
    
    // MARK: Query - Initialization
    
    init(queryKey: String, config: QueryConfig, select: QuerySelector<TFetchedData, TSelectedData>? = nil) {
        self.queryKey = queryKey
        self.config = config
        self.select = select
        
        initializeSubscription(queryKey)
        if (!config.disableInitialFetch) {
            Task {
                await self.fetch()
            }
        }
    }
    
    private func initializeSubscription(_ queryKey: String) {
        QueryInternalPublishersManager.shared.getPublisher(forKey: queryKey)
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                guard let newData = message.data as? TFetchedData else { return }
                
                guard let select = self?.select else {
                    self?.lastStatus = message.status
                    self?.data = newData as? TSelectedData
                    return
                }
                
                if let equatableCurrentData = self?.data as? any Equatable, let equatableNewData = select(newData) as? any Equatable {
                    if !equatableCurrentData.isEqualTo(equatableNewData) {
                        self?.lastStatus = message.status
                        self?.data = equatableNewData as? TSelectedData
                    }
                } else {
                    self?.lastStatus = message.status
                    self?.data = select(newData)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: Query - Fetching and cache interactions related methods
    
    private func saveNewDataInCache(_ queryKey: String, _ data: TFetchedData) {
        QueryCache.shared.overrideCacheEntry(key: queryKey, value: data)
    }
    
    private func distributeUpdatedDataAndStatus(_ queryKey: String, _ messageContent: QueryPublisherMessageContent) {
        let (data, status) = messageContent
        let message = QueryPublisherMessage(data: data, status: status)
        QueryInternalPublishersManager.shared.sendThroughPublisher(forKey: queryKey, message: message)
    }
    
    private func markQueryAsFetched() {
        if !self.isFetched {
            self.isFetched = true
        }
    }
    
    private func fetchData(_ queryKey: String, _ queryFunction: @escaping DefaultQueryFunction) async -> QueryPublisherMessageContent {
        do {
            // NOTE: Risky line below, not sure if TData assertion will be correct each time
            let fetchedData = try await queryFunction() as? TFetchedData
            let status: QueryStatus = .Success
            
            markQueryAsFetched()
            if (self.error != nil) { self.error = nil }
            
            return (fetchedData, status)
        } catch let error {
            self.error = error
            
            let status: QueryStatus = .Error
            markQueryAsFetched()
            
            if let globalOnError = NTKQueryGlobalConfig.shared.globalOnErrorQuery {
                globalOnError(GlobalErrorParameters(error: error, meta: buildMetaDictonary()))
            }
            
            return (nil, status)
        }
    }
    
    private func fetchDistrubuteAndSaveData(_ queryKey: String, _ queryFunction: @escaping DefaultQueryFunction, _ staleTime: Int) {
        Task {
            let queryPublisherMessageContent = await fetchData(queryKey, queryFunction)
            
            distributeUpdatedDataAndStatus(queryKey, queryPublisherMessageContent)
            
            if (staleTime > 0) {
                if let data = queryPublisherMessageContent.data {
                    saveNewDataInCache(queryKey, data)
                }
            }
        }
    }
    
    private func fetch() async {
        /**
            Scenarios:
                - empty cache:
                    - staleTime set to 0 - It indicates a no cache mode meaning just fetch and distrubute every time
                    - staleTime bigger than 0 - fetch, distrubute and save data in the dedicated cache entry
                - saved cache:
                    - not stale data - just assigned data collected from cache
                    - stale data: fetch, distrubute and save data in the dedicated cache entry
            Conclusion: Only in case when data is already saved in the cache and not stale there is no need to go through a whole procedure
         */
        
        guard let queryFunction = self.queryFunction else { return }
        
        if let cacheEntry = QueryCache.shared.readCacheEntry(key: queryKey) {
            let now = Date()
            if (now < cacheEntry.lastUpdateTime + Double(staleTime / 1000)) {
                Task {
                    if let select = self.select {
                        self.data = select(cacheEntry.data as! TFetchedData)
                    } else {
                        self.data = cacheEntry.data as? TSelectedData
                    }
                    self.lastStatus = .Success
                    markQueryAsFetched()
                }
                return
            }
        }
        
        let isUniqueRequest = await ActiveQueriesManager.shared.tryToAddActiveQuery(queryKey)
        
        if (isUniqueRequest) {
            fetchDistrubuteAndSaveData(queryKey, queryFunction, staleTime)
            await ActiveQueriesManager.shared.removeActiveQuery(queryKey)
        }
    }
    
    /// Allows to manually refetch provided `queryFunction`.
    ///
    /// Once the query fetches new data, it's provided to all other listeners and potentially can be stored in the cache.
    public func refetch() {
        guard let queryFunction = self.queryFunction else { return }
        self.lastStatus = .Loading
        
        fetchDistrubuteAndSaveData(queryKey, queryFunction, staleTime)
    }
    
//    deinit {
//        print("Deinit")
//    }
    
}
