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
    
    /// Creates a mutation instance using the provided parameters as local configuration.
    ///
    /// - Parameters:
    ///     - mutationKey: Mutation identifier used for accessing global settings or debugging.
    ///     - mutationFunction: Function that performs asynchronous or synchronous task, that can return something based on its result. *(Optional since it can be passed whether via local or global configuration).*
    ///     - onSuccess: Handler that will be fired when the mutation is successful.
    ///     - onError: Handler that will be fired if the mutation encounters an error.
    ///     - meta: Stores additional information about the mutation that can be used with error handler.
    public init(
        mutationKey: String,
        mutationFunction: MutationFunction<TData>? = nil,
        onSuccess: MutationSuccessHandler? = nil,
        onError: MutationErrorHandler? = nil, 
        meta: MetaDictionary? = nil
    ) {
        let config = MutationConfig(mutationFunction: mutationFunction, onSuccess: onSuccess, onError: onError, meta: meta)
        _mutation = StateObject(wrappedValue: Mutation<TData>(mutationKey: mutationKey, config: config))
    }
    
    /// The underlying mutation instance created by the wrapper.
    public var wrappedValue: Mutation<TData> { mutation }
}

/// Represents an operation that will modify server-side data and then potentially updates the client's cache based on the result.
@MainActor
public final class Mutation<TData: Codable>: ObservableObject {
    private let mutationKey: String
    private var config: MutationConfig
    
    /// Status that represent last known result of the particular mutation.
    @Published public var lastStatus: MutationStatus = .ReadyToUse
    
    /// Data returned from the provided `mutationFunction`.
    @Published public var data: TData? = nil
    
    /// Error that was encountered during the mutation usage.
    @Published public var error: Error? = nil
    
    /// Indactes if the current status of mutation is `.Pending`.
    public var isPending: Bool { lastStatus == .Pending }
    
    /// Indactes if the current status of mutation is `.Success`.
    public var isSuccess: Bool { lastStatus == .Success }
    
    /// Indactes if the current status of mutation is `.Error`.
    public var isError: Bool { lastStatus == .Error }
    
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
    
    /// Mutation function that can be called.
    ///
    /// If `mutationFunction` can't be found mutation won't be called.
    ///
    /// Returns: [Optionally] The data from the provided `mutationFunction`
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
