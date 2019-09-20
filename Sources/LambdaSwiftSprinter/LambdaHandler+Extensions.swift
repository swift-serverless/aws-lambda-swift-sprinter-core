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

struct CodableSyncLambdaHandler<Event: Decodable, Response: Encodable>: SyncLambdaHandler {
    let handlerFunction: (Event, Context) throws -> Response

    func handler(event: Data, context: Context) throws -> Data {
        let data = try event.decode() as Event
        let output = try handlerFunction(data, context)
        return try Data(from: output)
    }
}

struct CodableAsyncLambdaHandler<Event: Decodable, Response: Encodable>: AsyncLambdaHandler {
    let handlerFunction: AsyncCodableLambda<Event, Response>

    func handler(event: Data, context: Context, completion: @escaping (LambdaResult) -> Void) {
        do {
            let data = try event.decode() as Event
            handlerFunction(data, context) { outputResult in
                switch outputResult {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let outputDict):
                    do {
                        let outputData = try Data(from: outputDict)
                        completion(.success(outputData))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}

struct DictionarySyncLambdaHandler: SyncLambdaHandler {
    let completionHandler: ([String: Any], Context) throws -> [String: Any]

    func handler(event: Data, context: Context) throws -> Data {
        let data = try event.jsonObject()
        let output = try completionHandler(data, context)
        return try Data(jsonObject: output)
    }
}

struct DictionaryAsyncLambdaHandler: AsyncLambdaHandler {
    let completionHandler: AsyncDictionaryLambda

    func handler(event: Data, context: Context, completion: @escaping (LambdaResult) -> Void) {
        do {
            let jsonDictionary = try event.jsonObject()
            completionHandler(jsonDictionary, context) { outputResult in
                switch outputResult {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let outputDict):
                    do {
                        let outputData = try Data(jsonObject: outputDict)
                        completion(.success(outputData))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}
