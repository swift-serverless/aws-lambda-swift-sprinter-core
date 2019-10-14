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
import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
import XCTest

enum ErrorMock: Error {
    case someError
}

class LambdaApiCURLTests: XCTestCase {
    var config: URLSessionConfiguration!
    var session: URLSession!
    var urlBuilder: LambdaRuntimeAPIUrlBuilder!
    let awsLambdaRuntimeAPI = "localhost:80"
    let requestID = "009248902898383-298783789-933098"
    var validData: Data!
    var urlResponse: URLResponse!
    var httpResponse: HTTPURLResponse!
    var badHttpResponse: HTTPURLResponse!
    var networkError: NSError!
    var api: LambdaApiCURL!

    override func setUp() {
        config = URLSessionConfiguration.default
        config.protocolClasses = [URLProtocolMock.self]

        urlBuilder = try? LambdaRuntimeAPIUrlBuilder(awsLambdaRuntimeAPI: awsLambdaRuntimeAPI)
        XCTAssertNotNil(urlBuilder)

        validData = Fixtures.validJSON.data(using: .utf8)

        urlResponse = URLResponse(url: urlBuilder.nextInvocationURL(),
                                  mimeType: "application/json",
                                  expectedContentLength: 10,
                                  textEncodingName: nil)
        httpResponse = HTTPURLResponse(url: urlBuilder.nextInvocationURL(),
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: ["Accepts": "application/json"])
        badHttpResponse = HTTPURLResponse(url: urlBuilder.nextInvocationURL(),
                                          statusCode: 300,
                                          httpVersion: nil,
                                          headerFields: nil)
        networkError = NSError(
            domain: "NSURLErrorDomain",
            code: -1004, // kCFURLErrorCannotConnectToHost
            userInfo: nil
        )

        session = URLSession(configuration: config)

        api = try? LambdaApiCURL(awsLambdaRuntimeAPI: awsLambdaRuntimeAPI, session: session)
        XCTAssertNotNil(api)
    }

    override func tearDown() {
        URLProtocolMock.testURLs = [:]
        session = nil
        api = nil
    }

    func testInit() {
        // when valid awsLambdaRuntimeAPI
        let api = try? LambdaApiCURL(awsLambdaRuntimeAPI: awsLambdaRuntimeAPI)
        XCTAssertNotNil(api)
        XCTAssertNotNil(api?.builder)
        XCTAssertNotNil(api?.urlSession)

        let session = api?.urlSession
        XCTAssertEqual(session?.configuration.timeoutIntervalForRequest, LambdaApiCURL.timeoutIntervalForRequest)

        // when invalid awsLambdaRuntimeAPI
        XCTAssertThrowsError(try LambdaApiCURL(awsLambdaRuntimeAPI: "##"))
    }

    public func testGetNextInvocation() {
        let url = urlBuilder.nextInvocationURL()
        // Throws

        // when (Data?,URLREsponse?,Error?) = (validData,urlResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, urlResponse, nil)]
        XCTAssertThrowsError(try api?.getNextInvocation())

        // when (Data?,URLREsponse?,Error?) = (validData,urlResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, urlResponse, nil)]
        XCTAssertThrowsError(try api?.getNextInvocation())

        // when (Data?,URLREsponse?,Error?) = (validData,badHttpResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, badHttpResponse, nil)]
        XCTAssertThrowsError(try api?.getNextInvocation())

        // when (Data?,URLREsponse?,Error?) = (nil,urlResponse,networkError)
        URLProtocolMock.testURLs = [url: (nil, urlResponse, networkError)]
        XCTAssertThrowsError(try api?.getNextInvocation())

        // when (Data?,URLREsponse?,Error?) = (validData, httpResponse, networkError)
        URLProtocolMock.testURLs = [url: (validData, httpResponse, networkError)]
        XCTAssertThrowsError(try api?.getNextInvocation())

        // Success
        // when (Data?,URLREsponse?,Error?) = (validData,httpResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, httpResponse, nil)]
        let response = try? api?.getNextInvocation()
        XCTAssertNotNil(response?.event)
        XCTAssertNotNil(response?.responseHeaders)
        XCTAssertEqual(response?.responseHeaders.count, 1)
    }

    public func testPostInvocationResponse() {
        let url = urlBuilder.invocationResponseURL(requestId: requestID)
        // Throws

        // when (Data?,URLREsponse?,Error?) = (validData,urlResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, urlResponse, nil)]
        XCTAssertThrowsError(try api?.postInvocationResponse(for: requestID, httpBody: validData))

        // when (Data?,URLREsponse?,Error?) = (validData,urlResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, urlResponse, nil)]
        XCTAssertThrowsError(try api?.postInvocationResponse(for: requestID, httpBody: validData))

        // when (Data?,URLREsponse?,Error?) = (validData,badHttpResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, badHttpResponse, nil)]
        XCTAssertThrowsError(try api?.postInvocationResponse(for: requestID, httpBody: validData))

        // when (Data?,URLREsponse?,Error?) = (nil,urlResponse,networkError)
        URLProtocolMock.testURLs = [url: (nil, urlResponse, networkError)]
        XCTAssertThrowsError(try api?.postInvocationResponse(for: requestID, httpBody: validData))

        // when (Data?,URLREsponse?,Error?) = (validData, httpResponse, networkError)
        URLProtocolMock.testURLs = [url: (validData, httpResponse, networkError)]
        XCTAssertThrowsError(try api?.postInvocationResponse(for: requestID, httpBody: validData))

        // Success
        // when (Data?,URLREsponse?,Error?) = (validData,httpResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, httpResponse, nil)]
        XCTAssertNoThrow(try api.postInvocationResponse(for: requestID, httpBody: validData))
    }

    public func testPostInvocationError() {
        let url = urlBuilder.invocationErrorURL(requestId: requestID)
        let error = ErrorMock.someError
        // Throws

        // when (Data?,URLREsponse?,Error?) = (validData,urlResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, urlResponse, nil)]
        XCTAssertThrowsError(try api?.postInvocationError(for: requestID, error: error))

        // when (Data?,URLREsponse?,Error?) = (validData,urlResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, urlResponse, nil)]
        XCTAssertThrowsError(try api?.postInvocationError(for: requestID, error: error))

        // when (Data?,URLREsponse?,Error?) = (validData,badHttpResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, badHttpResponse, nil)]
        XCTAssertThrowsError(try api?.postInvocationError(for: requestID, error: error))

        // when (Data?,URLREsponse?,Error?) = (nil,urlResponse,networkError)
        URLProtocolMock.testURLs = [url: (nil, urlResponse, networkError)]
        XCTAssertThrowsError(try api?.postInvocationError(for: requestID, error: error))

        // when (Data?,URLREsponse?,Error?) = (validData, httpResponse, networkError)
        URLProtocolMock.testURLs = [url: (validData, httpResponse, networkError)]
        XCTAssertThrowsError(try api?.postInvocationError(for: requestID, error: error))

        // Success
        // when (Data?,URLREsponse?,Error?) = (validData,httpResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, httpResponse, nil)]
        XCTAssertNoThrow(try api?.postInvocationError(for: requestID, error: error))
    }

    public func testPostInitializationError() {
        let url = urlBuilder.initializationErrorRequest()
        let error = ErrorMock.someError
        // Throws

        // when (Data?,URLREsponse?,Error?) = (validData,urlResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, urlResponse, nil)]
        XCTAssertThrowsError(try api?.postInitializationError(error: error))

        // when (Data?,URLREsponse?,Error?) = (validData,urlResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, urlResponse, nil)]
        XCTAssertThrowsError(try api?.postInitializationError(error: error))

        // when (Data?,URLREsponse?,Error?) = (validData,badHttpResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, badHttpResponse, nil)]
        XCTAssertThrowsError(try api?.postInitializationError(error: error))

        // when (Data?,URLREsponse?,Error?) = (nil,urlResponse,networkError)
        URLProtocolMock.testURLs = [url: (nil, urlResponse, networkError)]
        XCTAssertThrowsError(try api?.postInitializationError(error: error))

        // when (Data?,URLREsponse?,Error?) = (validData, httpResponse, networkError)
        URLProtocolMock.testURLs = [url: (validData, httpResponse, networkError)]
        XCTAssertThrowsError(try api?.postInitializationError(error: error))

        // Success
        // when (Data?,URLREsponse?,Error?) = (validData,httpResponse,nil)
        URLProtocolMock.testURLs = [url: (validData, httpResponse, nil)]
        XCTAssertNoThrow(try api?.postInitializationError(error: error))
    }
    
    static var allTests = [
        ("testInit", testInit),
        ("testGetNextInvocation", testGetNextInvocation),
        ("testPostInvocationResponse", testPostInvocationResponse),
        ("testPostInvocationError", testPostInvocationError),
        ("testPostInitializationError", testPostInitializationError),
    ]

}
