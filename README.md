# aws-lambda-swift-sprinter-core

[![Swift 5](https://img.shields.io/badge/Swift-5.0-blue.svg)](https://swift.org/download/) [![Swift 5.1.2](https://img.shields.io/badge/Swift-5.1.2-blue.svg)](https://swift.org/download/) ![](https://img.shields.io/badge/version-1.0.0--alpha.3-red) ![](https://travis-ci.com/swift-sprinter/aws-lambda-swift-sprinter-core.svg?branch=master) [![codecov](https://codecov.io/gh/swift-sprinter/aws-lambda-swift-sprinter-core/branch/master/graph/badge.svg)](https://codecov.io/gh/swift-sprinter/aws-lambda-swift-sprinter-core)

**LambdaSwiftSprinter** is a Swift framework allowing the development of AWS Lambdas based on the  [AWS Lambda Custom Runtime](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-custom.html) for Swift.

## Requirements

It's required Swift 5.0 to build the code.

Follow the instruction on the [official Swift web site](https://swift.org/download/) to prepare your development environment.
The repository **Swift-Sprinter** contains a full description of what is an AWS Lambda Custom Runtime for Swift and how to build and use it.


## Usage

From the command line, create a directory to contain your project
```console
mkdir HelloWorld
cd HelloWorld
```

Use swift package manager to start your project:
```console
swift package init --type executable
```

Edit the file Package.swift by adding the dependency LambdaSwiftSprinter to the target:
```swift
import PackageDescription

let package = Package(
    name: "HelloWorld",
    dependencies: [
       .package(url: "https://github.com/swift-sprinter/aws-lambda-swift-sprinter-core", from: "1.0.0-alpha.3")
    ],
    targets: [
        .target(
            name: "HelloWorld",
            dependencies: ["LambdaSwiftSprinter"]),
        .testTarget(
            name: "HelloWorldTests",
            dependencies: ["HelloWorld"]),
    ]
)
```

Modify the main.swift file with the following code:
```swift
import LambdaSwiftSprinter
import Foundation

struct Event: Codable {
    let name: String
}

struct Response: Codable {
    let message: String
}

let syncLambda: SyncCodableLambda<Event, Response> = { (event, context) throws -> Response in
    let message = "Hello World! Hello \(event.name)!"
    return Response(message: message)
}

public func log(_ object: Any, flush: Bool = false) {
    fputs("\(object)\n", stderr)
    if flush {
        fflush(stderr)
    }
}

do {
    let sprinter = try SprinterCURL()
    sprinter.register(handler: "helloWorld", lambda: syncLambda)
    try sprinter.run()
} catch let error {
    log(String(describing: error))
}
```
Update the lambda with your code.

- The **Event** object is the JSON received by the Lambda invocation
- The **Context** object contains the information to interact with AWS Lambda.
- The **Response** object is the response of your AWS Lamda invocation.
- The **Handler** contains the implementation of the code executed by the AWS Lambda. (SyncCodableLambda<Event, Response> in the example)

To run the lambda in the custom runtime environment with **SwiftSprinter** it's required to:

- **Define** the lambda handler: ``` let lambda: SyncCodableLambda<Event, Response> = ... ```
- **Init** the sprinter:  ``` let sprinter = try SprinterCURL()```
- **Register** the lambda handler: ```sprinter.register(handler: "helloWorld", lambda: lambda)```
- **Run** the sprinter: ```try sprinter.run()```
- **Log**: It's a good practice to enclose the code in a *do/catch*, this will ensure to log all the errors in the AWS Lambda error output.

Refer to the [lambda programming model](https://docs.aws.amazon.com/lambda/latest/dg/programming-model-v2.html) for more info on AWS Lambda.

## Examples

The examples are maintained here [https://github.com/swift-sprinter/aws-lambda-swift-sprinter](https://github.com/swift-sprinter/aws-lambda-swift-sprinter), to keep the size of this Swift package small.

- [HelloWorld](https://github.com/swift-sprinter/aws-lambda-swift-sprinter/blob/master/Examples/HelloWorld): A basic Lambda Swift example
- [HTTPSRequest](https://github.com/swift-sprinter/aws-lambda-swift-sprinter/blob/master/Examples/HTTPSRequest): A basic example showing how to perform an HTTPS request from the Swift Lambda using the [LambdaSwiftSprinterNioPlugin](https://github.com/swift-sprinter/aws-lambda-swift-sprinter-nio-plugin)
- [S3Test](https://github.com/swift-sprinter/aws-lambda-swift-sprinter/blob/master/Examples/S3Test): A basic example showing how to access an S3 bucket from the Swift Lambda using [https://github.com/swift-aws/aws-sdk-swift](https://github.com/swift-aws/aws-sdk-swift).

# Design goals

The LambdaSwiftSprinter framework has been designed to implement the following goals:
- Codable Event and Response
- Dictionary Event and Response
- Synchronous and Asynchronous functions
- Plugin architecture
- No third party dependencies
- Safe Context
- Error throwing

## Codable Event and Response

To ensure the Event and Response JSON passed through the lambda are converted into struct by Swift-Sprinter, you need to declare them as Codable:

```swift
struct Event: Codable {
    let name: String
}

struct Response: Codable {
    let message: String
}
```

and then implement you synchronous ```AsyncCodableLambda<Event: Decodable, Response: Encodable>``` or asynchronous ```SyncCodableLambda<Event: Decodable, Response: Encodable>``` lambda.

```swift
// Synchronous lambda example:

let syncLambda: SyncCodableLambda<Event, Response> = { (event, context) throws -> Response in
    let message = "Hello World! Hello \(event.name)!"
    return Response(message: message)
}

// Asynchronous lambda example:

let asyncLambda: AsyncCodableLambda<Event, Response> = { (event, context, completion) -> Void in
    let message = "Hello World! Hello \(event.name)!"
    completion(.success(Response(message: message)))
}
```

## Dictionary Event and Response

Sometime could not be convenient to define the Event and Response with a fixed struct. In this case, could be better to receive a dictionary from the JSON passed through the lambda by Swift-Sprinter.


In this case, it's possible to define the asynchronous lambda with ```AsyncDictionaryLambda``` or the synchronous lambda with ```SyncDictionaryLambda```.

```swift
// Synchronous lambda example:

let syncDictLambda = { (dictionary: [String: Any], context: Context) throws -> [String: Any] in
    var result = [String: Any]()
    if let name = dictionary["name"] as? String {
        let message = "Hello World! Hello \(name)!"
        result["message"] = message
        } else {
        throw MyLambdaError.invalidEvent
    }
    return result
}

// Asynchronous lambda example:

let asyncDictLambda: AsyncDictionaryLambda = { (dictionary, context, completion) in
    var result = [String: Any]()
    if let name = dictionary["name"] as? String {
        let message = "Hello World! Hello \(name)!"
        result["message"] = message
    } else {
        completion(.failure(MyLambdaError.invalidEvent))
    }
    completion(.success(result))
}
```

## Syncrhonous and Asynchronous functions

**Asynchronous** lambda functions call a completion handler to return a Result:
Use ```AsyncCodableLambda<Event: Decodable, Response: Encodable>```  and  ```AsyncDictionaryLambda``` to define an asynchronous lambda. The completion handler takes a *Result<Value, Error>* as paremater with a **.success(value)** or **.failure(error)**.
The code inside the asynchronous lambda could be asynchronous and the completion handler must be called to send the result.

```swift
let asyncLambda: AsyncCodableLambda<Event, Response> = { event, context, completion in
    let message = "Hello World! Hello \(event.name)!"
    return completion(.success(Response(message: message)))
}

let asyncDictLambda: AsyncDictionaryLambda = { (dictionary, context, completion) in
    var result = [String: Any]()
    if let name = dictionary["name"] as? String {
        let message = "Hello World! Hello \(name)!"
        result["message"] = message
    } else {
        completion(.failure(MyLambdaError.invalidEvent))
    }
    completion(.success(result))
}
```

**Synchronous** lambda functions returns a value or throws an error:
Use ```SyncCodableLambda<Event: Decodable, Response: Encodable>```  and  ```SyncDictionaryLambda``` to define an synchronous lambda. The code inside the synchronous lambda must be synchronous.

```swift
let syncLambda: SyncCodableLambda<Event, Response> = { (event, context) throws -> Response in
    let message = "Hello World! Hello \(event.name)!"
    return Response(message: message)
}

let syncDictLambda = { (dictionary: [String: Any], context: Context) throws -> [String: Any] in
    var result = [String: Any]()
    if let name = dictionary["name"] as? String {
        let message = "Hello World! Hello \(name)!"
        result["message"] = message
    } else {
        throw MyLambdaError.invalidEvent
    }
    return result
}
```

It's possible to extend the library by implementing ```SyncLambdaHandler``` and ```AsyncLambdaHandler```.

### Plugin architecture

The Sprinter class depends on the implementation of the LambdaAPI protocol.
This allows adding LambdaAPI classes as a plugin.

```swift
public protocol LambdaAPI: class {

    init(awsLambdaRuntimeAPI: String) throws
    func getNextInvocation() throws -> (event: Data, responseHeaders: [AnyHashable: Any])
    func postInvocationResponse(for requestId: String, httpBody: Data) throws
    func postInvocationError(for requestId: String, error: Error) throws
    func postInitializationError(error: Error) throws
}
```

The default implementation **LambdaApiCURL** is based on the Foundation class URLSession and will call the AWS Runtime API using this class.

## No third-party dependencies

One of the main issues on server-side swift is resolving the software dependencies. The fragmentation of the existing server-side library and the use of different versions could add complexity to the core library.  **By design, this core framework does not depend on other third-party frameworks.** In particular, this choice allows using differents Logging and Network framework and a custom implementation of the LambdaAPI.

## Safe Context
The **Context** object, passed inside the lambda, contains all the **environment** variables defined by the Lambda implementation: https://docs.aws.amazon.com/lambda/latest/dg/lambda-environment-variables.html

The **Context** object, passed inside the lambda, contains all the **response headers** variables defined by the Lambda Runtime API implementation: https://docs.aws.amazon.com/lambda/latest/dg/runtimes-api.html

In case some of the required Environment variables or Response Headers are not found an error is thrown.

## Error throwing

By design, the library throws all the errors. This will ensure:

- All the errors are not hidden inside the implementation.
- It's possible to use a custom logging library.

Library errors:

```swift
public enum SprinterError: Error {

    /// A required Environment variable is missing.
    case missingEnvironmentVariables(Context.AWSEnvironmentKey)

    /// A required Response Header variable is missing.
    case missingResponseHeaderVariables(Context.ResponseHeaderKey)

    /// The handler is missing or does not contain a ```.``` in the name.
    /// A valid name must have a format similar to 'Executable.handler'
    case invalidHandlerName(String)

    /// API Runtime Error
    case endpointError(String)

    /// The JSON payload is nil
    case invalidJSON
}
```

Encoding/Decoding and errors:

If the code uses the Codable Event and Response all the encoding and decoding errors will be thrown.

Basic Logging:

To print all the errors to the lambda error output it's possible to use the following code:

```swift
public func log(_ object: Any, flush: Bool = false) {
    fputs("\(object)\n", stderr)
    if flush {
    fflush(stderr)
    }
}
```

A do/catch will ensure all the error will be reported to the AWS lambda output.
```swift
do {
    let sprinter = try SprinterCURL()
    sprinter.register(handler: "helloWorld", lambda: lambda)
    try sprinter.run()
} catch let error {
    log(String(describing: error))
}
```

Note:

Use `String(describing: error)` to convert an Error to String. 
If you use `error.localizedDescription`, the string on Linux will be `"The operation could not be completed"`.

## Known Limitation with HTTPS connections with Foundation

As documented by [sebsto](https://forums.swift.org/u/sebsto) in the [AWS Lambda Runtime Swift forum](https://forums.swift.org/t/aws-lambda-runtime-api/18498)

*Trying to make an HTTPS connection from the lambda function (with the Foundation library) it fails with "error setting certificate verify locations:\n CAfile: /etc/ssl/certs/ca-certificates.crt\n CApath: /etc/ssl/certs".*

For this reason, it's required a plugin based on NIO 2 to prevent the HTTPS issue.
One of the goals of this core library is to allow the developers to use their NIO 2 library to work around the issue.

# Contributions

Contributions are more than welcome! Follow [this guide](https://github.com/swift-sprinter/aws-lambda-swift-sprinter-core/blob/master/CONTRIBUTING.md) to contribute.

# Acknowledgements

This project has been inspired by the amazing work of the following people:

- Matthew Burke, Capital One : https://medium.com/capital-one-tech/serverless-computing-with-swift-f515ff052919

- Justin Sanders : https://medium.com/@gigq/using-swift-in-aws-lambda-6e2a67a27e03

- Claus Höfele : https://medium.com/@claushoefele/serverless-swift-2e8dce589b68

- Kohki Miki, Cookpad : https://github.com/giginet/aws-lambda-swift-runtime

- Toni Sutter : https://github.com/tonisuter/aws-lambda-swift

- Sébastien Stormacq :  https://github.com/sebsto/swift-custom-runtime-lambda

A special thanks to [BJSS](https://www.bjss.com) to sustain me in delivering this project.