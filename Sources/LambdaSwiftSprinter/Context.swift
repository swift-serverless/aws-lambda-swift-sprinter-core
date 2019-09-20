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

public struct Context {
    // MARK: Lambda Environment Variables
    // https://docs.aws.amazon.com/lambda/latest/dg/lambda-environment-variables.html

    /// The name of the function.
    public let functionName: String

    /// The version of the function being executed.
    public let functionVersion: String

    /// The name of the Amazon CloudWatch Logs group
    public let logGroupName: String

    /// The name of the Amazon CloudWatch Logs group and stream for the function.
    public let logStreamName: String

    /// The amount of memory available to the function in MB.
    public let memoryLimitInMB: String

    /// The handler location configured on the function.
    public var handler: String? {
        return environment(.handler)
    }

    /// The AWS region where the Lambda function is executed.
    public var region: String? {
        return environment(.region)
    }

    /// The runtime identifier, prefixed by AWS_Lambda_. For example, AWS_Lambda_java8.
    public var executionEnv: String? {
        return environment(.executionEnv)
    }

    /// Access keys obtained from the function's execution role.
    public var accessKeyId: String? {
        return environment(.accessKeyId)
    }

    /// Secret Access keys obtained from the function's execution role.
    public var secretAccessKey: String? {
        return environment(.secretAccessKey)
    }

    /// Session Token obtained from the function's execution role.
    public var sessionToken: String? {
        return environment(.sessionToken)
    }

    /// en_US.UTF-8. This is the locale of the runtime.
    public var lang: String? {
        return environment(.lang)
    }

    /// The environment's timezone (UTC). The execution environment uses NTP to synchronize the system clock.
    public var timeZone: String? {
        return environment(.timeZone)
    }

    /// The path to your Lambda function code.
    public var taskRoot: String? {
        return environment(.taskRoot)
    }

    /// The path to runtime libraries.
    public var lambdaRuntimDir: String? {
        return environment(.lambdaRuntimDir)
    }

    /// /usr/local/bin:/usr/bin/:/bin:/opt/bin
    public var path: String? {
        return environment(.path)
    }

    /// LD_LIBRARY_PATH
    /// /lib64:/usr/lib64:$LAMBDA_RUNTIME_DIR:$LAMBDA_RUNTIME_DIR/lib:$LAMBDA_TASK_ROOT:$LAMBDA_TASK_ROOT/lib:/opt/lib
    public var ldLibraryPath: String? {
        return environment(.ldLibraryPath)
    }

    /// NODE_PATH
    /// (Node.js) /opt/nodejs/node8/node_modules/:/opt/nodejs/node_modules:$LAMBDA_RUNTIME_DIR/node_modules
    public var nodePath: String? {
        return environment(.nodePath)
    }

    /// PYTHONPATH
    /// (Python) $LAMBDA_RUNTIME_DIR.
    public var pythonPath: String? {
        return environment(.pythonPath)
    }

    /// GEM_PATH
    /// (Ruby) $LAMBDA_TASK_ROOT/vendor/bundle/ruby/2.5.0:/opt/ruby/gems/2.5.0.
    public var gemPath: String? {
        return environment(.gemPath)
    }

    /// (custom runtime) The host and port of the runtime API.
    public var lambdaRuntimeApi: String? {
        return environment(.lambdaRuntimeApi)
    }

    /// X-Ray Identifier
    public var xAmznTraceId: String? {
        return environment(.xAmznTraceId)
    }

    public enum AWSEnvironmentKey: String {
        case handler = "_HANDLER"
        case region = "AWS_REGION"
        case executionEnv = "AWS_EXECUTION_ENV"
        case functionName = "AWS_LAMBDA_FUNCTION_NAME"
        case memoryLimitInMB = "AWS_LAMBDA_FUNCTION_MEMORY_SIZE"
        case functionVersion = "AWS_LAMBDA_FUNCTION_VERSION"
        case logGroupName = "AWS_LAMBDA_LOG_GROUP_NAME"
        case logStreamName = "AWS_LAMBDA_LOG_STREAM_NAME"
        case accessKeyId = "AWS_ACCESS_KEY_ID"
        case secretAccessKey = "AWS_SECRET_ACCESS_KEY"
        case sessionToken = "AWS_SESSION_TOKEN"
        case lang = "LANG"
        case timeZone = "TZ"
        case taskRoot = "LAMBDA_TASK_ROOT"
        case lambdaRuntimDir = "LAMBDA_RUNTIME_DIR"
        case path = "PATH"
        case ldLibraryPath = "LD_LIBRARY_PATH"
        case nodePath = "NODE_PATH"
        case pythonPath = "PYTHONPATH"
        case gemPath = "GEM_PATH"
        case lambdaRuntimeApi = "AWS_LAMBDA_RUNTIME_API"
        case xAmznTraceId = "_X_AMZN_TRACE_ID"
    }

    // MARK: AWS Lambda Runtime Interface
    // https://docs.aws.amazon.com/lambda/latest/dg/runtimes-api.html

    /// The request ID, which identifies the request that triggered the function invocation.
    public var awsRequestId: String

    /// The date that the function times out in Unix time milliseconds. For example, 1542409706888.
    public var deadlineMs: Int

    /// The ARN of the Lambda function, version, or alias that's specified in the invocation.
    public var invokedFunctionArn: String

    /// The AWS X-Ray tracing header.
    public var runtimeTraceId: String?

    /// For invocations from the AWS Mobile SDK, data about the Amazon Cognito identity provider.
    public var identity: [String: Any]?

    /// For invocations from the AWS Mobile SDK, data about the client application and device.
    public var clientContext: [String: Any]?

    public enum ResponseHeaderKey: String {
        case awsRequestId = "Lambda-Runtime-Aws-Request-Id"
        case deadlineMs = "Lambda-Runtime-Deadline-Ms"
        case invokedFunctionArn = "Lambda-Runtime-Invoked-Function-Arn"
        case runtimeTraceId = "Lambda-Runtime-Trace-Id"
        case clientContext = "Lambda-Runtime-Client-Context"
        case identity = "Lambda-Runtime-Cognito-Identity"
    }

    // MARK: internals
    internal static func validate(headers: [AnyHashable: Any], key: ResponseHeaderKey) throws -> String {
        guard let value = headers[key.rawValue] as? String else {
            throw SprinterError.missingResponseHeaderVariables(key)
        }
        return value
    }

    internal static func validate(headers: [AnyHashable: Any], key: ResponseHeaderKey) throws -> Int {
        guard let value = headers[key.rawValue] as? String,
            let number = Int(value) else {
            throw SprinterError.missingResponseHeaderVariables(key)
        }
        return number
    }

    internal static func validate(environment: [String: String], key: AWSEnvironmentKey) throws -> String {
        guard let value = environment[key.rawValue] else {
            throw SprinterError.missingEnvironmentVariables(key)
        }
        return value
    }

    internal func environment(_ key: AWSEnvironmentKey) -> String? {
        return environment[key.rawValue]
    }

    internal var environment: [String: String]

    // MARK: init
    public init(environment: [String: String], responseHeaders: [AnyHashable: Any]) throws {
        self.functionName = try Context.validate(environment: environment, key: .functionName)
        self.functionVersion = try Context.validate(environment: environment, key: .functionVersion)
        self.logGroupName = try Context.validate(environment: environment, key: .logGroupName)
        self.logStreamName = try Context.validate(environment: environment, key: .logStreamName)
        self.memoryLimitInMB = try Context.validate(environment: environment, key: .memoryLimitInMB)

        self.awsRequestId = try Context.validate(headers: responseHeaders, key: .awsRequestId)
        self.invokedFunctionArn = try Context.validate(headers: responseHeaders, key: .invokedFunctionArn)
        self.deadlineMs = try Context.validate(headers: responseHeaders, key: .deadlineMs)
        self.runtimeTraceId = responseHeaders.rhk(key: .runtimeTraceId)
        self.identity = responseHeaders.rhkToDictionary(key: .identity)
        self.clientContext = responseHeaders.rhkToDictionary(key: .clientContext)

        self.environment = environment
    }
}

// MARK: helpers

extension Dictionary where Key == String, Value == String {
    func awsEnv(key: Context.AWSEnvironmentKey) -> String? {
        return self[key.rawValue]
    }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    func rhk(key: Context.ResponseHeaderKey) -> String? {
        return self[key.rawValue] as? String
    }

    func rhkToDictionary(key: Context.ResponseHeaderKey) -> [String: Any]? {
        return self[key.rawValue] as? [String: Any]
    }
}
