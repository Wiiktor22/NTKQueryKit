//
//  Mutation.swift
//
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation
import SwiftUI

@propertyWrapper
public struct NTKMutation<TData: Codable>: DynamicProperty {
    @StateObject var mutation: Mutation<TData>
    
    public init(
        mutationKey: String,
        mutationFunction: MutationFunction<TData>? = nil,
        onSuccess: MutationSuccessHandler? = nil,
        onError: MutationErrorHandler? = nil, meta: MetaDictionary? = nil
    ) {
        let config = MutationConfig(mutationFunction: mutationFunction, onSuccess: onSuccess, onError: onError, meta: meta)
        _mutation = StateObject(wrappedValue: Mutation<TData>(mutationKey: mutationKey, config: config))
    }
    
    public var wrappedValue: Mutation<TData> { mutation }
}

@MainActor
public final class Mutation<TData: Codable>: ObservableObject {
    private let mutationKey: String
    private var config: MutationConfig
    
    @Published public var lastStatus: MutationStatus = .ReadyToUse
    @Published public var data: TData? = nil
    @Published public var error: Error? = nil
    
    public var isPending: Bool { lastStatus == .Pending }
    public var isSuccess: Bool { lastStatus == .Success }
    public var isError: Bool { lastStatus == .Error }
    
    public init(mutationKey: String, config: MutationConfig) {
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
    
    public func mutate() async throws -> TData? {
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
