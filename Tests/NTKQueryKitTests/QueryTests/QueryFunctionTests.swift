//
//  QueryFunctionTests.swift
//  
//
//  Created by Wiktor Szlegier on 24/10/2023.
//

import XCTest
@testable import NTKQueryKit

@MainActor
final class QueryFunctionTests: XCTestCase {
    
    let testingQueryKey = "TestingQuery"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        NTKQueryGlobalConfig.shared.deinitializeConfiguration()
    }

    func testAccessingLocalQueryFunction() throws {
        let exp = expectation(description: "Local queryFunction was called  when it is the only queryFunction for particular key (no global)")
        func localQueryFunction() -> [String] {
            exp.fulfill()
            return ["NTKQueryKit"]
        }
        
        _ = Query<[String], [String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: localQueryFunction))
        
        waitForExpectations(timeout: 1)
    }
    
    func testAccessingGlobalQueryFunction() throws {
        let exp = expectation(description: "Global queryFunction was called when there is no local query function")
        func globalQueryFunction() -> [String] {
            exp.fulfill()
            return ["NTKQueryKit", "Global"]
        }
        
        let queriesConfig = [testingQueryKey: QueryConfig(queryFunction: globalQueryFunction)]
        NTKQueryGlobalConfig.shared.initializeWithConfiguration(queriesConfig: queriesConfig)
        
        _ = Query<[String], [String]>(queryKey: testingQueryKey, config: QueryConfig())
        
        waitForExpectations(timeout: 1)
    }
    
    func testAccessingQueryFunctionWithLocalAndGlobal() throws {
        let exp = expectation(description: "Local queryFunction was called when both global and local query functions are set")
        func localQueryFunction() -> [String] {
            exp.fulfill()
            return ["NTKQueryKit", "Local"]
        }
        func globalQueryFunction() -> [String] {
            XCTFail("Global query function was called!")
            return ["NTKQueryKit", "Global"]
        }
        
        let queriesConfig = [testingQueryKey: QueryConfig(queryFunction: globalQueryFunction)]
        NTKQueryGlobalConfig.shared.initializeWithConfiguration(queriesConfig: queriesConfig)
        
        _ = Query<[String], [String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: localQueryFunction))
        
        waitForExpectations(timeout: 1)
    }

}
