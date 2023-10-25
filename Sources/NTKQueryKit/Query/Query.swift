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
public struct NTKQuery<TData: Codable>: DynamicProperty {
    @StateObject private var query: Query<TData>
    
    public init(
        queryKey: String,
        queryFunction: DefaultQueryFunction? = nil,
        staleTime: Int? = nil,
        meta: MetaDictionary? = nil
    ) {
        let config = QueryConfig(queryFunction: queryFunction, staleTime: staleTime, meta: meta)
        _query = StateObject(wrappedValue: Query(queryKey: queryKey, config: config))
    }
    
    public var wrappedValue: Query<TData> { query }
}

@MainActor
public class Query<TData: Codable>: ObservableObject {
    // MARK: Query - Properties
    
    private typealias QueryPublisherMessageContent = (data: TData?, status: QueryStatus)
    private var cancellables: Set<AnyCancellable> = []
    
    private let queryKey: String
    private let config: QueryConfig
    
    @Published public var isFetched = false
    @Published public var lastStatus: QueryStatus = .Loading
    @Published public var data: TData? = nil
    @Published public var error: Error? = nil
    
    public var isLoading: Bool { lastStatus == .Loading }
    public var isSuccess: Bool { lastStatus == .Success }
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
    
    init(queryKey: String, config: QueryConfig) {
        self.queryKey = queryKey
        self.config = config
        
        initializeSubscription(queryKey)
        self.fetch()
    }
    
    private func initializeSubscription(_ queryKey: String) {
        QueryInternalPublishersManager.shared.getPublisher(forKey: queryKey)
            .sink { [weak self] message in
                self?.lastStatus = message.status
                if let data = message.data {
                    self?.data = data as? TData
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: Query - Fetching and cache interactions related methods
    
    private func saveNewDataInCache(_ queryKey: String, _ data: TData) {
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
            let data = try await queryFunction() as? TData
            
            self.data = data
            if (self.error != nil) { self.error = nil }
            
            let status: QueryStatus = .Success
            markQueryAsFetched(withStatus: status)
            
            return (data, status)
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
            let queryPublisherMessageContent = await fetchAndAssignData(queryKey, queryFunction)
            
            distributeUpdatedDataAndStatus(queryKey, queryPublisherMessageContent)
            
            if (staleTime > 0) {
                if let data = queryPublisherMessageContent.data {
                    saveNewDataInCache(queryKey, data)
                }
            }
        }
    }
    
    private func fetch() {
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
                    self.data = cacheEntry.data as? TData
                    markQueryAsFetched(withStatus: .Success)
                }
                return
            }
        }
        
        fetchAssignDistrubuteAndSaveData(queryKey, queryFunction, staleTime)
    }
    
    public func refetch() {
        guard let queryFunction = self.queryFunction else { return }
        self.lastStatus = .Loading
        
        fetchAssignDistrubuteAndSaveData(queryKey, queryFunction, staleTime)
        
        // NOTE: Only for testing!
//        let newData = ["Testing", "Query", "Wiktor"] as! TData
//        distributeUpdatedDataAndStatus(queryKey, (newData, .Success))
//        saveNewDataInCache(queryKey, newData)
    }
    
//    deinit {
//        print("Deinit")
//    }
    
}
