//
//  QueryGlobalErrorTests.swift
//  QueryKitPrototypeTests
//
//  Created by Wiktor Szlegier on 24/10/2023.
//

import XCTest

@MainActor
final class QueryGlobalErrorTests: XCTestCase {
    
    let testingQueryKey = "TestingQuery"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        NTKQueryGlobalConfig.shared.deinitializeConfiguration()
    }

     func testGlobalErrorInvocation() throws {
        let exp = expectation(description: "Global onError function was called when there is an error thrown in queryFunction")
        func globalOnErrorQuery(payload: GlobalErrorParameters) {
            exp.fulfill()
        }
        
        NTKQueryGlobalConfig.shared.initializeWithConfiguration(queriesConfig: [:], globalOnErrorQuery: globalOnErrorQuery)
        
        func throwingQueryFunction() throws -> [String] {
            throw TestingErrors.Standard
        }
        _ = Query<[String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: throwingQueryFunction))
        
        waitForExpectations(timeout: 1)
    }
    
    func testGlobalErrorInvocationWithLocalMeta() throws {
        let exp = expectation(description: "Global onError function was called with local meta dictionary that contains two keys: queryKey & testingMessage")
        
        let testingMessage = "Testing Error Message"
        
        func globalOnErrorQuery(payload: GlobalErrorParameters) {
            if let queryKey = payload.meta["queryKey"] as? String, let message = payload.meta["testingMessage"] as? String {
                if (queryKey == testingQueryKey && message == testingMessage) {
                    exp.fulfill()
                }
            }
        }
        
        NTKQueryGlobalConfig.shared.initializeWithConfiguration(queriesConfig: [:], globalOnErrorQuery: globalOnErrorQuery)
        
        func throwingQueryFunction() throws -> [String] {
            throw TestingErrors.Standard
        }
        let meta = ["testingMessage": testingMessage]
        _ = Query<[String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: throwingQueryFunction, meta: meta))
        
        waitForExpectations(timeout: 1)
    }
    
    func testGlobalErrorInvocationWithGlobalMeta() throws {
        let exp = expectation(description: "Global onError function was called with global meta dictionary that contains two keys: queryKey & globalTestingMessage")
        
        let globalTestingMessage = "Global Testing Error Message"
        
        func globalOnErrorQuery(payload: GlobalErrorParameters) {
            if let queryKey = payload.meta["queryKey"] as? String, let message = payload.meta["globalTestingMessage"] as? String {
                if (queryKey == testingQueryKey && message == globalTestingMessage) {
                    exp.fulfill()
                }
            }
        }
        
        let meta = ["globalTestingMessage": globalTestingMessage]
        NTKQueryGlobalConfig.shared.initializeWithConfiguration(
            queriesConfig: [testingQueryKey: QueryConfig(queryFunction: nil, staleTime: nil, meta: meta)],
            globalOnErrorQuery: globalOnErrorQuery
        )
        
        func throwingQueryFunction() throws -> [String] {
            throw TestingErrors.Standard
        }
        _ = Query<[String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: throwingQueryFunction))
        
        waitForExpectations(timeout: 1)
    }

}
