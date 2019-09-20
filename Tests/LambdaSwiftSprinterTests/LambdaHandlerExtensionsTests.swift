//    Copyright 2019 (c) Andrea Scuderi - https://github.com/swift-sprinter
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

@testable import LambdaSwiftSprinter
import XCTest

class LambdaHandlerExtensionsTests: XCTestCase {
    var validData: Data!
    var validContext: Context!
    var invalidData: Data!

    override func setUp() {
        validData = Fixtures.validJSON.data(using: .utf8)
        XCTAssertNotNil(validData)

        validContext = try? Context(environment: Fixtures.fullValidEnvironment,
                                    responseHeaders: Fixtures.fullValidHeaders)
        XCTAssertNotNil(validContext)

        invalidData = Fixtures.invalidJSON.data(using: .utf8)
        XCTAssertNotNil(invalidData)
    }

    func testDictionarySyncLambdaHandler() {
        // When valid Data and valid completionHandler
        let lambda = DictionarySyncLambdaHandler { (dictionary, _) -> [String: Any] in
            dictionary
        }
        let result = try? lambda.handler(event: validData,
                                         context: validContext)
        XCTAssertNotNil(result)

        // When invalid Data and valid completionHandler
        XCTAssertThrowsError(try lambda.handler(event: invalidData,
                                                context: validContext))

        // When valid Data and invalid completionHandler
        let lambda2 = DictionarySyncLambdaHandler { (_, _) -> [String: Any] in
            throw ErrorMock.someError
        }

        XCTAssertThrowsError(try lambda2.handler(event: validData,
                                                 context: validContext))

        // When invalid Data and invalid completionHandler
        XCTAssertThrowsError(try lambda2.handler(event: invalidData,
                                                 context: validContext))
    }

    func testDictionaryAsyncLambdaHandler() {
        // When valid Data and valid completionHandler
        let lambda = DictionaryAsyncLambdaHandler { dictionary, _, completion in
            completion(.success(dictionary))
        }
        let expectSuccess1 = expectation(description: "expect1")
        let expectFail1 = expectation(description: "expect1")
        expectFail1.isInverted = true
        lambda.handler(event: validData, context: validContext) { result in
            switch result {
            case .failure:
                expectFail1.fulfill()
            case .success(let result):
                XCTAssertNotNil(result)
                expectSuccess1.fulfill()
            }
        }

        // When invalid Data and valid completionHandler
        let expectSuccess2 = expectation(description: "expect2")
        expectSuccess2.isInverted = true
        let expectFail2 = expectation(description: "expect2")

        lambda.handler(event: invalidData, context: validContext) { result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
                expectFail2.fulfill()
            case .success:
                expectSuccess2.fulfill()
            }
        }

        // When valid Data and invalid completionHandler
        let lambda2 = DictionaryAsyncLambdaHandler { _, _, completion in
            completion(.failure(ErrorMock.someError))
        }

        let expectSuccess3 = expectation(description: "expect3")
        expectSuccess3.isInverted = true
        let expectFail3 = expectation(description: "expect3")

        lambda2.handler(event: validData, context: validContext) { result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
                expectFail3.fulfill()
            case .success:
                expectSuccess3.fulfill()
            }
        }

        // When invalid Data and valid completionHandler
        let expectSuccess4 = expectation(description: "expect3")
        expectSuccess4.isInverted = true
        let expectFail4 = expectation(description: "expect3")

        lambda2.handler(event: validData, context: validContext) { result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
                expectFail4.fulfill()
            case .success:
                expectSuccess4.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCodableSyncLambdaHandler() {
        // When valid Data and valid completionHandler
        let lambda = CodableSyncLambdaHandler<EventMock, EventMock> { (event, _) throws -> EventMock in
            return event
        }

        let result = try? lambda.handler(event: validData,
                                         context: validContext)
        XCTAssertNotNil(result)

        // When invalid Data and valid completionHandler
        XCTAssertThrowsError(try lambda.handler(event: invalidData,
                                                context: validContext))

        // When valid Data and invalid completionHandler
        let lambda2 = CodableSyncLambdaHandler<EventMock, EventMock> { (_, _) throws -> EventMock in
            throw ErrorMock.someError
        }

        XCTAssertThrowsError(try lambda2.handler(event: validData,
                                                 context: validContext))

        // When invalid Data and invalid completionHandler
        XCTAssertThrowsError(try lambda2.handler(event: invalidData,
                                                 context: validContext))
    }

    func testCodableAsyncLambdaHandler() {
        // When valid Data and valid completionHandler
        let lambda = CodableAsyncLambdaHandler<EventMock, EventMock> { event, _, completion in
            completion(.success(event))
        }

        let expectSuccess1 = expectation(description: "expect1")
        let expectFail1 = expectation(description: "expect1")
        expectFail1.isInverted = true
        lambda.handler(event: validData, context: validContext) { result in
            switch result {
            case .failure:
                expectFail1.fulfill()
            case .success(let result):
                XCTAssertNotNil(result)
                expectSuccess1.fulfill()
            }
        }

        // When invalid Data and valid completionHandler
        let expectSuccess2 = expectation(description: "expect2")
        expectSuccess2.isInverted = true
        let expectFail2 = expectation(description: "expect2")

        lambda.handler(event: invalidData, context: validContext) { result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
                expectFail2.fulfill()
            case .success:
                expectSuccess2.fulfill()
            }
        }

        // When valid Data and invalid completionHandler
        let lambda2 = CodableAsyncLambdaHandler<EventMock, EventMock> { _, _, completion in
            completion(.failure(ErrorMock.someError))
        }
        let expectSuccess3 = expectation(description: "expect3")
        expectSuccess3.isInverted = true
        let expectFail3 = expectation(description: "expect3")

        lambda2.handler(event: invalidData, context: validContext) { result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
                expectFail3.fulfill()
            case .success:
                expectSuccess3.fulfill()
            }
        }

        // When invalid Data and invalid completionHandler
        let expectSuccess4 = expectation(description: "expect2")
        expectSuccess4.isInverted = true
        let expectFail4 = expectation(description: "expect2")

        lambda2.handler(event: invalidData, context: validContext) { result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
                expectFail4.fulfill()
            case .success:
                expectSuccess4.fulfill()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    static var allTests = [
        ("testDictionarySyncLambdaHandler", testDictionarySyncLambdaHandler),
        ("testDictionaryAsyncLambdaHandler", testDictionaryAsyncLambdaHandler),
        ("testCodableSyncLambdaHandler", testCodableSyncLambdaHandler),
        ("testCodableAsyncLambdaHandler", testCodableAsyncLambdaHandler),
    ]
}
