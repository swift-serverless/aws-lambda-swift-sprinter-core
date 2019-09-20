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

class ContextTests: XCTestCase {
    func testInit() {
        let validEnvironment = Fixtures.validEnvironment
        let validResponseHeaders = Fixtures.validHeadersWithXRay

        let invalidEnvironment = Fixtures.invalidEnvironmentMissingFunctionName
        let invalidResponseHeaders = Fixtures.invalidHeaders

        // When valid environment and responseHeaders
        XCTAssertNoThrow(try Context(environment: validEnvironment,
                                     responseHeaders: validResponseHeaders))

        // When invalid environment and valid responseHeaders
        XCTAssertThrowsError(try Context(environment: invalidEnvironment,
                                         responseHeaders: validResponseHeaders))

        // When valid environment and invalid responseHeaders
        XCTAssertThrowsError(try Context(environment: validEnvironment,
                                         responseHeaders: invalidResponseHeaders))

        // When invalid environment and invalid responseHeaders
        XCTAssertThrowsError(try Context(environment: invalidEnvironment,
                                         responseHeaders: invalidResponseHeaders))
    }

    func testProperties() {
        let environment = Fixtures.fullValidEnvironment
        let responseHeaders = Fixtures.fullValidHeaders

        guard let context = try? Context(environment: environment,
                                         responseHeaders: responseHeaders) else {
            XCTFail("context cannot be nil")
            return
        }

        XCTAssertEqual(environment.count, 22)

        XCTAssertEqual(context.handler, environment["_HANDLER"])
        XCTAssertEqual(context.region, environment["AWS_REGION"])
        XCTAssertEqual(context.executionEnv, environment["AWS_EXECUTION_ENV"])
        XCTAssertEqual(context.functionName, environment["AWS_LAMBDA_FUNCTION_NAME"])
        XCTAssertEqual(context.memoryLimitInMB, environment["AWS_LAMBDA_FUNCTION_MEMORY_SIZE"])
        XCTAssertEqual(context.functionVersion, environment["AWS_LAMBDA_FUNCTION_VERSION"])
        XCTAssertEqual(context.logGroupName, environment["AWS_LAMBDA_LOG_GROUP_NAME"])
        XCTAssertEqual(context.logStreamName, environment["AWS_LAMBDA_LOG_STREAM_NAME"])
        XCTAssertEqual(context.accessKeyId, environment["AWS_ACCESS_KEY_ID"])
        XCTAssertEqual(context.secretAccessKey, environment["AWS_SECRET_ACCESS_KEY"])
        XCTAssertEqual(context.sessionToken, environment["AWS_SESSION_TOKEN"])
        XCTAssertEqual(context.lang, environment["LANG"])
        XCTAssertEqual(context.timeZone, environment["TZ"])
        XCTAssertEqual(context.taskRoot, environment["LAMBDA_TASK_ROOT"])
        XCTAssertEqual(context.lambdaRuntimDir, environment["LAMBDA_RUNTIME_DIR"])
        XCTAssertEqual(context.path, environment["PATH"])
        XCTAssertEqual(context.ldLibraryPath, environment["LD_LIBRARY_PATH"])
        XCTAssertEqual(context.nodePath, environment["NODE_PATH"])
        XCTAssertEqual(context.pythonPath, environment["PYTHONPATH"])
        XCTAssertEqual(context.gemPath, environment["GEM_PATH"])
        XCTAssertEqual(context.lambdaRuntimeApi, environment["AWS_LAMBDA_RUNTIME_API"])
        XCTAssertEqual(context.xAmznTraceId, environment["_X_AMZN_TRACE_ID"])

        XCTAssertEqual(responseHeaders.count, 6)
        XCTAssertEqual(context.awsRequestId, responseHeaders["Lambda-Runtime-Aws-Request-Id"] as? String)
        let deadlineMs = Int(responseHeaders["Lambda-Runtime-Deadline-Ms"] as? String ?? "")
        XCTAssertEqual(context.deadlineMs, deadlineMs)
        XCTAssertEqual(context.deadlineMs, 1568043534055)
        XCTAssertEqual(context.invokedFunctionArn, responseHeaders["Lambda-Runtime-Invoked-Function-Arn"] as? String)
        XCTAssertEqual(context.runtimeTraceId, responseHeaders["Lambda-Runtime-Trace-Id"] as? String)
        XCTAssertNotNil(context.clientContext)
        XCTAssertNotNil(context.identity)

        XCTAssertEqual(context.environment.count, 22)
    }

    func testValidateThrows() {
        XCTAssertThrowsError(try Context.validate(headers: [String: String](),
                                                  key: Context.ResponseHeaderKey.deadlineMs) as String)
        XCTAssertThrowsError(try Context.validate(headers: [String: String](),
                                                  key: Context.ResponseHeaderKey.deadlineMs) as Int)
        XCTAssertThrowsError(try Context.validate(environment: [String: String](),
                                                  key: .functionName))
    }

    func testPerformanceInit() {
        let environment = Fixtures.validEnvironment
        let responseHeaders = Fixtures.validHeadersWithXRay

        measure {
            let context = try? Context(environment: environment, responseHeaders: responseHeaders)
            XCTAssertNotNil(context)
        }
    }

    static var allTests = [
        ("testInit", testInit),
        ("testProperties", testProperties),
        ("testPerformanceInit", testPerformanceInit),
        ("testValidateThrows", testValidateThrows),
    ]
}
