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

public class Sprinter<API: LambdaAPI> {
    let apiClient: API
    let handlerName: String
    var lambdas: [String: LambdaHandler]
    let environment: [String: String]

    public init(environment: [String: String] = ProcessInfo.processInfo.environment) throws {
        self.lambdas = [:]
        self.environment = environment

        guard let runtime = environment.awsEnv(key: .lambdaRuntimeApi) else {
            throw SprinterError.missingEnvironmentVariables(.lambdaRuntimeApi)
        }

        guard let handler = environment.awsEnv(key: .handler) else {
            throw SprinterError.missingEnvironmentVariables(.handler)
        }

        guard let periodIndex = handler.firstIndex(of: ".") else {
            throw SprinterError.invalidHandlerName(handler)
        }

        self.apiClient = try API(awsLambdaRuntimeAPI: runtime)
        self.handlerName = String(handler[handler.index(after: periodIndex)...])
    }

    public func register(handler name: String, lambda: LambdaHandler) {
        lambdas[name] = lambda
    }

    public func register(handler name: String, lambda: @escaping SyncDictionaryLambda) {
        let lambda = DictionarySyncLambdaHandler(completionHandler: lambda)
        lambdas[name] = lambda
    }

    public func register(handler name: String, lambda: @escaping AsyncDictionaryLambda) {
        let lambda = DictionaryAsyncLambdaHandler(completionHandler: lambda)
        lambdas[name] = lambda
    }

    public func register<Event: Decodable, Response: Encodable>(handler name: String,
                                                                lambda: @escaping SyncCodableLambda<Event, Response>) {
        let lambda = CodableSyncLambdaHandler(handlerFunction: lambda)
        lambdas[name] = lambda
    }

    public func register<Event: Decodable, Response: Encodable>(handler name: String,
                                                                lambda: @escaping AsyncCodableLambda<Event, Response>) {
        let lambda = CodableAsyncLambdaHandler(handlerFunction: lambda)
        lambdas[name] = lambda
    }

    internal var cancel = false
    internal var counter = 0

    /**
     Run lambda. Call this function after the registration of the lambdas.

     - Throws: `SprinterErorr`
     */
    public func run() throws {
        while !cancel {
            let (event, responseHeaders) = try apiClient.getNextInvocation()
            counter += 1

            if let lambdaRuntimeTraceId = responseHeaders.rhk(key: .runtimeTraceId) {
                setenv(Context.AWSEnvironmentKey.xAmznTraceId.rawValue, lambdaRuntimeTraceId, 0)
            }

            guard let lambda = lambdas[handlerName] else {
                try apiClient.postInitializationError(error: SprinterError.missingEnvironmentVariables(.handler))
                return
            }

            let context = try Context(environment: environment, responseHeaders: responseHeaders)
            let result = lambda.commonHandler(event: event, context: context)

            switch result {
            case .success(let outputData):
                try apiClient.postInvocationResponse(for: context.awsRequestId, httpBody: outputData)
            case .failure(let error):
                try apiClient.postInvocationError(for: context.awsRequestId, error: error)
            }
        }
    }
}
