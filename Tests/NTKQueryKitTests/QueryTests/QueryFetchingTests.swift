//
//  QueryFetchingTests.swift
//  
//
//  Created by Wiktor Szlegier on 24/10/2023.
//

import XCTest
@testable import NTKQueryKit

@MainActor
final class QueryFetchingTests: XCTestCase {
    
    let testingQueryKey = "TestingQuery"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        QueryClient.shared.removeQuery(queryKey: testingQueryKey)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFetchingWithEmptyCacheAndStaleTimeEqualZero() throws {
        let exp = expectation(description: "Query function was called when there is no data stored in cache and stale time set to 0")
        
        func queryFunction() async throws -> [String] {
            try? await Task.sleep(nanoseconds: 250_000_000)
            exp.fulfill()
            return ["Query", "Function"]
        }
        
        _ = Query<[String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: queryFunction))
        
        waitForExpectations(timeout: 1)
        
        let cacheEntryData: [String]? = QueryClient.shared.getQueryData(queryKey: testingQueryKey)
        XCTAssertNil(cacheEntryData)
    }
    
    func testFetchingWithEmptyCacheAndStaleTimeBiggerThanZero() throws {
        let exp = expectation(description: "Query function was called when there is no data stored in cache and stale time is bigger than 0")
        
        func queryFunction() async throws -> [String] {
            try? await Task.sleep(nanoseconds: 250_000_000)
            exp.fulfill()
            return ["Query", "Function"]
        }
        
        _ = Query<[String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: queryFunction, staleTime: 3000))
        
        waitForExpectations(timeout: 1)
        
        let cacheEntryData: [String]? = QueryClient.shared.getQueryData(queryKey: testingQueryKey)
        XCTAssertEqual(cacheEntryData, ["Query", "Function"])
    }
    
    func testFetchingWithStoredCacheAndNotStaleData() throws {
        let exp = expectation(description: "When stale data is stored in cache entry queryFunction SHOULDN'T be called")
        exp.isInverted = true // NOTE: Inverted, because we expect to NOT call queryFunction
        
        QueryClient.shared.setQueryData(queryKey: testingQueryKey, data: ["Manual", "Update"])
        
        func queryFunction() async throws -> [String] {
            try? await Task.sleep(nanoseconds: 250_000_000)
            exp.fulfill()
            return ["Query", "Function"]
        }
        
        let query = Query<[String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: queryFunction, staleTime: 10000))
        
        waitForExpectations(timeout: 1)
        
        let cacheEntryData: [String]? = QueryClient.shared.getQueryData(queryKey: testingQueryKey)
        XCTAssertEqual(cacheEntryData, ["Manual", "Update"], "Data stored in cache should be equal to the one already stored")
        XCTAssertEqual(query.data, ["Manual", "Update"], "Data returned from the query instance should be equal to the one stored in cache")
    }
    
    func testFetchingWithStoredCacheAndStaleData() async throws {
        let exp = expectation(description: "When not stale data is stored in cache entry queryFunction MUST be called")
        
        QueryClient.shared.setQueryData(queryKey: testingQueryKey, data: ["Manual", "Update"])
        
        // NOTE: Waiting until data become stale
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        func queryFunction() async throws -> [String] {
            exp.fulfill()
            return ["Query", "Function"]
        }
        let query = Query<[String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: queryFunction, staleTime: 250))
        
        await fulfillment(of: [exp], timeout: 1000)
        
        let cacheEntryData: [String]? = QueryClient.shared.getQueryData(queryKey: testingQueryKey)
        XCTAssertEqual(cacheEntryData, ["Query", "Function"], "Data stored in cache should be updated after it was stale")
        XCTAssertEqual(query.data, ["Query", "Function"], "Data returned from the query instance should come from queryFunction since the one in cache entry was stale")
    }
    
    // MARK: Refetching
    
    func testRefetching() {
        let fetchExp = expectation(description: "Query function should be called first time")
        let refetchExp = expectation(description: "Query function should be called on refetch")
        
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
        
        let query = Query<[String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: queryFunction))
        wait(for: [fetchExp], timeout: 1)
        
        query.refetch()
        wait(for: [refetchExp], timeout: 1)
        
        XCTAssertEqual(query.data, ["Second", "Version"], "Data returned from the query instance should be updated after refetching")
    }
    
    func testRefetchingWithStaleTimeBiggerThanZero() throws {
        let fetchExp = expectation(description: "Query function should be called first time")
        let refetchExp = expectation(description: "Query function should be called on refetch")
        
        let testingQueryKey = "TestingQuery"
        
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
        
        let query = Query<[String]>(queryKey: testingQueryKey, config: QueryConfig(queryFunction: queryFunction, staleTime: 10000))
        wait(for: [fetchExp], timeout: 1)
        
        query.refetch()
        wait(for: [refetchExp], timeout: 1)
        
        // NOTE: Despite the fact that data wasn't stale, after manual refetch we still expect to see new data
        XCTAssertEqual(query.data, ["Second", "Version"], "Data returned from the query instance should be updated after refetching")
        
        let cacheEntryData: [String]? = QueryClient.shared.getQueryData(queryKey: testingQueryKey)
        XCTAssertEqual(cacheEntryData, ["Second", "Version"], "Data stored in cache should be updated after refetching with stale time set")
    }

}
