SWIFT_VERSION?=5.1.1

DOCKER_TAG=nio-swift:$(SWIFT_VERSION)
SWIFT_DOCKER_IMAGE=$(DOCKER_TAG)

docker_build:
	docker build --tag $(DOCKER_TAG) docker/$(SWIFT_VERSION)/.

swift_test_with_coverage:
	docker run \
			--rm \
			--volume "$(shell pwd)/:/src" \
			--workdir "/src/" \
			$(SWIFT_DOCKER_IMAGE) \
			/bin/bash -c "swift test --enable-code-coverage && llvm-cov export .build/x86_64-unknown-linux/debug/LambdaSwiftSprinter.build/*.o -instr-profile=.build/x86_64-unknown-linux/debug/codecov/default.profdata -format=lcov > .build/x86_64-unknown-linux/debug/codecov/lcov.info"