//
//  QueryConfig.swift
//
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation

struct QueryConfig {
    let queryFunction: DefaultQueryFunction?
    let staleTime: Int?
    let meta: MetaDictionary?
    
    init(
        queryFunction: DefaultQueryFunction? = nil,
        staleTime: Int? = nil,
        meta: MetaDictionary? = nil
    ) {
        self.queryFunction = queryFunction
        self.staleTime = staleTime
        self.meta = meta
    }
}
