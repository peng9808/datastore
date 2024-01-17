include Makefile.variables

.PHONY: debug
debug:
	${DOCKER_DEBUG_CMD} ash

.PHONY: unit-test
unit-test:
	go test -race -coverprofile=coverage.txt -covermode=atomic `go list ./pkg/... | grep -v -E './pkg/local-storage/member|./pkg/scheduler|./pkg/evictor|./pkg/apiserver'`
	curl -s https://codecov.io/bash | bash

.PHONY: vendor
vendor:
	go mod tidy -compat=1.18
	go mod vendor

#### for METADATA_CONTROLLER #########
METADATA_CONTROLLER_MODULE_NAME = metadata-controller
METADATA_CONTROLLER_BUILD_INPUT = ${CMDS_DIR}/${METADATA_CONTROLLER_MODULE_NAME}/main.go

.PHONY: compile_metadata_controller
compile_metadata_controller:
	GOARCH=amd64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${METADATA_CONTROLLER_BUILD_OUTPUT} ${METADATA_CONTROLLER_BUILD_INPUT}

.PHONY: compile_metadata_controller_arm64
compile_metadata_controller_arm64:
	GOARCH=arm64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${METADATA_CONTROLLER_BUILD_OUTPUT} ${METADATA_CONTROLLER_BUILD_INPUT}

.PHONY: build_metadata_controller_image
build_metadata_controller_image:
	@echo "Build metadata-controller image ${METADATA_CONTROLLER_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_metadata_controller
	docker build -t ${METADATA_CONTROLLER_IMAGE_NAME}:${IMAGE_TAG} -f ${METADATA_CONTROLLER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_metadata_controller_image_arm64
build_metadata_controller_image_arm64:
	@echo "Build metadata-controller image ${METADATA_CONTROLLER_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_metadata_controller_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${METADATA_CONTROLLER_IMAGE_NAME}:${IMAGE_TAG} -f ${METADATA_CONTROLLER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: release_metadata_controller
release_metadata_controller:
	# build for amd64 version
	${DOCKER_MAKE_CMD} make compile_metadata_controller
	${DOCKER_BUILDX_CMD_AMD64} -t ${METADATA_CONTROLLER_IMAGE_NAME}:${RELEASE_TAG}-amd64 -f ${METADATA_CONTROLLER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# build for arm64 version
	${DOCKER_MAKE_CMD} make compile_metadata_controller_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${METADATA_CONTROLLER_IMAGE_NAME}:${RELEASE_TAG}-arm64 -f ${METADATA_CONTROLLER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# push to a public registry
	${MUILT_ARCH_PUSH_CMD} -i ${METADATA_CONTROLLER_IMAGE_NAME}:${RELEASE_TAG}



.PHONY: apis
apis:
	${DOCKER_MAKE_CMD} make _gen-apis

.PHONY: builder
builder:
	docker build -t ${BUILDER_NAME}:${BUILDER_TAG} -f ${BUILDER_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	docker push ${BUILDER_NAME}:${BUILDER_TAG}

.PHONY: _gen-apis
_gen-apis:
	${OPERATOR_CMD} generate k8s
	${OPERATOR_CMD} generate crds
	GOPROXY=https://goproxy.cn,direct /code-generator/generate-groups.sh all github.com/hwameistor/datastore/pkg/apis/client github.com/hwameistor/datastore/pkg/apis "datastore:v1alpha1" --go-header-file /go/src/github.com/hwameistor/datastore/build/boilerplate.go.txt
