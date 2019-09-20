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

class SyncLambdaHandlerMock: SyncLambdaHandler {
    var data = Data()
    var error: Error?

    func handler(event: Data, context: Context) throws -> Data {
        if let error = error {
            throw error
        }
        return data
    }
}

class AsyncLambdaHandlerMock: AsyncLambdaHandler {
    var data = Data()
    var error: Error?

    func handler(event: Data, context: Context, completion: @escaping (LambdaResult) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }
        completion(.success(data))
    }
}

class LambdaHandlerTests: XCTestCase {
    func testSyncLambdaHandler() {
        let lambdaHandler = SyncLambdaHandlerMock()

        let environment = Fixtures.fullValidEnvironment
        let responseHeaders = Fixtures.fullValidHeaders

        guard let context = try? Context(environment: environment,
                                         responseHeaders: responseHeaders) else {
            XCTFail("context cannot be nil")
            return
        }

        // when error
        lambdaHandler.error = ErrorMock.someError
        let result = lambdaHandler.commonHandler(event: Data(), context: context)
        switch result {
        case .failure(let error):
            XCTAssertNotNil(error)
        case .success:
            XCTFail("Unexpected")
        }

        // when success
        lambdaHandler.error = nil
        let result2 = lambdaHandler.commonHandler(event: Data(), context: context)
        switch result2 {
        case .failure:
            XCTFail("Unexpected")
        case .success(let value):
            XCTAssertNotNil(value)
        }
    }

    func testAsyncLambdaHandler() {
        let lambdaHandler = AsyncLambdaHandlerMock()
        let validData = Fixtures.validJSON.data(using: .utf8)!

        let environment = Fixtures.fullValidEnvironment
        let responseHeaders = Fixtures.fullValidHeaders

        guard let context = try? Context(environment: environment,
                                         responseHeaders: responseHeaders) else {
            XCTFail("context cannot be nil")
            return
        }

        // when error
        lambdaHandler.error = ErrorMock.someError
        let result = lambdaHandler.commonHandler(event: validData, context: context)
        switch result {
        case .failure(let error):
            XCTAssertNotNil(error)
        case .success:
            XCTFail("Unexpected")
        }

        // when success
        lambdaHandler.error = nil
        let result2 = lambdaHandler.commonHandler(event: validData, context: context)
        switch result2 {
        case .failure:
            XCTFail("Unexpected")
        case .success(let value):
            XCTAssertNotNil(value)
        }
    }

    static var allTests = [
        ("testSyncLambdaHandler", testSyncLambdaHandler),
        ("testAsyncLambdaHandler", testAsyncLambdaHandler),
    ]
}
