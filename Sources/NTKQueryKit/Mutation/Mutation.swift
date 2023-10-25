//
//  Mutation.swift
//
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation
import SwiftUI

@propertyWrapper
struct NTKMutation<TData: Codable>: DynamicProperty {
    @StateObject var mutation: Mutation<TData>
    
    init(
        mutationKey: String,
        mutationFunction: MutationFunction<TData>? = nil,
        onSuccess: MutationSuccessHandler? = nil,
        onError: MutationErrorHandler? = nil, meta: MetaDictionary? = nil
    ) {
        let config = MutationConfig(mutationFunction: mutationFunction, onSuccess: onSuccess, onError: onError, meta: meta)
        _mutation = StateObject(wrappedValue: Mutation<TData>(mutationKey: mutationKey, config: config))
    }
    
    var wrappedValue: Mutation<TData> { mutation }
}

@MainActor
final class Mutation<TData: Codable>: ObservableObject {
    private let mutationKey: String
    private var config: MutationConfig
    
    @Published var lastStatus: MutationStatus = .ReadyToUse
    @Published var data: TData? = nil
    @Published var error: Error? = nil
    
    var isPending: Bool { lastStatus == .Pending }
    var isSuccess: Bool { lastStatus == .Success }
    var isError: Bool { lastStatus == .Error }
    
    init(mutationKey: String, config: MutationConfig) {
        self.mutationKey = mutationKey
        self.config = config
    }
    
    private var mutationFunction: DefaultMutationFunction? {
        if let localMutationFunction = self.config.mutationFunction {
            return localMutationFunction
        } else {
            return NTKQueryGlobalConfig.shared.mutationsConfig[self.mutationKey]?.mutationFunction
        }
    }
    
    private var onSuccess: MutationSuccessHandler? {
        if let localOnSuccess = self.config.onSuccess {
            return localOnSuccess
        } else {
            return NTKQueryGlobalConfig.shared.mutationsConfig[self.mutationKey]?.onSuccess
        }
    }
    
    private var onError: MutationErrorHandler? {
        if let localOnError = self.config.onError {
            return localOnError
        } else if let localOnErrorFromConfig = NTKQueryGlobalConfig.shared.mutationsConfig[self.mutationKey]?.onError {
            return localOnErrorFromConfig
        } else {
            return NTKQueryGlobalConfig.shared.globalOnErrorMutation
        }
    }
    
    private var meta: MetaDictionary? {
        if let localMeta = self.config.meta {
            return localMeta
        } else {
            return NTKQueryGlobalConfig.shared.mutationsConfig[mutationKey]?.meta
        }
    }
    
    private func buildMetaDictonary() -> MetaDictionary {
        let defaultMeta: MetaDictionary = ["mutationKey": mutationKey]
        
        if let providedMeta = self.meta {
            return defaultMeta.merging(providedMeta) { (current, _) in current }
        } else {
            return defaultMeta
        }
    }
    
    func mutate() async throws -> TData? {
        guard let mutationFunction = self.mutationFunction else { return nil }
        self.lastStatus = .Pending
        
        do {
            // NOTE: Risky line below, not sure if TData assertion will be correct each time
            let data = try await mutationFunction() as? TData
            
            self.lastStatus = .Success
            self.data = data
            if (self.error != nil) { self.error = nil }
            
            if let onSuccess = self.onSuccess {
                onSuccess(data)
            }
            
            return data
        } catch let error {
            self.lastStatus = .Error
            if (self.data != nil) { self.data = nil }
            self.error = error
            
            if let onError = self.onError {
                onError(GlobalErrorParameters(error: error, meta: buildMetaDictonary()))
            }
            
            return nil
        }
    }
}
