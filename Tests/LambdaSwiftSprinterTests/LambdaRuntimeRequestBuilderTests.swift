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

import Foundation
import XCTest

@testable import LambdaSwiftSprinter

class LambdaRuntimeRequestBuilderTests: XCTestCase {
    var builder: LambdaRuntimeRequestBuilder!
    var urlBuilder: LambdaRuntimeAPIUrlBuilder!
    var validData: Data!

    override func setUp() {
        builder = try? LambdaRuntimeRequestBuilder(awsLambdaRuntimeAPI: "runtime")
        urlBuilder = try? LambdaRuntimeAPIUrlBuilder(awsLambdaRuntimeAPI: "runtime")
        XCTAssertNotNil(urlBuilder)
    }

    func testInit() {
        XCTAssertNotNil(builder)
    }

    func testGetNextInvocationRequest() {
        let request = builder.getNextInvocationRequest()
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url, urlBuilder.nextInvocationURL())
    }

    func testPostInvocationResponseRequest() {
        validData = Fixtures.validJSON.data(using: .utf8)
        XCTAssertNotNil(validData)

        let request = builder.postInvocationResponseRequest(requestId: "request-id", body: validData)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url, urlBuilder.invocationResponseURL(requestId: "request-id"))
        XCTAssertNotNil(request.httpBody)

        let data: EventMock? = try? request.httpBody?.decode()
        XCTAssertNotNil(data)
    }

    func testPostInvocationErrorRequest() {
        let request = builder.postInvocationErrorRequest(requestId: "request-id", error: SprinterError.invalidJSON)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url, urlBuilder.invocationErrorURL(requestId: "request-id"))
        XCTAssertNotNil(request.httpBody)

        let data: InvocationError? = try? request.httpBody?.decode()
        XCTAssertNotNil(data)
    }

    func testPostInitializationErrorRequest() {
        let request = builder.postInitializationErrorRequest(error: SprinterError.invalidJSON)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url, urlBuilder.initializationErrorRequest())
        XCTAssertNotNil(request.httpBody)

        let data: InvocationError? = try? request.httpBody?.decode()
        XCTAssertNotNil(data)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testGetNextInvocationRequest", testGetNextInvocationRequest),
        ("testPostInvocationResponseRequest", testPostInvocationResponseRequest),
        ("testPostInvocationErrorRequest", testPostInvocationErrorRequest),
        ("testPostInitializationErrorRequest", testPostInitializationErrorRequest),
    ]
}
