//
//  QueryValue.swift
//  
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation
import SwiftUI
import Combine

/// Property wrapper that represent an interface to access cache entry's data and subscribe to its changes.
@propertyWrapper
public struct NTKQueryValue<TData: Codable>: DynamicProperty {
    @StateObject private var queryValueInstance: QueryValue<TData>
    
    /// Creates a subscriber instance using the provided key.
    ///
    /// - Parameters:
    ///     - queryKey: Query identifier (known as key) used to specify concrete cache entry to follow.
    public init(queryKey: String) {
        _queryValueInstance = StateObject(wrappedValue: QueryValue<TData>(queryKey: queryKey))
    }
    
    /// The underlying data that belongs to specified cache entry.
    public var wrappedValue: TData? { queryValueInstance.data }
}

/// Represents a subscription interface to get and track data stored in the cache entry.
@MainActor
public class QueryValue<TData: Codable>: ObservableObject {
    /// Data that belongs to specified cache entry.
    @Published public var data: TData? = nil
    private var cancellables: Set<AnyCancellable> = []
    
    init(queryKey: String) {
        initializeSubscription(queryKey)
        initializeData(queryKey)
    }
    
    private func initializeSubscription(_ queryKey: String) {
        QueryInternalPublishersManager.shared.getPublisher(forKey: queryKey)
            .sink { [weak self] message in
                if let data = message.data {
                    self?.data = data as? TData
                }
            }
            .store(in: &cancellables)
    }
    
    private func initializeData(_ queryKey: String) {
        Task { [weak self] in
            if let cacheEntryValue = QueryCache.shared.readCacheEntry(key: queryKey) {
                self?.data = cacheEntryValue.data as? TData
            }
        }
    }
}
