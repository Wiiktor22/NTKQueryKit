//
//  QueryConfig.swift
//
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation

public struct QueryConfig {
    public let queryFunction: DefaultQueryFunction?
    public let staleTime: Int?
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
