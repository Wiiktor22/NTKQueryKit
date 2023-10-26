//
//  QueryConfig.swift
//
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation

/// Describes the structure of available configuration options for the query.
///
/// It can be used as a local and global configuration.
public struct QueryConfig {
    /// Function used by the query to request data. 
    ///
    /// Optional since it can be passed whether via local or global configuration.
    public let queryFunction: DefaultQueryFunction?
    
    /// The time in milliseconds after data is considered stale. Defaults to 0.
    public let staleTime: Int?
    
    /// Stores additional information about the query that can be used with error handler. By default it contains information about the `queryKey`.
    public let meta: MetaDictionary?
    
    public init(
        queryFunction: DefaultQueryFunction? = nil,
        staleTime: Int? = nil,
        meta: MetaDictionary? = nil
    ) {
        self.queryFunction = queryFunction
        self.staleTime = staleTime
        self.meta = meta
    }
}
