//
//  Query.swift
//  
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation
import SwiftUI
import Combine

@propertyWrapper
public struct NTKQuery<TFetchedData: Codable, TSelectedData: Codable>: DynamicProperty {
    @StateObject private var query: Query<TFetchedData, TSelectedData>
    
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
        select: QuerySelector<TFetchedData, TSelectedData>? = nil,
        disableInitialFetch: Bool? = nil,
        meta: MetaDictionary? = nil
    ) {
        let config = QueryConfig(
            queryFunction: queryFunction,
            staleTime: staleTime,
            disableInitialFetch: disableInitialFetch,
            meta: meta
        )
        _query = StateObject(wrappedValue: Query<TFetchedData, TSelectedData>(queryKey: queryKey, select: select ?? { (_ data: TFetchedData) in data as! TSelectedData } , config: config))
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
    
    private let select: QuerySelector<TFetchedData, TSelectedData>
    
    /// Indicates whether a query was fetched at least once, not considering the result.
    @Published public var isFetched = false
    
    /// Status that represent last known result of the particular query.
    @Published public var lastStatus: QueryStatus = .Loading
    
    /// Data stored in the cache entry identified by provided key.
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
    
    init(queryKey: String, select: @escaping QuerySelector<TFetchedData, TSelectedData>, config: QueryConfig) {
        self.queryKey = queryKey
        self.select = select
        self.config = config
        
        initializeSubscription(queryKey)
        if (!config.disableInitialFetch) {
            Task {
                await self.fetch()
            }
        }
    }
    
    private func initializeSubscription(_ queryKey: String) {
        QueryInternalPublishersManager.shared.getPublisher(forKey: queryKey)
            .sink { [weak self] message in
                self?.lastStatus = message.status
                if let data = message.data {
                    self?.data = self?.select(data as! TFetchedData)
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
    
    private func markQueryAsFetched(withStatus status: QueryStatus) {
        self.isFetched = true
        self.lastStatus = status
    }
    
    private func fetchAndAssignData(_ queryKey: String, _ queryFunction: @escaping DefaultQueryFunction) async -> QueryPublisherMessageContent {
        do {
            // NOTE: Risky line below, not sure if TData assertion will be correct each time
            let fetchedData = try await queryFunction() as! TFetchedData
            let data = self.select(fetchedData)
            
            self.data = data
            if (self.error != nil) { self.error = nil }
            
            let status: QueryStatus = .Success
            markQueryAsFetched(withStatus: status)
            
            return (fetchedData, status)
        } catch let error {
            self.error = error
            
            let status: QueryStatus = .Error
            markQueryAsFetched(withStatus: status)
            
            if let globalOnError = NTKQueryGlobalConfig.shared.globalOnErrorQuery {
                globalOnError(GlobalErrorParameters(error: error, meta: buildMetaDictonary()))
            }
            
            return (nil, status)
        }
    }
    
    private func fetchAssignDistrubuteAndSaveData(_ queryKey: String, _ queryFunction: @escaping DefaultQueryFunction, _ staleTime: Int) {
        Task {
            print("fetchAssignDistrubuteAndSaveData")
            let queryPublisherMessageContent = await fetchAndAssignData(queryKey, queryFunction)
            
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
                    self.data = self.select(cacheEntry.data as! TFetchedData)
                    markQueryAsFetched(withStatus: .Success)
                }
                return
            }
        }
        
        let isUniqueRequest = await ActiveQueriesManager.shared.tryToAddActiveQuery(queryKey)
        
        if (isUniqueRequest) {
            fetchAssignDistrubuteAndSaveData(queryKey, queryFunction, staleTime)
            await ActiveQueriesManager.shared.removeActiveQuery(queryKey)
        }
    }
    
    /// Allows to manually refetch provided `queryFunction`.
    ///
    /// Once the query fetches new data, it's provided to all other listeners and potentially can be stored in the cache.
    public func refetch() {
        guard let queryFunction = self.queryFunction else { return }
        self.lastStatus = .Loading
        
        fetchAssignDistrubuteAndSaveData(queryKey, queryFunction, staleTime)
    }
    
//    deinit {
//        print("Deinit")
//    }
    
}
