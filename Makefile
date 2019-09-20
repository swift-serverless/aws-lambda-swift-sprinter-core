SWIFT_DOCKER_IMAGE=swift:latest

swift_test:
	docker run \
			--rm \
			--volume "$(shell pwd)/:/src" \
			--workdir "/src/" \
			$(SWIFT_DOCKER_IMAGE) \
			swift test