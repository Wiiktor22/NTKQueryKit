//
//  QuerySelectTests.swift
//  
//
//  Created by Wiktor Szlegier on 12/03/2024.
//

import XCTest
@testable import NTKQueryKit

@MainActor
final class QuerySelectTests: XCTestCase {
    
    let testingQueryKey = "TestingQuerySelect"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        QueryClient.shared.removeQuery(queryKey: testingQueryKey)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBasicSelectUsage() throws {
        let exp = expectation(description: "Local queryFunction was called, therefore data is fetched")
        func localQueryFunction() -> [String] {
            exp.fulfill()
            return ["Full", "Data"]
        }
        
        func select(_ data: [String]) -> [String] {
            return data.filter { $0 == "Data" }
        }
        
        let mainQuery = Query<[String], [String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: localQueryFunction))
        let partialQuery = Query<[String], [String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: localQueryFunction), select: select)
        
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(mainQuery.data, ["Full", "Data"], "For query instance without provided select function fetched data should be available")
        XCTAssertEqual(partialQuery.data, ["Data"], "For query instance with provided select function only selected data should be available")
    }
    
    func testSelectBehaviorAfterChangingData() throws {
        let queryFuncExp = expectation(description: "Local queryFunction was called, therefore data is fetched")
        func localQueryFunction() -> [String] {
            queryFuncExp.fulfill()
            return ["Full", "Data"]
        }
        
        func select(_ data: [String]) -> [String] {
            return data.filter { $0 == "Data" }
        }
        
        let mainQuery = Query<[String], [String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: localQueryFunction))
        let partialQuery = Query<[String], [String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: localQueryFunction), select: select)
        
        wait(for: [queryFuncExp], timeout: 1)
        
        XCTAssertEqual(mainQuery.data, ["Full", "Data"], "For query instance without provided select function fetched data should be available")
        XCTAssertEqual(partialQuery.data, ["Data"], "For query instance with provided select function only selected data should be available")
        
        QueryClient.shared.setQueryData(queryKey: testingQueryKey, data: ["Full", "Data", "Changed", "Data"])
        
        XCTAssertEqual(mainQuery.data, ["Full", "Data", "Changed", "Data"], "After update, query instance should have updated (full) access to data")
        XCTAssertEqual(partialQuery.data, ["Data", "Data"], "After update, query instance should run select function again to provide updated portion of data")
    }
    
    func testSelectWithQueryValue() throws {
        let queryFuncExp = expectation(description: "Local queryFunction was called, therefore data is fetched")
        func localQueryFunction() -> [String] {
            queryFuncExp.fulfill()
            return ["Full", "Data"]
        }
        
        func select(_ data: [String]) -> Int {
            let filteredData = data.filter { $0 == "Data" }
            print(filteredData)
            return filteredData.count
        }
        
        let query = Query<[String], [String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: localQueryFunction))
        let queryValue = QueryValue<[String], Int>(queryKey: testingQueryKey, select: select)
        
        wait(for: [queryFuncExp], timeout: 1)
        
        XCTAssertEqual(query.data, ["Full", "Data"], "For query instance without provided select function fetched data should be available")
        XCTAssertEqual(queryValue.data, 1, "For query value instance with provided select function only selected data should be available")
    }
}
