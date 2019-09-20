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

// References:
//  --: https://www.hackingwithswift.com/articles/153/how-to-test-ios-networking-code-the-easy-way
//  --: https://nshipster.com/nsurlprotocol/

class URLProtocolMock: URLProtocol {
    // this dictionary maps URLs to test data
    static var testURLs = [URL?: (Data?, URLResponse?, Error?)]()

    // say we want to handle all types of request
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // if we have a valid URL…
        guard let url = request.url else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        let output: (Data?, URLResponse?, Error?)? = URLProtocolMock.testURLs[url]

        // if we have test data for that URL…
        if let data = output?.0 {
            // …load it immediately.
            client?.urlProtocol(self, didLoad: data)
        }

        // …and we return our response if defined…
        if let response = output?.1 {
            client?.urlProtocol(self,
                                didReceive: response,
                                cacheStoragePolicy: .notAllowed)
        }

        // …and we return our error if defined…
        if let error = output?.2 {
            client?.urlProtocol(self, didFailWithError: error)
        }

        // mark that we've finished
        client?.urlProtocolDidFinishLoading(self)
    }

    // this method is required but doesn't need to do anything
    override func stopLoading() {}
}
