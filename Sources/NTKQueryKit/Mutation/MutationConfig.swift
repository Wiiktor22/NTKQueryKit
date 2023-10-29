//
//  MutationConfig.swift
//  
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation

/// Describes the structure of available configuration options for the mutation.
///
/// It can be used as a local and global configuration.
public struct MutationConfig<TParameter> {
    let mutationFunction: DefaultMutationFunction<TParameter>?
    let onSuccess: MutationSuccessHandler?
    let onError: MutationErrorHandler?
    let meta: MetaDictionary?
    
    /// Creates a configuration used to specify settings for mutation.
    ///
    /// - Parameters:
    ///     - mutationFunction: Function that performs asynchronous or synchronous task, that can return something based on its result. *(Optional since it can be passed whether via local or global configuration).*
    ///     - onSuccess: Handler that will be fired when the mutation is successful.
    ///     - onError: Handler that will be fired if the mutation encounters an error.
    ///     - meta: Stores additional information about the mutation that can be used with error handler. By default it contains information about the `mutationKey`.
    public init(
        mutationFunction: DefaultMutationFunction<TParameter>? = nil,
        onSuccess: MutationSuccessHandler? = nil,
        onError: MutationErrorHandler? = nil,
        meta: MetaDictionary? = nil
    ) {
        self.mutationFunction = mutationFunction
        self.onSuccess = onSuccess
        self.onError = onError
        self.meta = meta
    }
}
