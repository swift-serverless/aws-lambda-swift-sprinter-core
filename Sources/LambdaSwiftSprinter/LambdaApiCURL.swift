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
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public class LambdaApiCURL: LambdaAPI {
    let urlSession: URLSession
    let builder: LambdaRuntimeRequestBuilder
    static var timeoutIntervalForRequest: TimeInterval = 3600

    public required init(awsLambdaRuntimeAPI: String) throws {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = LambdaApiCURL.timeoutIntervalForRequest
        self.urlSession = URLSession(configuration: configuration)
        self.builder = try LambdaRuntimeRequestBuilder(awsLambdaRuntimeAPI: awsLambdaRuntimeAPI)
    }

    internal init(awsLambdaRuntimeAPI: String, session: URLSession) throws {
        self.urlSession = session
        self.builder = try LambdaRuntimeRequestBuilder(awsLambdaRuntimeAPI: awsLambdaRuntimeAPI)
    }

    internal func synchronousDataTask(with urlRequest: URLRequest) throws -> (event: Data, responseHeaders: [AnyHashable: Any]) {
        let (optData, optResponse, optError) = urlSession.synchronousDataTask(with: urlRequest)

        guard optError == nil else {
            throw SprinterError.endpointError(String(describing: optError!))
        }

        guard let httpResponse = optResponse as? HTTPURLResponse else {
            throw SprinterError.endpointError("Invalid HTTPURLResponse from AWS Lambda Runtime API. \(optResponse.debugDescription)")
        }

        guard httpResponse.statusCode >= 200,
            httpResponse.statusCode < 300 else {
            throw SprinterError.endpointError("Invalid HTTPURLResponse from AWS Lambda Runtime API. \(httpResponse.debugDescription)")
        }
        return (event: optData ?? Data(), responseHeaders: httpResponse.allHeaderFields)
    }

    public func getNextInvocation() throws -> (event: Data, responseHeaders: [AnyHashable: Any]) {
        let request = builder.getNextInvocationRequest()
        return try synchronousDataTask(with: request)
    }

    public func postInvocationResponse(for requestId: String, httpBody: Data) throws {
        let request = builder.postInvocationResponseRequest(requestId: requestId, body: httpBody)
        _ = try synchronousDataTask(with: request)
    }

    public func postInvocationError(for requestId: String, error: Error) throws {
        let request = builder.postInvocationErrorRequest(
            requestId: requestId,
            error: error
        )
        _ = try synchronousDataTask(with: request)
    }

    public func postInitializationError(error: Error) throws {
        let request = builder.postInitializationErrorRequest(error: error)
        _ = try synchronousDataTask(with: request)
    }
}

extension URLSession {
    internal func synchronousDataTask(with urlRequest: URLRequest) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?

        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()

        let dataTask = self.dataTask(with: urlRequest) { pData, pResponse, pError in
            data = pData
            response = pResponse
            error = pError
            dispatchGroup.leave()
        }
        dataTask.resume()
        dispatchGroup.wait()
        return (data, response, error)
    }
}

public typealias SprinterCURL = Sprinter<LambdaApiCURL>
