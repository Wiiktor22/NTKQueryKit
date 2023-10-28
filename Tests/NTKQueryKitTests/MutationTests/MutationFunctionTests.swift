//
//  MutationFunctionTests.swift
//  
//
//  Created by Wiktor Szlegier on 24/10/2023.
//

import XCTest
@testable import NTKQueryKit

@MainActor
final class MutationFunctionTests: XCTestCase {
    
    let testingMutationKey = "mutationKey"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        NTKQueryGlobalConfig.shared.deinitializeConfiguration()
    }

    func testAccessingLocalMutationFunction() async throws {
        let exp = expectation(description: "Local mutationFunction was called in case it is the only one that is passed")
        func localMutationFunction() -> [String] {
            exp.fulfill()
            return ["Local", "Mutation"]
        }
        
        let mutation = Mutation<Void, [String]>(
            mutationKey: testingMutationKey,
            config: MutationConfig(mutationFunction: localMutationFunction)
        )
        
        _ = try? await mutation.mutate()
        
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertEqual(mutation.data, ["Local", "Mutation"])
    }
    
    func testAccessingLocalMutationFunctionWithParameters() async throws {
        let exp = expectation(description: "Local mutationFunction was called in case it is the only one that is passed")
        func localMutationFunction(_ param: [String]) -> [String] {
            exp.fulfill()
            return ["Local", "Mutation"] + param
        }
        
        let mutation = Mutation<[String], [String]>(
            mutationKey: testingMutationKey,
            config: MutationConfig(mutationFunction: localMutationFunction)
        )
        
        _ = try? await mutation.mutate(["With", "Parameters"])
        
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertEqual(mutation.data, ["Local", "Mutation", "With", "Parameters"])
    }
    
    func testAccessingGlobalMutationFunction() async throws {
        let exp = expectation(description: "Global mutationFunction was called in case when there is no local")
        
        func globalMutationFunction() -> [String] {
            exp.fulfill()
            return ["Global", "Mutation"]
        }
        
        let mutationsConfig = [testingMutationKey: MutationConfig(mutationFunction: globalMutationFunction)]
        NTKQueryGlobalConfig.shared.initializeWithConfiguration(mutationsConfig: mutationsConfig)
        
        let mutation = Mutation<Void, [String]>(
            mutationKey: testingMutationKey,
            config: MutationConfig()
        )
        
        _ = try? await mutation.mutate()
        
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertEqual(mutation.data, ["Global", "Mutation"])
    }
    
    func testAccessingGlobalMutationFunctionWithParameters() async throws {
        let exp = expectation(description: "Global mutationFunction was called in case when there is no local")
        
        func globalMutationFunction(_ param: [String]) -> [String] {
            exp.fulfill()
            return ["Global", "Mutation"] + param
        }
        
        let mutationsConfig = [testingMutationKey: MutationConfig(mutationFunction: globalMutationFunction)]
        NTKQueryGlobalConfig.shared.initializeWithConfiguration(mutationsConfig: mutationsConfig)
        
        let mutation = Mutation<[String], [String]>(
            mutationKey: testingMutationKey,
            config: MutationConfig(mutationFunction: globalMutationFunction)
        )
        
        _ = try? await mutation.mutate(["With", "Parameters"])
        
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertEqual(mutation.data, ["Global", "Mutation", "With", "Parameters"])
    }

    func testAccessingMutationFunctionWithLocalAndGlobal() async throws {
        let exp = expectation(description: "Local mutationFunction was called in case when both local and global functions are available")
        
        func localMutationFunction() -> [String] {
            exp.fulfill()
            return ["Local", "Mutation"]
        }
        func globalMutationFunction() -> [String] {
            XCTFail("Global mutation function was called")
            return ["Global", "Mutation"]
        }
        
        let mutationsConfig = [testingMutationKey: MutationConfig(mutationFunction: globalMutationFunction)]
        NTKQueryGlobalConfig.shared.initializeWithConfiguration(mutationsConfig: mutationsConfig)
        
        let mutation = Mutation<Void, [String]>(
            mutationKey: testingMutationKey,
            config: MutationConfig(mutationFunction: localMutationFunction)
        )
        
        _ = try? await mutation.mutate()
        
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertEqual(mutation.data, ["Local", "Mutation"])
    }
}
