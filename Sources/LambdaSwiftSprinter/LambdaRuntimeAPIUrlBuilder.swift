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
#if swift(>=5.1) && os(Linux)
    import FoundationNetworking
#endif

public struct LambdaRuntimeAPIUrlBuilder {
    let awsLambdaRuntimeAPI: String
    let baseURL: URL

    public init(awsLambdaRuntimeAPI: String) throws {
        self.awsLambdaRuntimeAPI = awsLambdaRuntimeAPI
        guard let baseURL = URL(string: "http://\(awsLambdaRuntimeAPI)/2018-06-01/runtime") else {
            throw SprinterError.missingEnvironmentVariables(.lambdaRuntimeApi)
        }
        self.baseURL = baseURL
    }

    public func nextInvocationURL() -> URL {
        var url = baseURL
        url.appendPathComponent("/invocation/next")
        return url
    }

    public func invocationResponseURL(requestId: String) -> URL {
        var url = baseURL
        url.appendPathComponent("/invocation/\(requestId)/response")
        return url
    }

    public func invocationErrorURL(requestId: String) -> URL {
        var url = baseURL
        url.appendPathComponent("/invocation/\(requestId)/error")
        return url
    }

    public func initializationErrorRequest() -> URL {
        var url = baseURL
        url.appendPathComponent("/init/error")
        return url
    }
}
