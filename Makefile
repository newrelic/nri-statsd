PROJECT_WORKSPACE	?= $(CURDIR)
DOCKER_IMAGE_NAME	?= newrelic/nri-statsd
DOCKER_IMAGE_TAG	?= test   
GOSTATSD_TAG		?= 35.2.1
BASE_IMAGE_TAG		?= 3.18
TEST_IMAGE_TAG		?= 1.20.6-alpine3.18

DOCKER_BUILD_CMD	?= docker build --pull \
					--no-cache \
					-t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) \
					--build-arg BASE_IMAGE_TAG=$(BASE_IMAGE_TAG) \
					--build-arg GOSTATSD_TAG=$(GOSTATSD_TAG) \
					.

DOCKER_TEST_CMD		?= docker run -i \
					-v $(HOME)/.docker/:/root/.docker/ \
					-v /var/run/docker.sock:/var/run/docker.sock \
					-v $(PROJECT_WORKSPACE):/nri-statsd \
					-w /nri-statsd/tests/integration \
					--add-host host.docker.internal:host-gateway \
					-p "8081:8081" \
					-e CGO_ENABLED=0 \
					-e DOCKER_DEFAULT_PLATFORM=linux/$(ARCH) \
					-e "TC_HOST=host.docker.internal" \
					golang:$(TEST_IMAGE_TAG) \
					sh -c 'go clean -testcache && go test -v .'

buildTargetArch=$(word 2,$(subst -, ,$@))

.PHONY : docker-%
docker-% : export ARCH=$(call buildTargetArch, $@)
docker-% :
	@printf '\n================================================================\n'
	@printf 'Target: $@\n'
	@printf '\n================================================================\n'
	@DOCKER_DEFAULT_PLATFORM=linux/$(ARCH) $(DOCKER_BUILD_CMD)

.PHONY : build/docker-amd64
build/docker-amd64:
	@$(MAKE) docker-amd64

.PHONY : build/docker-arm64
build/docker-arm64:
	@$(MAKE) docker-arm64

.PHONY : tests-%
tests-% : export ARCH=$(call buildTargetArch, $@)
tests-% : 
	@printf '\n================================================================\n'
	@printf 'Target: $@\n'
	@printf '\n================================================================\n'
	@$(DOCKER_TEST_CMD)

.PHONY : integration-tests-amd64
integration-tests-amd64: build/docker-amd64
	@$(MAKE) tests-amd64

.PHONY : integration-tests-arm64
integration-tests-arm64: build/docker-arm64
	@$(MAKE) tests-arm64
