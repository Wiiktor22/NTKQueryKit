//
//  QueryConstants.swift
//  QueryKitPrototype
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation

// MARK: Query

enum QueryStatus {
    case Loading
    case Success
    case Error
}

typealias DefaultQueryFunction = () async throws -> Codable

// MARK: Mutation

enum MutationStatus {
    case ReadyToUse
    case Pending
    case Success
    case Error
}

typealias DefaultMutationFunction = () async throws -> Codable?
typealias MutationFunction<TData: Codable> = () async throws -> TData?

typealias MutationSuccessHandler = (_ data: Codable) -> Void
typealias MutationErrorHandler = (_ error: GlobalErrorParameters) -> Void

// MARK: Shared

typealias MetaDictionary = [String: Codable]

