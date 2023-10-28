//
//  Mutation.swift
//
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation
import SwiftUI

@propertyWrapper
public struct NTKMutation<TParameter, TData: Codable>: DynamicProperty {
    @StateObject var mutation: Mutation<TParameter, TData>
    
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
        mutationFunction: MutationFunction<TParameter, TData>? = nil,
        onSuccess: MutationSuccessHandler? = nil,
        onError: MutationErrorHandler? = nil,
        meta: MetaDictionary? = nil
    ) {
        let config = MutationConfig<TParameter>(mutationFunction: mutationFunction, onSuccess: onSuccess, onError: onError, meta: meta)
        _mutation = StateObject(wrappedValue: Mutation<TParameter, TData>(mutationKey: mutationKey, config: config))
    }
    
    /// The underlying mutation instance created by the wrapper.
    public var wrappedValue: Mutation<TParameter, TData> { mutation }
}

/// Represents an operation that will modify server-side data and then potentially updates the client's cache based on the result.
@MainActor
public final class Mutation<TParameter, TData: Codable>: ObservableObject {
    private let mutationKey: String
    private var config: MutationConfig<TParameter>
    
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
    
    init(mutationKey: String, config: MutationConfig<TParameter>) {
        self.mutationKey = mutationKey
        self.config = config
    }
    
    private var mutationFunction: DefaultMutationFunction<TParameter>? {
        if let localMutationFunction = self.config.mutationFunction {
            return localMutationFunction
        } else {
            let config = NTKQueryGlobalConfig.shared.mutationsConfig[self.mutationKey] as? MutationConfig<TParameter>
            return config?.mutationFunction
        }
    }
    
    private var onSuccess: MutationSuccessHandler? {
        if let localOnSuccess = self.config.onSuccess {
            return localOnSuccess
        } else {
            let config = NTKQueryGlobalConfig.shared.mutationsConfig[self.mutationKey] as? MutationConfig<TParameter>
            return config?.onSuccess
        }
    }
    
    private var onError: MutationErrorHandler? {
        if let localOnError = self.config.onError {
            return localOnError
        } else if let localOnErrorFromConfig = (NTKQueryGlobalConfig.shared.mutationsConfig[self.mutationKey] as? MutationConfig<TParameter>)?.onError {
            return localOnErrorFromConfig
        } else {
            return NTKQueryGlobalConfig.shared.globalOnErrorMutation
        }
    }
    
    private var meta: MetaDictionary? {
        if let localMeta = self.config.meta {
            return localMeta
        } else {
            let config = NTKQueryGlobalConfig.shared.mutationsConfig[self.mutationKey] as? MutationConfig<TParameter>
            return config?.meta
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
    public func mutate(_ parameter: TParameter = ()) async throws -> TData? {
        guard let mutationFunction = self.mutationFunction else { return nil }
        self.lastStatus = .Pending
        
        do {
            // NOTE: Risky line below, not sure if TData assertion will be correct each time
            let data = try await mutationFunction(parameter) as? TData
            
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
