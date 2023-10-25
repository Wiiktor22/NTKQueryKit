//
//  QueryClient.swift
//  
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation

public final class QueryClient {
    private init() {}
    
    /// The shared singleton client to use throughout your project.
    public static let shared = QueryClient()
    
    /// Read the saved data from the cache entry with the given key.
    ///
    /// In case there is no cache entry for the given key it will result in nil.
    ///
    /// - Parameter queryKey: The cache entry's key to read.
    ///
    /// - Returns: Data saved in the cache entry (identified by the given key).
    public func getQueryData<T: Codable>(queryKey: String) -> T? {
        QueryCache.shared.readCacheEntry(key: queryKey)?.data as? T
    }
    
    /// Read the query state object for the given key.
    ///
    /// In case there is no cache entry for the given key it will result in nil.
    ///
    /// - Parameter queryKey: The cache entry's key to read.
    ///
    /// - Returns: Potentially the cache entry object: ``QueryCacheEntry`` (if such entry for the given key exists)
    public func getQueryState(queryKey: String) -> QueryCacheEntry? {
        QueryCache.shared.readCacheEntry(key: queryKey)
    }
    
    /// Set manually the data for the specific cache entry.
    ///
    /// This function will set a passed in data for the cache entry identified by the given key, and it will notify already existing listeners about the changes.
    ///
    /// - Parameters:
    ///     - queryKey: The cache entry's key to update.
    ///     - data: The data to store in the cache entry.
    public func setQueryData(queryKey: String, data: Codable) {
        QueryCache.shared.overrideCacheEntry(key: queryKey, value: data)
        QueryInternalPublishersManager.shared.sendThroughPublisher(forKey: queryKey, message: QueryPublisherMessage(data: data, status: .Success))
    }
    
    private func fetchQuery(queryKey: String, queryFunction: DefaultQueryFunction) async {
        if let data: Codable = try? await queryFunction() {
            QueryCache.shared.overrideCacheEntry(key: queryKey, value: data)
            QueryInternalPublishersManager.shared.sendThroughPublisher(forKey: queryKey, message: QueryPublisherMessage(data: data, status: .Success))
        }
    }
    
    /// Prefetches a query with the given key. Optionally, it accepts a query function that might be used to fetch data and store it in the cache, otherwise it looks for a globally set function (via config).
    ///
    /// - Parameters:
    ///     - queryKey: The cache entry's key to prefetch.
    ///     - queryFunction: [Optional] The query function to use in order to prefetch data to the specific cache entry.
    public func prefetchQuery(queryKey: String, queryFunction: DefaultQueryFunction?) async {
        if let queryFunction = queryFunction {
            await fetchQuery(queryKey: queryKey, queryFunction: queryFunction)
        } else if let globalQueryFunction = NTKQueryGlobalConfig.shared.queriesConfig[queryKey]?.queryFunction {
            await fetchQuery(queryKey: queryKey, queryFunction: globalQueryFunction)
        }
    }
    
    /// Removes a query state object with the given key from the cache.
    ///
    /// - Parameter queryKey: The cache entry's key to remove.
    public func removeQuery(queryKey: String) {
        QueryCache.shared.removeCacheEntry(key: queryKey)
    }
}
