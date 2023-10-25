//
//  QueryValueTests.swift
//  
//
//  Created by Wiktor Szlegier on 24/10/2023.
//

import XCTest
@testable import NTKQueryKit
import Combine

@MainActor
final class QueryValueTests: XCTestCase {
    
    let testingQueryKey = "TestingQuery"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        QueryClient.shared.removeQuery(queryKey: testingQueryKey)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAccessingDataByQueryValue() throws {
        let fetchExp = expectation(description: "Query function was called")
        
        func queryFunction() -> [String] {
            fetchExp.fulfill()
            return ["Query", "Function"]
        }
        
        let query = Query<[String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: queryFunction, staleTime: 20000))
        let queryValue = QueryValue<[String]>(queryKey: testingQueryKey)
        
        waitForExpectations(timeout: 1)
        XCTAssertEqual(query.data, ["Query", "Function"], "Fetched data is saved in Query")
        XCTAssertEqual(queryValue.data, ["Query", "Function"], "Fetched data is accessible through QueryValue")
        
    }
    
    func testPublishingNewDataByQuery() throws {
        let fetchExp = expectation(description: "Query function was called")
        let refetchExp = expectation(description: "Query function was called on refetch")
        
        var calledFirstTime = true
        func queryFunction() async throws -> [String] {
            if (calledFirstTime == true) {
                calledFirstTime = false
                fetchExp.fulfill()
                return ["First", "Version"]
            } else {
                refetchExp.fulfill()
                return ["Second", "Version"]
            }
        }
        
        let query = Query<[String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: queryFunction, staleTime: 20000))
        let queryValue = QueryValue<[String]>(queryKey: testingQueryKey)
        
        wait(for: [fetchExp], timeout: 1)
        
        query.refetch()
        wait(for: [refetchExp], timeout: 1)
        
        // NOTE: Expect to see new data in Query and QueryValue instance
        XCTAssertEqual(query.data, ["Second", "Version"], "Data returned from the query instance should be updated after refetching")
        XCTAssertEqual(queryValue.data, ["Second", "Version"], "QueryValue successfully subscribe to publisher and receives new data after refetching")
    }
    
    func testAccessingCacheByQueryValue() throws {
        var cancellables: Set<AnyCancellable> = []
        
        QueryClient.shared.setQueryData(queryKey: testingQueryKey, data: ["Manual", "Overwrite"])
        
        let queryValue = QueryValue<[String]>(queryKey: testingQueryKey)
        
        let exp = expectation(description: "Publisher")
        
        queryValue.$data
            // NOTE: Ignore first nil
            .dropFirst()
            .sink(receiveValue: { data in
                XCTAssertEqual(data, ["Manual", "Overwrite"])
                exp.fulfill()
            }).store(in: &cancellables)
        
        wait(for: [exp], timeout: 1)
    }

}
