//
//  ActiveQueriesManagerTests.swift
//  
//
//  Created by Wiktor Szlegier on 29/10/2023.
//

import XCTest
@testable import NTKQueryKit

@MainActor
final class ActiveQueriesManagerTests: XCTestCase {
    
    let testingQueryKey = "TestingQueryKey"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNotOverfetchingBehavior() throws {
        let firstInstanceExp = expectation(description: "The first query should be the only one that will fetch data")
        
        func firstQueryFunction() -> [String] {
            firstInstanceExp.fulfill()
            return ["First", "Query"]
        }
        
        func secondQueryFunction() -> [String] {
            XCTFail("The second query shouldn't be called since this is a duplication")
            return ["Second", "Query"]
        }
        
        func thirdQueryFunction() -> [String] {
            XCTFail("The third query shouldn't be called since this is a duplication")
            return ["Third", "Query"]
        }
        
        let firstQuery = Query<[String], [String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: firstQueryFunction))
        let secondQuery = Query<[String], [String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: secondQueryFunction))
        let thirdQuery = Query<[String], [String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: thirdQueryFunction))
        
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(firstQuery.data, ["First", "Query"])
        XCTAssertEqual(secondQuery.data, ["First", "Query"])
        XCTAssertEqual(thirdQuery.data, ["First", "Query"])
    }

}
