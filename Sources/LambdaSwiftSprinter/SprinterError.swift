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
