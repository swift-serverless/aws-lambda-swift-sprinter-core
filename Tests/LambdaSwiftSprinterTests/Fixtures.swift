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
import XCTest

struct Fixtures {
    static let validHeaders = ["Lambda-Runtime-Aws-Request-Id": "cb40b6a0-aeff-4d2b-bcdc-9010acae195d",
                               "Lambda-Runtime-Deadline-Ms": "1568043534055",
                               "Lambda-Runtime-Invoked-Function-Arn": "arn:aws:lambda:eu-west-1:000000000000:function:Lambda"]

    static let validHeadersWithXRay = ["Lambda-Runtime-Aws-Request-Id": "cb40b6a0-aeff-4d2b-bcdc-9010acae195d",
                                       "Lambda-Runtime-Deadline-Ms": "1568043534055",
                                       "Lambda-Runtime-Invoked-Function-Arn": "arn:aws:lambda:eu-west-1:000000000000:function:Lambda",
                                       "Lambda-Runtime-Trace-Id": "trace-id"]

    static let fullValidHeaders: [String: Any] = ["Lambda-Runtime-Aws-Request-Id": "cb40b6a0-aeff-4d2b-bcdc-9010acae195d",
                                                  "Lambda-Runtime-Deadline-Ms": "1568043534055",
                                                  "Lambda-Runtime-Invoked-Function-Arn": "arn:aws:lambda:eu-west-1:000000000000:function:Lambda",
                                                  "Lambda-Runtime-Trace-Id": "trace-id",
                                                  "Lambda-Runtime-Client-Context": ["": ""],
                                                  "Lambda-Runtime-Cognito-Identity": ["": ""]]

    static let invalidHeaders = ["Lambda-Runtime-Aws-Request-Id": "0040b6a0-aeff-4d2b-bcdc-9010acae195d",
                                 "Lambda-Runtime-Deadline-Ms": "a"]

    static let validEnvironment = ["AWS_LAMBDA_RUNTIME_API": "runtime",
                                   "_HANDLER": "Lambda.handler",
                                   "AWS_LAMBDA_FUNCTION_NAME": "Lambda",
                                   "AWS_LAMBDA_FUNCTION_VERSION": "$LATEST",
                                   "AWS_LAMBDA_LOG_GROUP_NAME": "/aws/lambda/Lambda",
                                   "AWS_LAMBDA_LOG_STREAM_NAME": "2019/09/08/[$LATEST]000023faf4eb46fda06507e07c100000",
                                   "AWS_LAMBDA_FUNCTION_MEMORY_SIZE": "128"]

    static let fullValidEnvironment = ["AWS_LAMBDA_RUNTIME_API": "runtime",
                                       "_HANDLER": "Lambda.handler",
                                       "AWS_LAMBDA_FUNCTION_NAME": "Lambda",
                                       "AWS_LAMBDA_FUNCTION_VERSION": "$LATEST",
                                       "AWS_LAMBDA_LOG_GROUP_NAME": "/aws/lambda/Lambda",
                                       "AWS_LAMBDA_LOG_STREAM_NAME": "2019/09/08/[$LATEST]000023faf4eb46fda06507e07c100000",
                                       "AWS_LAMBDA_FUNCTION_MEMORY_SIZE": "128",
                                       "AWS_REGION": "eu-west-1",
                                       "AWS_EXECUTION_ENV": "EXECUTION_ENV",
                                       "AWS_SECRET_ACCESS_KEY": "secret-ket",
                                       "AWS_SESSION_TOKEN": "session-token",
                                       "AWS_ACCESS_KEY_ID": "access-key-id",
                                       "LANG": "en_US.UTF-8",
                                       "TZ": ":UTC",
                                       "LAMBDA_TASK_ROOT": "/var/task",
                                       "LAMBDA_RUNTIME_DIR": "/var/runtime",
                                       "PATH": "/usr/local/bin:/usr/bin/:/bin:/opt/bin",
                                       "LD_LIBRARY_PATH": "/lib64:/usr/lib64:/var/runtime:/var/runtime/lib:/var/task:/var/task/lib:/opt/lib",
                                       "NODE_PATH": "",
                                       "PYTHONPATH": "",
                                       "GEM_PATH": "",
                                       "_X_AMZN_TRACE_ID": ""]

    static let invalidEnvironmentMissingFunctionName = ["AWS_LAMBDA_RUNTIME_API": "runtime",
                                                        "_HANDLER": "Lambda.handler",
                                                        "AWS_LAMBDA_FUNCTION_VERSION": "$LATEST",
                                                        "AWS_LAMBDA_LOG_GROUP_NAME": "/aws/lambda/Lambda",
                                                        "AWS_LAMBDA_LOG_STREAM_NAME": "2019/09/08/[$LATEST]000023faf4eb46fda06507e07c100000",
                                                        "AWS_LAMBDA_FUNCTION_MEMORY_SIZE": "128"]

    static let validEnvironmentWithXRay = ["AWS_LAMBDA_RUNTIME_API": "runtime",
                                           "_HANDLER": "Lambda.handler",
                                           "AWS_LAMBDA_FUNCTION_NAME": "Lambda",
                                           "AWS_LAMBDA_FUNCTION_VERSION": "$LATEST",
                                           "AWS_LAMBDA_LOG_GROUP_NAME": "/aws/lambda/Lambda",
                                           "AWS_LAMBDA_LOG_STREAM_NAME": "2019/09/08/[$LATEST]000023faf4eb46fda06507e07c100000",
                                           "AWS_LAMBDA_FUNCTION_MEMORY_SIZE": "128",
                                           "_X_AMZN_TRACE_ID": "trace-id"]

    static let validJSONDictionary: [String: Any] = ["string": "Name",
                                                     "int": 1,
                                                     "float": 0.9,
                                                     "dictionary": ["name": "N",
                                                                    "value": 10]]

    static let validJSON = "{\"dictionary\":{\"name\":\"N\",\"value\":10},\"float\":0.9,\"string\":\"Name\",\"int\":1}"

    static let invalidJSON = "{\"dictionary\":{\"name\":\"N\",\"value\":10},\"float\":0.9,\"string\"}"
}
