//
//  QueryValue.swift
//  
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation
import SwiftUI
import Combine

/// Property wrapper that represents an interface to access cache entry's data and subscribe to its changes.
@propertyWrapper
public struct NTKQueryValue<TData: Codable>: DynamicProperty {
    @StateObject private var queryValueInstance: QueryValue<TData, TData>
    
    /// Creates a subscriber instance using the provided key.
    ///
    /// - Parameters:
    ///     - queryKey: Query identifier (known as key) used to specify concrete cache entry to follow.
    public init(queryKey: String) {
        _queryValueInstance = StateObject(wrappedValue: QueryValue<TData, TData>(queryKey: queryKey))
    }
    
    /// The underlying data that belongs to specified cache entry.
    public var wrappedValue: TData? { queryValueInstance.data }
}

/// Property wrapper that represents an interface to access a selected portion of cache entry's data and subscribe to its changes.
@propertyWrapper
public struct NTKQueryValueSelect<TFetchedData: Codable, TSelectedData: Codable>: DynamicProperty {
    @StateObject private var queryValueInstance: QueryValue<TFetchedData, TSelectedData>
    
    /// Creates a subscriber instance using the provided key.
    ///
    /// - Parameters:
    ///     - queryKey: Query identifier (known as key) used to specify concrete cache entry to follow.
    ///     - select: Function used to transform or select a part of fetched data (by queryFunction). It affects stored data in th `data` property, however it does not impact data stored in cache.
    public init(queryKey: String, select: @escaping QuerySelector<TFetchedData, TSelectedData>) {
        _queryValueInstance = StateObject(wrappedValue: QueryValue<TFetchedData, TSelectedData>(queryKey: queryKey, select: select))
    }
    
    /// The underlying data that belongs to specified cache entry.
    public var wrappedValue: TSelectedData? { queryValueInstance.data }
}

/// Represents a subscription interface to get and track data stored in the cache entry.
@MainActor
public class QueryValue<TFetchedData: Codable, TSelectedData: Codable>: ObservableObject {
    /// Data that belongs to specified cache entry. (It can be a full data, or a selected portion of it).
    @Published public var data: TSelectedData? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    private let select: QuerySelector<TFetchedData, TSelectedData>?
    
    init(queryKey: String, select: QuerySelector<TFetchedData, TSelectedData>? = nil) {
        self.select = select
        
        initializeSubscription(queryKey)
        initializeData(queryKey)
    }
    
    private func initializeSubscription(_ queryKey: String) {
        QueryInternalPublishersManager.shared.getPublisher(forKey: queryKey)
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                guard let newData = message.data as? TFetchedData else { return }
                
                guard let select = self?.select else {
                    self?.data = newData as? TSelectedData
                    return
                }
                
                if let equatableCurrentData = self?.data as? any Equatable, let equatableNewData = select(newData) as? any Equatable {
                    if !equatableCurrentData.isEqualTo(equatableNewData) {
                        self?.data = equatableNewData as? TSelectedData
                    }
                } else {
                    self?.data = select(newData)
                }
            }
            .store(in: &cancellables)
    }
    
    private func initializeData(_ queryKey: String) {
        Task { [weak self] in
            guard let cacheEntryData = QueryCache.shared.readCacheEntry(key: queryKey)?.data as? TFetchedData else { return }
            
            if let select = self?.select {
                self?.data = select(cacheEntryData)
            } else {
                self?.data = cacheEntryData as? TSelectedData
            }
        }
    }
}
