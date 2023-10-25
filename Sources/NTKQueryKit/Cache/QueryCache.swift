//
//  QueryCache.swift
//
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation

protocol QueryCacheEntry {
    var lastUpdateTime: Date { get set }
    var data: Codable { get set }
}

// NOTE: It needs to be a class (not struct) since it is a NSCache requirement
private class _QueryCacheEntry: QueryCacheEntry {
    var lastUpdateTime: Date
    var data: Codable
    
    init(_ data: Codable) {
        self.lastUpdateTime = Date()
        self.data = data
    }
}

internal final class QueryCache {
    static let shared = QueryCache()
    
    private init() {}
    
    private let cacheContainer = NSCache<NSString, _QueryCacheEntry>()
    
    func overrideCacheEntry(key: String, value: Codable) {
        cacheContainer.setObject(_QueryCacheEntry(value), forKey: key as NSString)
    }
    
    func readCacheEntry(key: String) -> QueryCacheEntry? {
        return cacheContainer.object(forKey: key as NSString)
    }
    
    func removeCacheEntry(key: String) {
        cacheContainer.removeObject(forKey: key as NSString)
    }
}
