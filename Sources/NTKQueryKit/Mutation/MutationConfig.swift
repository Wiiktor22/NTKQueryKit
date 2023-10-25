//
//  MutationConfig.swift
//  
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation

struct MutationConfig {
    typealias MutationFunction = () async throws -> Codable?
    
    let mutationFunction: MutationFunction?
    let onSuccess: MutationSuccessHandler?
    let onError: MutationErrorHandler?
    let meta: MetaDictionary?
    
    init(
        mutationFunction: MutationFunction? = nil,
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
