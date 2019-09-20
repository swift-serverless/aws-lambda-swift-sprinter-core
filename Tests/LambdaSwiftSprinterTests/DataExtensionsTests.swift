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

struct DictionaryMock: Codable {
    let name: String
    let value: Int
}

struct EventMock: Codable {
    let string: String
    let int: Int
    let float: Float
    let dictionary: DictionaryMock
}

struct InvalidEventMock: Codable {
    let string: Int // This should be string
    let int: Int
    let float: Float
    let dictionary: DictionaryMock
}

class DataExtensionsTests: XCTestCase {
    var validData: Data!
    var invalidData: Data!

    override func setUp() {
        validData = Fixtures.validJSON.data(using: .utf8)
        XCTAssertNotNil(validData)

        invalidData = Fixtures.invalidJSON.data(using: .utf8)
        XCTAssertNotNil(invalidData)
    }

    func testDecodeJSONObj() {
        // When valid data
        let dictionary = try? validData.jsonObject()
        XCTAssertNotNil(dictionary)
        XCTAssertEqual(dictionary?["string"] as? String, "Name")
        XCTAssertEqual(dictionary?["int"] as? Int, 1)
        XCTAssertNotNil(dictionary?["dictionary"] as? [String: Any])

        // When invalid data
        XCTAssertNotNil(invalidData)
        XCTAssertThrowsError(try invalidData?.jsonObject())
    }

    func testEncodeJSONObj() {
        // When valid
        let data = try? Data(jsonObject: Fixtures.validJSONDictionary)
        XCTAssertNotNil(data)
    }

    func testDecode() {
        // When valid data

        let event: EventMock? = try? validData.decode()
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.string, "Name")
        XCTAssertEqual(event?.int, 1)
        XCTAssertEqual(event?.dictionary.name, "N")

        // When invalid data
        let eventInvalid: InvalidEventMock? = try? validData.decode()
        XCTAssertNil(eventInvalid)
    }

    func testEncode() {
        // When valid

        let dictionary = DictionaryMock(name: "dict", value: 3)
        let event = EventMock(string: "Name", int: 2, float: 3.7, dictionary: dictionary)

        let data = try? Data(from: event)
        XCTAssertNotNil(data)
    }

    func testPerformanceEncodeDecodeJSON() {
        // This is an example of a performance test case.
        measure {
            do {
                let dictionary = try validData.jsonObject()
                _ = try Data(jsonObject: dictionary)
            } catch {
                XCTFail("Unexpected")
            }
        }
    }

    func testPerformanceEncodeDecode() {
        // This is an example of a performance test case.
        measure {
            do {
                let event: EventMock = try validData.decode()
                _ = try Data(from: event)
            } catch {
                XCTFail("Unexpected")
            }
        }
    }

    static var allTests = [
        ("testDecodeJSONObj", testDecodeJSONObj),
        ("testEncodeJSONObj", testEncodeJSONObj),
        ("testPerformanceEncodeDecode", testPerformanceEncodeDecode),
        ("testPerformanceEncodeDecodeJSON", testPerformanceEncodeDecodeJSON),
        ("testDecode", testDecode),
        ("testEncode", testEncode),
    ]
}
