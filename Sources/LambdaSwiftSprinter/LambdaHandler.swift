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

public typealias LambdaResult = Result<Data, Error>
public typealias DictionaryResult = Result<[String: Any], Error>

public typealias AsyncDictionaryLambda = ([String: Any], Context, @escaping (DictionaryResult) -> Void) -> Void
public typealias AsyncCodableLambda<Event: Decodable, Response: Encodable> = (Event, Context, @escaping (Result<Response, Error>) -> Void) -> Void

public typealias SyncDictionaryLambda = ([String: Any], Context) throws -> [String: Any]
public typealias SyncCodableLambda<Event: Decodable, Response: Encodable> = (Event, Context) throws -> Response

public protocol LambdaHandler {
    func commonHandler(event: Data, context: Context) -> LambdaResult
}

public protocol SyncLambdaHandler: LambdaHandler {
    func handler(event: Data, context: Context) throws -> Data
}

public extension SyncLambdaHandler {
    func commonHandler(event: Data, context: Context) -> LambdaResult {
        do {
            let data = try handler(event: event, context: context)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
}

public protocol AsyncLambdaHandler: LambdaHandler {
    func handler(event: Data, context: Context, completion: @escaping (LambdaResult) -> Void)
}

public extension AsyncLambdaHandler {
    func commonHandler(event: Data, context: Context) -> LambdaResult {
        var handlerResult: LambdaResult?
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        handler(event: event, context: context) { result in
            handlerResult = result
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        return handlerResult!
    }
}
