//
//  MutationStatusHandlerTests.swift
//  
//
//  Created by Wiktor Szlegier on 24/10/2023.
//

import XCTest
@testable import NTKQueryKit

@MainActor
final class MutationStatusHandlerTests: XCTestCase {
    
    let testingMutationKey = "mutationKey"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        NTKQueryGlobalConfig.shared.deinitializeConfiguration()
    }
    
    // MARK: onSuccess
    
    private func successMutation() -> [String] {
        return ["Success", "Mutation"]
    }

    func testLocalOnSuccessHandlerForMutation() async throws {
        let exp = expectation(description: "Local onSuccess handler is call on successful mutation call")
        
        func localOnSuccess(payload: Codable?) {
            exp.fulfill()
        }
        
        let mutation = Mutation<Void, [String]>(
            mutationKey: testingMutationKey,
            config: MutationConfig(mutationFunction: successMutation, onSuccess: localOnSuccess)
        )
        
        _ = try? await mutation.mutate()
        
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertTrue(mutation.isSuccess)
    }
    
    func testGlobalOnSuccessHandlerForMutation() async throws {
        let exp = expectation(description: "Global onSuccess handler is call on successful mutation call, when there is no local one set")
        
        func globalOnSuccess(payload: Codable?) {
            exp.fulfill()
        }
        
        let mutationsConfig = [testingMutationKey: MutationConfig<Void>(onSuccess: globalOnSuccess)]
        NTKQueryGlobalConfig.shared.initializeWithConfiguration(mutationsConfig: mutationsConfig)
        
        let mutation = Mutation<Void, [String]>(
            mutationKey: testingMutationKey,
            config: MutationConfig(mutationFunction: successMutation)
        )
        
        _ = try? await mutation.mutate()
        
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertTrue(mutation.isSuccess)
    }
    
    func testOnSuccessWhenBothLocalAndGlobalAreAvailable() async throws {
        let exp = expectation(description: "Local onSuccess handler is call on successful mutation call, when there are both local and global available")
        
        func localOnSuccess(payload: Codable?) {
            exp.fulfill()
        }
        func globalOnSuccess(payload: Codable?) {
            XCTFail("Global onSucess was called")
        }
        
        let mutationsConfig = [testingMutationKey: MutationConfig<Void>(onSuccess: globalOnSuccess)]
        NTKQueryGlobalConfig.shared.initializeWithConfiguration(mutationsConfig: mutationsConfig)
        
        let mutation = Mutation<Void, [String]>(
            mutationKey: testingMutationKey,
            config: MutationConfig(mutationFunction: successMutation, onSuccess: localOnSuccess)
        )
        
        _ = try? await mutation.mutate()
        
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertTrue(mutation.isSuccess)
    }

    // MARK: onError
    
    private func errorMutation() throws -> [String] {
        throw TestingErrors.Standard
    }

    func testLocalOnErrorHandlerForMutation() async throws {
        let exp = expectation(description: "Local onError handler is call on failure mutation call")
        
        func localOnError(error: GlobalErrorParameters) {
            exp.fulfill()
        }
        
        let mutation = Mutation<Void, [String]>(
            mutationKey: testingMutationKey,
            config: MutationConfig(mutationFunction: errorMutation, onError: localOnError)
        )
        
        _ = try? await mutation.mutate()
        
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertTrue(mutation.isError)
    }
    
    func testGlobalOnErrorHandlerForMutation() async throws {
        let exp = expectation(description: "Global onError handler is call on failure mutation call, when there is no local one set")
        
        func globalOnError(error: GlobalErrorParameters) {
            exp.fulfill()
        }
        
        let mutationsConfig = [testingMutationKey: MutationConfig<Void>(onError: globalOnError)]
        NTKQueryGlobalConfig.shared.initializeWithConfiguration(mutationsConfig: mutationsConfig)
        
        let mutation = Mutation<Void, [String]>(
            mutationKey: testingMutationKey,
            config: MutationConfig(mutationFunction: errorMutation)
        )
        
        _ = try? await mutation.mutate()
        
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertTrue(mutation.isError)
    }
    
    func testOnErrorWhenBothLocalAndGlobalAreAvailable() async throws {
        let exp = expectation(description: "Local onError handler is call on failure mutation call, when there are both local and global available")
        
        func localOnError(error: GlobalErrorParameters) {
            exp.fulfill()
        }
        func globalOnError(error: GlobalErrorParameters) {
            XCTFail("Global onError was called")
        }
        
        let mutationsConfig = [testingMutationKey: MutationConfig<Void>(onError: globalOnError)]
        NTKQueryGlobalConfig.shared.initializeWithConfiguration(mutationsConfig: mutationsConfig)
        
        let mutation = Mutation<Void, [String]>(
            mutationKey: testingMutationKey,
            config: MutationConfig(mutationFunction: errorMutation, onError: localOnError)
        )
        
        _ = try? await mutation.mutate()
        
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertTrue(mutation.isError)
    }
}
