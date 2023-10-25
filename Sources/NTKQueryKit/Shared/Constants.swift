//
//  QueryConstants.swift
//  QueryKitPrototype
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation

// MARK: Query
public enum QueryStatus {
    case Loading
    case Success
    case Error
}

public typealias DefaultQueryFunction = () async throws -> Codable
public typealias QueryFunction<TData: Codable> = () async throws -> TData

public typealias QueriesConfigDictionary = [String: QueryConfig]

// MARK: Mutation
public enum MutationStatus {
    case ReadyToUse
    case Pending
    case Success
    case Error
}

public typealias DefaultMutationFunction = () async throws -> Codable?
public typealias MutationFunction<TData: Codable> = () async throws -> TData?

public typealias MutationSuccessHandler = (_ data: Codable) -> Void
public typealias MutationErrorHandler = (_ error: GlobalErrorParameters) -> Void

public typealias MutationsConfigDictionary = [String: MutationConfig]

// MARK: Shared
public typealias MetaDictionary = [String: Codable]

public typealias GlobalOnErrorFunction = (_ payload: GlobalErrorParameters) -> Void

