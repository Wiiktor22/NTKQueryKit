//
//  QueryClient.swift
//  
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation

public final class QueryClient {
    public static let shared = QueryClient()
    
    private init() {}
    
    public func getQueryData<T: Codable>(queryKey: String) -> T? {
        QueryCache.shared.readCacheEntry(key: queryKey)?.data as? T
    }
    
    public func getQueryState(queryKey: String) -> QueryCacheEntry? {
        QueryCache.shared.readCacheEntry(key: queryKey)
    }
    
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
    
    public func prefetchQuery(queryKey: String, queryFunction: DefaultQueryFunction?) async {
        if let queryFunction = queryFunction {
            await fetchQuery(queryKey: queryKey, queryFunction: queryFunction)
        } else if let globalQueryFunction = NTKQueryGlobalConfig.shared.queriesConfig[queryKey]?.queryFunction {
            await fetchQuery(queryKey: queryKey, queryFunction: globalQueryFunction)
        }
    }
    
    public func removeQuery(queryKey: String) {
        QueryCache.shared.removeCacheEntry(key: queryKey)
    }
}
