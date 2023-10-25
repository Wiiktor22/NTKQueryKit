//
//  MutationConfig.swift
//  
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation

public struct MutationConfig {
    public let mutationFunction: DefaultMutationFunction?
    public let onSuccess: MutationSuccessHandler?
    public let onError: MutationErrorHandler?
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
