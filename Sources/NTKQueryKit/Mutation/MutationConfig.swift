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
public struct MutationConfig {
    /// Function that performs asynchronous or synchronous task, that can return something based on its result.
    ///
    /// Optional since it can be passed whether via local or global configuration.
    public let mutationFunction: DefaultMutationFunction?
    
    /// Handler that will be fired when the mutation is successful.
    public let onSuccess: MutationSuccessHandler?
    
    /// Handler that will be fired if the mutation encounters an error.
    public let onError: MutationErrorHandler?
    
    /// Stores additional information about the mutation that can be used with error handler. By default it contains information about the `mutationKey`.
    public let meta: MetaDictionary?
    
    public init(
        mutationFunction: DefaultMutationFunction? = nil,
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
