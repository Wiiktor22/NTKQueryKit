//
//  QueryConstants.swift
//  QueryKitPrototype
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation

// MARK: Query

/// Possible statutes that represent last known query state.
public enum QueryStatus {
    case Loading
    case Success
    case Error
}

/// A type representing fundamental constraints of a query function.
public typealias DefaultQueryFunction = () async throws -> Codable
/// A type representing query function with generic response type.
public typealias QueryFunction<TData: Codable> = () async throws -> TData

/// A type representing dictionary (used for applying global config) that contains `queryKey` and ``QueryConfig``.
public typealias QueriesConfigDictionary = [String: QueryConfig]

// MARK: Mutation

/// Possible statutes that represent last known mutation state.
public enum MutationStatus {
    /// Information that indicates that particular mutation was not used yet.
    case ReadyToUse
    /// Information that indicates that particular mutation is executing currently.
    case Pending
    /// Information that indicates that last execution of this mutation was successful.
    case Success
    /// Information that indicates that last execution of this mutation was unsuccessful.
    case Error
}

/// A type representing fundamental constraints of a mutation function.
public typealias DefaultMutationFunction = () async throws -> Codable
/// A type representing mutation function with generic response type.
public typealias MutationFunction<TData: Codable> = () async throws -> TData

public typealias DefaultMutationFunctionWithParam<TParam> = (_ param: TParam) async throws -> Codable

public typealias MutationFunctionWithParam<TParam, TData> = (_ param: TParam) async throws -> TData

/// A type representing `onSuccess` handler used within mutations.
public typealias MutationSuccessHandler = (_ data: Codable) -> Void
/// A type representing `onError` handler used within mutations.
public typealias MutationErrorHandler = (_ error: GlobalErrorParameters) -> Void

/// A type representing dictionary (used for applying global config) that contains `mutationKey` and ``MutationConfig``.
public typealias MutationsConfigDictionary = [String: MutationConfig<Any>]

// MARK: Shared

/// A type representing meta dictionary: a String as identifier and a codable parameter as information.
public typealias MetaDictionary = [String: Codable]

/// A type representing global `onError` handlers used for both queries and mutations.
public typealias GlobalOnErrorFunction = (_ payload: GlobalErrorParameters) -> Void

