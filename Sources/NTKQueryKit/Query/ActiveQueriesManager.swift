//
//  ActiveQueriesManager.swift
//
//
//  Created by Wiktor Szlegier on 29/10/2023.
//

import Foundation

final actor ActiveQueriesManager {
    private init() {}
    
    public static let shared = ActiveQueriesManager()
    
    private var activeQueries: Set<String> = []
    
    func tryToAddActiveQuery(_ key: String) -> Bool {
        let (inserted, _) = activeQueries.insert(key)
        return inserted
    }
    
    func removeActiveQuery(_ key: String) {
        activeQueries.remove(key)
    }
}
