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

struct Event: Codable {
    let name: String
}

struct Response: Codable {
    let value: String
}

final class SprinterTests: XCTestCase {
    var environment = [String: String]()

    override func setUp() {
        environment = [:]
    }

    override func tearDown() {
        environment = [:]
    }

    func testInit() {
        // When value is not injected, but provided by ProcessInfo.processInfo.environment
        // When AWS_LAMBDA_RUNTIME_API is NULL
        XCTAssertThrowsError(try Sprinter<LambdaAPIMock>())

        // When k_HANDLER is NULL
        var environment = ["AWS_LAMBDA_RUNTIME_API": "some"]
        XCTAssertThrowsError(try Sprinter<LambdaAPIMock>(environment: environment))

        // When k_HANDLER doesn't contain .
        environment["_HANDLER"] = "some"
        XCTAssertThrowsError(try Sprinter<LambdaAPIMock>(environment: environment))

        // When Success
        environment["_HANDLER"] = "some.handler"
        let sprinter = try? Sprinter<LambdaAPIMock>(environment: environment)
        XCTAssertNotNil(sprinter)
        XCTAssertEqual(sprinter?.handlerName, "handler")
    }

    func testRegister() {
        let environment = ["AWS_LAMBDA_RUNTIME_API": "runtime",
                           "_HANDLER": "Lambda.handler"]
        let sprinter = try? Sprinter<LambdaAPIMock>(environment: environment)

        let completion = SyncLambdaHandlerMock()

        sprinter?.register(handler: "name", lambda: completion)
        XCTAssertNotNil(sprinter?.lambdas["name"])
    }

    func testRegisterSyncWithCompletion() {
        let environment = ["AWS_LAMBDA_RUNTIME_API": "runtime",
                           "_HANDLER": "Lambda.handler"]
        let sprinter = try? Sprinter<LambdaAPIMock>(environment: environment)

        let completion: SyncDictionaryLambda = { (_, _) -> [String: Any] in
            ["": ""]
        }
        sprinter?.register(handler: "handler", lambda: completion)

        guard let lambda = sprinter?.lambdas["handler"] else {
            XCTFail("Unexpected")
            return
        }
        XCTAssertNotNil(lambda)
    }

    func testRegisterAsyncWithCompletion() {
        let environment = ["AWS_LAMBDA_RUNTIME_API": "runtime",
                           "_HANDLER": "Lambda.handler"]
        let sprinter = try? Sprinter<LambdaAPIMock>(environment: environment)

        let lambdaFunction: AsyncDictionaryLambda = { _, _, completion in
            completion(.success(["": ""]))
        }
        sprinter?.register(handler: "handler", lambda: lambdaFunction)

        guard let lambda = sprinter?.lambdas["handler"] else {
            XCTFail("Unexpected")
            return
        }
        XCTAssertNotNil(lambda)
    }

    func testRegisterSyncTyped() {
        let environment = ["AWS_LAMBDA_RUNTIME_API": "runtime",
                           "_HANDLER": "Lambda.handler"]

        let sprinter = try? Sprinter<LambdaAPIMock>(environment: environment)

        let handlerFunction: SyncCodableLambda<Event, Response> = { (input, context) throws -> Response in

            Response(value: "test")
        }

        sprinter?.register(handler: "handler", lambda: handlerFunction)

        guard let lambda = sprinter?.lambdas["handler"] else {
            XCTFail("Unexpected")
            return
        }
        XCTAssertNotNil(lambda)
    }

    func testRegisterAsyncTyped() {
        let environment = Fixtures.validEnvironment
        let sprinter = try? Sprinter<LambdaAPIMock>(environment: environment)

        let handlerFunction: AsyncCodableLambda<Event, Response> = { (_, _, completion) -> Void in
            completion(.success(Response(value: "test")))
        }

        sprinter?.register(handler: "handler", lambda: handlerFunction)

        guard let lambda = sprinter?.lambdas["handler"] else {
            XCTFail("Unexpected")
            return
        }

        XCTAssertNotNil(lambda)
    }

    func testSprinterRun_When_Success() {
        let environment = Fixtures.validEnvironmentWithXRay
        let sprinter = try? Sprinter<LambdaAPIMock>(environment: environment)

        let handlerFunction: AsyncCodableLambda<Event, Response> = { (input, _, completion) -> Void in

            XCTAssertEqual(input.name, "input")
            completion(.success(Response(value: "test")))
        }

        sprinter?.register(handler: "handler", lambda: handlerFunction)

        let client = sprinter?.apiClient

        guard let data = try? Data(from: Event(name: "input")) else {
            XCTFail("Unexpected")
            return
        }

        client?.inputData = data
        client?.responseHeaderFields = Fixtures.validHeadersWithXRay

        let onGetNextCalled = expectation(description: "onGetNext")
        client?.onGetNext = {
            sprinter?.cancel = true
            onGetNextCalled.fulfill()
        }

        let onPostResponseCalled = expectation(description: "onPostResponse")
        client?.onPostResponse = { _, data in
            let output: Response? = try? data.decode()
            XCTAssertEqual(output?.value, "test")
            onPostResponseCalled.fulfill()
        }

        let onPostErrorCalled = expectation(description: "onPostErrorCalled")
        onPostErrorCalled.isInverted = true
        client?.onPostError = { _, error in
            print(error)
            onPostErrorCalled.fulfill()
        }

        try? sprinter?.run()
        wait(for: [onGetNextCalled, onPostResponseCalled, onPostErrorCalled], timeout: 1)
        XCTAssertEqual(sprinter?.counter, 1)
        XCTAssertEqual(ProcessInfo.processInfo.environment["_X_AMZN_TRACE_ID"], "trace-id")
    }

    func testSprinterRun_When_PostError() {
        let environment = Fixtures.validEnvironmentWithXRay
        let sprinter = try? Sprinter<LambdaAPIMock>(environment: environment)

        let handlerFunction: AsyncCodableLambda<Event, Response> = { (_, _, completion) -> Void in
            completion(.success(Response(value: "test")))
        }

        sprinter?.register(handler: "handler", lambda: handlerFunction)

        let client = sprinter?.apiClient
        client?.responseHeaderFields = Fixtures.validHeadersWithXRay

        let onGetNextCalled = expectation(description: "onGetNext")
        client?.onGetNext = {
            sprinter?.cancel = true
            onGetNextCalled.fulfill()
        }

        let onPostResponseCalled = expectation(description: "onPostResponse")
        onPostResponseCalled.isInverted = true
        client?.onPostResponse = { _, _ in
            onPostResponseCalled.fulfill()
        }

        let onPostErrorCalled = expectation(description: "onPostErrorCalled")
        client?.onPostError = { _, _ in
            onPostErrorCalled.fulfill()
        }

        try? sprinter?.run()
        wait(for: [onGetNextCalled, onPostResponseCalled, onPostErrorCalled], timeout: 1)
        XCTAssertEqual(sprinter?.counter, 1)
        XCTAssertEqual(ProcessInfo.processInfo.environment["_X_AMZN_TRACE_ID"], "trace-id")
    }

    func testSprinterRun_When_MissingHandler() {
        let environment = ["AWS_LAMBDA_RUNTIME_API": "some",
                           "_HANDLER": "some.handler"]
        let sprinter = try? Sprinter<LambdaAPIMock>(environment: environment)

        let handlerFunction: AsyncCodableLambda<Event, Response> = { (_, _, completion) -> Void in
            completion(.success(Response(value: "test")))
        }

        sprinter?.register(handler: "differentHandler", lambda: handlerFunction)

        let client = sprinter?.apiClient
        client?.responseHeaderFields = Fixtures.validHeaders

        let onGetNextCalled = expectation(description: "onGetNext")
        client?.onGetNext = {
            sprinter?.cancel = true
            onGetNextCalled.fulfill()
        }

        let onPostResponseCalled = expectation(description: "onPostResponse")
        onPostResponseCalled.isInverted = true
        client?.onPostResponse = { _, _ in
            onPostResponseCalled.fulfill()
        }

        let onPostErrorCalled = expectation(description: "onPostErrorCalled")
        onPostErrorCalled.isInverted = true
        client?.onPostError = { _, _ in
            onPostErrorCalled.fulfill()
        }

        let onInitErrorCalled = expectation(description: "onInitErrorCalled")
        client?.onInitError = { _ in
            onInitErrorCalled.fulfill()
        }

        try? sprinter?.run()
        wait(for: [onGetNextCalled, onPostResponseCalled, onPostErrorCalled, onInitErrorCalled], timeout: 1)
        XCTAssertEqual(sprinter?.counter, 1)
//        XCTAssertNil(ProcessInfo.processInfo.environment["_X_AMZN_TRACE_ID"], "trace-id")
    }

    func testSprinterRun_When_ContextThrow() {
        let environment = Fixtures.invalidEnvironmentMissingFunctionName
        let sprinter = try? Sprinter<LambdaAPIMock>(environment: environment)

        let handlerFunction: AsyncCodableLambda<Event, Response> = { (_, _, completion) -> Void in
            completion(.success(Response(value: "test")))
        }

        sprinter?.register(handler: "handler", lambda: handlerFunction)

        let client = sprinter?.apiClient
        client?.responseHeaderFields = Fixtures.validHeaders

        let onGetNextCalled = expectation(description: "onGetNext")
        client?.onGetNext = {
            sprinter?.cancel = true
            onGetNextCalled.fulfill()
        }

        let onPostResponseCalled = expectation(description: "onPostResponse")
        onPostResponseCalled.isInverted = true
        client?.onPostResponse = { _, _ in
            onPostResponseCalled.fulfill()
        }

        let onPostErrorCalled = expectation(description: "onPostErrorCalled")
        onPostErrorCalled.isInverted = true
        client?.onPostError = { _, _ in
            onPostErrorCalled.fulfill()
        }

        let onInitErrorCalled = expectation(description: "onInitErrorCalled")
        onInitErrorCalled.isInverted = true
        client?.onInitError = { _ in
            onInitErrorCalled.fulfill()
        }

        XCTAssertThrowsError(try sprinter?.run())
        wait(for: [onGetNextCalled, onPostResponseCalled, onPostErrorCalled, onInitErrorCalled], timeout: 1)
        XCTAssertEqual(sprinter?.counter, 1)
//        XCTAssertNil(ProcessInfo.processInfo.environment["_X_AMZN_TRACE_ID"], "trace-id")
    }

    static var allTests = [
        ("testInit", testInit),
        ("testRegister", testRegister),
        ("testRegisterSyncWithCompletion", testRegisterSyncWithCompletion),
        ("testRegisterAsyncWithCompletion", testRegisterAsyncWithCompletion),
        ("testRegisterSyncTyped", testRegisterSyncTyped),
        ("testRegisterAsyncTyped", testRegisterAsyncTyped),
        ("testSprinterRun_When_PostError", testSprinterRun_When_PostError),
        ("testSprinterRun_When_Success", testSprinterRun_When_Success),
        ("testSprinterRun_When_MissingHandler", testSprinterRun_When_MissingHandler),
        ("testSprinterRun_When_ContextThrow", testSprinterRun_When_ContextThrow),
    ]
}
