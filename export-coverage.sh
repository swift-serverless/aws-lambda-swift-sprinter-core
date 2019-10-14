llvm-cov export -instr-profile=.build/x86_64-unknown-linux/debug/codecov/default.profdata -format=lcov \
 -object .build/x86_64-unknown-linux/debug/LambdaSwiftSprinter.build/Context.swift.o \
 -object .build/x86_64-unknown-linux/debug/LambdaSwiftSprinter.build/Data+Extensions.swift.o \
 -object .build/x86_64-unknown-linux/debug/LambdaSwiftSprinter.build/LambdaAPI.swift.o \
 -object .build/x86_64-unknown-linux/debug/LambdaSwiftSprinter.build/LambdaApiCURL.swift.o \
 -object .build/x86_64-unknown-linux/debug/LambdaSwiftSprinter.build/LambdaHandler+Extensions.swift.o \
 -object .build/x86_64-unknown-linux/debug/LambdaSwiftSprinter.build/LambdaHandler.swift.o \
 -object .build/x86_64-unknown-linux/debug/LambdaSwiftSprinter.build/LambdaRuntimeAPIUrlBuilder.swift.o \
 -object .build/x86_64-unknown-linux/debug/LambdaSwiftSprinter.build/Sprinter.swift.o > .build/x86_64-unknown-linux/debug/codecov/lcov.info