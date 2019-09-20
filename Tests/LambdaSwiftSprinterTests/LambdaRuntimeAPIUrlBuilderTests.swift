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

class LambdaRuntimeAPIUrlBuilderTests: XCTestCase {
    var urlBuilder: LambdaRuntimeAPIUrlBuilder!
    let awsLambdaRuntimeAPI = "runtime"
    let requestId = "request-id"

    override func setUp() {
        urlBuilder = try? LambdaRuntimeAPIUrlBuilder(awsLambdaRuntimeAPI: awsLambdaRuntimeAPI)
    }

    func testInit() {
        XCTAssertNotNil(urlBuilder)
    }

    func testNextInvocationURL() {
        let value = "http://\(awsLambdaRuntimeAPI)/2018-06-01/runtime/invocation/next"
        XCTAssertEqual(urlBuilder.nextInvocationURL().absoluteString, value)
    }

    func testInvocationResponseURL() {
        let value = "http://\(awsLambdaRuntimeAPI)/2018-06-01/runtime/invocation/\(requestId)/response"
        XCTAssertEqual(urlBuilder.invocationResponseURL(requestId: requestId).absoluteString, value)
    }

    func testInvocationErrorURL() {
        let value = "http://\(awsLambdaRuntimeAPI)/2018-06-01/runtime/invocation/\(requestId)/error"
        XCTAssertEqual(urlBuilder.invocationErrorURL(requestId: requestId).absoluteString, value)
    }

    func testInitializationErrorRequest() {
        let value = "http://\(awsLambdaRuntimeAPI)/2018-06-01/runtime/init/error"
        XCTAssertEqual(urlBuilder.initializationErrorRequest().absoluteString, value)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testNextInvocationURL", testNextInvocationURL),
        ("testInvocationResponseURL", testInvocationResponseURL),
        ("testInvocationErrorURL", testInvocationErrorURL),
        ("testInitializationErrorRequest", testInitializationErrorRequest),
    ]
}
