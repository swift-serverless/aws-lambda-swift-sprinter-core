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
			swift test  --enable-code-coverage