//
//  GlobalErrorParameters.swift
//  QueryKitPrototype
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation

/// Describes the structure of error parameter
public struct GlobalErrorParameters {
    /// Stores the error.
    public let error: Error
    /// Provides the meta dictionary with additional info. 
    ///
    /// By default only `queryKey`/`mutationKey` will be passed (if it's specified).
    public let meta: MetaDictionary
}
