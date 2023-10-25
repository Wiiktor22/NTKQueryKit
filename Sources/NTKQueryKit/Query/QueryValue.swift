//
//  QueryValue.swift
//  
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation
import SwiftUI
import Combine

@propertyWrapper
public struct NTKQueryValue<TData: Codable>: DynamicProperty {
    @StateObject private var queryValueInstance: QueryValue<TData>
    
    public init(queryKey: String) {
        _queryValueInstance = StateObject(wrappedValue: QueryValue<TData>(queryKey: queryKey))
    }
    
    public var wrappedValue: TData? { queryValueInstance.data }
}

@MainActor
public class QueryValue<TData: Codable>: ObservableObject {
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
