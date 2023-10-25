//
//  QueryInternalManager.swift
//
//
//  Created by Wiktor Szlegier on 18/10/2023.
//

import Foundation
import Combine

public struct QueryPublisherMessage {
    let data: Codable?
    let status: QueryStatus
}

final class QueryInternalPublishersManager {
    typealias QueryPublisher = PassthroughSubject<QueryPublisherMessage, Never>
    
    static let shared = QueryInternalPublishersManager()
    
    private init() {}
    
    private var publishers = [String: QueryPublisher]()
    
    func getPublisher(forKey key: String) -> QueryPublisher {
        if let publisher = publishers[key] {
            return publisher
        } else {
            let newPublisher = QueryPublisher()
            publishers.updateValue(newPublisher, forKey: key)
            return newPublisher
        }
    }
    
    func sendThroughPublisher(forKey key: String, message: QueryPublisherMessage) {
        if let publisher = publishers[key] {
            publisher.send(message)
        }
    }
}
