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

public protocol LambdaAPI: AnyObject {
    init(awsLambdaRuntimeAPI: String) throws
    func getNextInvocation() throws -> (event: Data, responseHeaders: [AnyHashable: Any])
    func postInvocationResponse(for requestId: String, httpBody: Data) throws
    func postInvocationError(for requestId: String, error: Error) throws
    func postInitializationError(error: Error) throws
}

public struct InvocationError: Codable {
    public let errorMessage: String
    public let errorType: String

    public init(errorMessage: String, errorType: String) {
        self.errorMessage = errorMessage
        self.errorType = errorType
    }
}

public struct LambdaRuntimeRequestBuilder {
    let urlBuilder: LambdaRuntimeAPIUrlBuilder

    init(awsLambdaRuntimeAPI: String) throws {
        self.urlBuilder = try LambdaRuntimeAPIUrlBuilder(awsLambdaRuntimeAPI: awsLambdaRuntimeAPI)
    }

    func getNextInvocationRequest() -> URLRequest {
        let url = urlBuilder.nextInvocationURL()
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return request
    }

    func postInvocationResponseRequest(requestId: String, body: Data) -> URLRequest {
        let url = urlBuilder.invocationResponseURL(requestId: requestId)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        return request
    }

    func postInvocationErrorRequest(requestId: String, error: Error) -> URLRequest {
        let url = urlBuilder.invocationErrorURL(requestId: requestId)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let errorMessage = String(describing: error)
        let invocationError = InvocationError(errorMessage: errorMessage,
                                              errorType: "PostInvocationError")
        if let httpBody = try? Data(from: invocationError) {
            request.httpBody = httpBody
        }
        return request
    }

    func postInitializationErrorRequest(error: Error) -> URLRequest {
        let url = urlBuilder.initializationErrorRequest()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let errorMessage = String(describing: error)
        let invocationError = InvocationError(errorMessage: errorMessage,
                                              errorType: "PostInvocationError")
        if let httpBody = try? Data(from: invocationError) {
            request.httpBody = httpBody
        }
        return request
    }
}
