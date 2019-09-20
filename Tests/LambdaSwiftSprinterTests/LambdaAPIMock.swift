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
@testable import LambdaSwiftSprinter

class LambdaAPIMock: LambdaAPI {
    var inputData: Data = Data()
    var responseHeaderFields = [String: String]()
    var error: SprinterError?

    var stop = false

    var onGetNext: () -> Void = {}

    var onPostResponse: (String, Data) -> Void = { _, _ in
    }

    var onPostError: (String, Error) -> Void = { _, _ in
    }

    var onInitError: (Error) -> Void = { _ in
    }

    required init(awsLambdaRuntimeAPI: String) throws {
        self.awsLambdaRuntimeAPI = awsLambdaRuntimeAPI
    }

    var awsLambdaRuntimeAPI: String

    func getNextInvocation() throws -> (event: Data, responseHeaders: [AnyHashable: Any]) {
        if let error = self.error {
            throw error
        }
        onGetNext()
        return (inputData, responseHeaderFields)
    }

    func postInvocationResponse(for requestId: String, httpBody: Data) throws {
        if let error = self.error {
            throw error
        }
        onPostResponse(requestId, httpBody)
    }

    func postInvocationError(for requestId: String, error: Error) throws {
        if let error = self.error {
            throw error
        }
        onPostError(requestId, error)
    }

    func postInitializationError(error: Error) throws {
        if let error = self.error {
            throw error
        }
        onInitError(error)
    }
}
