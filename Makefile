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

.PHONY: compile
compile: compile_metadata_controller compile_datamanager

.PHONY: build
build: build_metadata_controller_image build_datamanager_image

.PHONY: run
run: run_datamanager

#### for METADATA_CONTROLLER #########
METADATA_CONTROLLER_MODULE_NAME = metadata-controller
METADATA_CONTROLLER_BUILD_INPUT = ${CMDS_DIR}/${METADATA_CONTROLLER_MODULE_NAME}/main.go
.PHONY: run_metadata_controller
run_metadata_controller:
	go run ${BUILD_OPTIONS} ${METADATA_CONTROLLER_BUILD_INPUT}

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


#### for DATAMANAGER #########
DATAMANAGER_MODULE_NAME = datamanager
DATAMANAGER_BUILD_INPUT = ${CMDS_DIR}/${DATAMANAGER_MODULE_NAME}/main.go
.PHONY: run_datamanager
run_datamanager:
	go run ${BUILD_OPTIONS} ${DATAMANAGER_BUILD_INPUT} --isTrainMaster=false --isInitRole=true --baseModelLocalDir=/Users/liangsun/Workspace/projects/golang/src/github.com/hwameistor/datastore/_build/models --checkpointLocalDir=/Users/liangsun/Workspace/projects/golang/src/github.com/hwameistor/datastore/_build/checkpoints --checkpointLocalDirOnHost=/Users/liangsun/Downloads/checkpoints --trainingdataLocalDir=/Users/liangsun/Workspace/projects/golang/src/github.com/hwameistor/datastore/_build/training --trainingdataLocalDirOnHost=/Users/liangsun/Downloads/training

.PHONY: compile_datamanager
compile_datamanager:
	GOARCH=amd64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${DATAMANAGER_BUILD_OUTPUT} ${DATAMANAGER_BUILD_INPUT}

.PHONY: compile_datamanager_arm64
compile_datamanager_arm64:
	GOARCH=arm64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${DATAMANAGER_BUILD_OUTPUT} ${DATAMANAGER_BUILD_INPUT}

.PHONY: build_datamanager_image
build_datamanager_image:
	@echo "Build datamanager image ${DATAMANAGER_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_datamanager
	${DOCKER_BUILDX_CMD_AMD64} -t ${DATAMANAGER_IMAGE_NAME}:${IMAGE_TAG} -f ${DATAMANAGER_IMAGE_DOCKERFILE}.amd64 ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_datamanager_image_arm64
build_datamanager_image_arm64:
	@echo "Build datamanager image ${DATAMANAGER_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_datamanager_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${DATAMANAGER_IMAGE_NAME}:${IMAGE_TAG} -f ${DATAMANAGER_IMAGE_DOCKERFILE}.arm64 ${PROJECT_SOURCE_CODE_DIR}

.PHONY: release_datamanager
release_datamanager:
	# build for amd64 version
	${DOCKER_MAKE_CMD} make compile_datamanager
	${DOCKER_BUILDX_CMD_AMD64} -t ${DATAMANAGER_IMAGE_NAME}:${RELEASE_TAG}-amd64 -f ${DATAMANAGER_IMAGE_DOCKERFILE}.amd64 ${PROJECT_SOURCE_CODE_DIR}
	# build for arm64 version
	${DOCKER_MAKE_CMD} make compile_datamanager_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${DATAMANAGER_IMAGE_NAME}:${RELEASE_TAG}-arm64 -f ${DATAMANAGER_IMAGE_DOCKERFILE}.arm64 ${PROJECT_SOURCE_CODE_DIR}
	# push to a public registry
	${MUILT_ARCH_PUSH_CMD} -i ${DATAMANAGER_IMAGE_NAME}:${RELEASE_TAG}



#### for DATALOAD-MANAGER #########
DATALOAD_MANAGER_MODULE_NAME = dataload-manager
DATALOAD_MANAGER_BUILD_INPUT = ${CMDS_DIR}/${DATALOAD_MANAGER_MODULE_NAME}/main.go
.PHONY: run_dataload_manager
run_dataload_manager:
	go run ${BUILD_OPTIONS} ${DATALOAD_MANAGER_BUILD_INPUT} --isTrainMaster=false --isInitRole=true --baseModelLocalDir=/Users/liangsun/Workspace/projects/golang/src/github.com/hwameistor/datastore/_build/models --checkpointLocalDir=/Users/liangsun/Workspace/projects/golang/src/github.com/hwameistor/datastore/_build/checkpoints --checkpointLocalDirOnHost=/Users/liangsun/Downloads/checkpoints --trainingdataLocalDir=/Users/liangsun/Workspace/projects/golang/src/github.com/hwameistor/datastore/_build/training --trainingdataLocalDirOnHost=/Users/liangsun/Downloads/training

.PHONY: compile_dataload_manager
compile_dataload_manager:
	GOARCH=amd64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${DATALOAD_MANAGER_BUILD_OUTPUT} ${DATALOAD_MANAGER_BUILD_INPUT}

.PHONY: compile_dataload_manager_arm64
compile_dataload_manager_arm64:
	GOARCH=arm64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${DATALOAD_MANAGER_BUILD_OUTPUT} ${DATALOAD_MANAGER_BUILD_INPUT}

.PHONY: build_dataload_manager_image
build_dataload_manager_image:
	@echo "Build dataload_manager image ${DATALOAD_MANAGER_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_dataload_manager
	${DOCKER_BUILDX_CMD_AMD64} -t ${DATALOAD_MANAGER_IMAGE_NAME}:${IMAGE_TAG} -f ${DATALOAD_MANAGER_IMAGE_DOCKERFILE}.amd64 ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_dataload_manager_image_arm64
build_dataload_manager_image_arm64:
	@echo "Build dataload_manager image ${DATALOAD_MANAGER_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_dataload_manager_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${DATALOAD_MANAGER_IMAGE_NAME}:${IMAGE_TAG} -f ${DATALOAD_MANAGER_IMAGE_DOCKERFILE}.arm64 ${PROJECT_SOURCE_CODE_DIR}

.PHONY: release_dataload_manager
release_dataload_manager:
	# build for amd64 version
	${DOCKER_MAKE_CMD} make compile_dataload_manager
	${DOCKER_BUILDX_CMD_AMD64} -t ${DATALOAD_MANAGER_IMAGE_NAME}:${RELEASE_TAG}-amd64 -f ${DATALOAD_MANAGER_IMAGE_DOCKERFILE}.amd64 ${PROJECT_SOURCE_CODE_DIR}
	# build for arm64 version
	${DOCKER_MAKE_CMD} make compile_dataload_manager_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${DATALOAD_MANAGER_IMAGE_NAME}:${RELEASE_TAG}-arm64 -f ${DATALOAD_MANAGER_IMAGE_DOCKERFILE}.arm64 ${PROJECT_SOURCE_CODE_DIR}
	# push to a public registry
	${MUILT_ARCH_PUSH_CMD} -i ${DATALOAD_MANAGER_IMAGE_NAME}:${RELEASE_TAG}

#### for DATALOAD-INIT #########
DATALOAD_INIT_MODULE_NAME = dataload-init
DATALOAD_INIT_BUILD_INPUT = ${CMDS_DIR}/${DATALOAD_INIT_MODULE_NAME}/main.go
.PHONY: run_dataload_init
run_dataload_init:
	go run ${BUILD_OPTIONS} ${DATALOAD_INIT_BUILD_INPUT} --isTrainMaster=false --isInitRole=true --baseModelLocalDir=/Users/liangsun/Workspace/projects/golang/src/github.com/hwameistor/datastore/_build/models --checkpointLocalDir=/Users/liangsun/Workspace/projects/golang/src/github.com/hwameistor/datastore/_build/checkpoints --checkpointLocalDirOnHost=/Users/liangsun/Downloads/checkpoints --trainingdataLocalDir=/Users/liangsun/Workspace/projects/golang/src/github.com/hwameistor/datastore/_build/training --trainingdataLocalDirOnHost=/Users/liangsun/Downloads/training

.PHONY: compile_dataload_init
compile_dataload_init:
	GOARCH=amd64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${DATALOAD_INIT_BUILD_OUTPUT} ${DATALOAD_INIT_BUILD_INPUT}

.PHONY: compile_dataload_init_arm64
compile_dataload_init_arm64:
	GOARCH=arm64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${DATALOAD_INIT_BUILD_OUTPUT} ${DATALOAD_INIT_BUILD_INPUT}

.PHONY: build_dataload_init_image
build_dataload_init_image:
	@echo "Build dataload_init image ${DATALOAD_INIT_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_dataload_init
	${DOCKER_BUILDX_CMD_AMD64} -t ${DATALOAD_INIT_IMAGE_NAME}:${IMAGE_TAG} -f ${DATALOAD_INIT_IMAGE_DOCKERFILE}.amd64 ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_dataload_init_image_arm64
build_dataload_init_image_arm64:
	@echo "Build dataload_init_arm64 image ${DATALOAD_INIT_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_dataload_init_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${DATALOAD_INIT_IMAGE_NAME}:${IMAGE_TAG} -f ${DATALOAD_INIT_IMAGE_DOCKERFILE}.arm64 ${PROJECT_SOURCE_CODE_DIR}

.PHONY: release_dataload_init
release_dataload_init:
	# build for amd64 version
	${DOCKER_MAKE_CMD} make compile_dataload_init
	${DOCKER_BUILDX_CMD_AMD64} -t ${DATALOAD_INIT_IMAGE_NAME}:${RELEASE_TAG}-amd64 -f ${DATALOAD_INIT_IMAGE_DOCKERFILE}.amd64 ${PROJECT_SOURCE_CODE_DIR}
	# build for arm64 version
	${DOCKER_MAKE_CMD} make compile_dataload_init_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${DATALOAD_INIT_IMAGE_NAME}:${RELEASE_TAG}-arm64 -f ${DATALOAD_INIT_IMAGE_DOCKERFILE}.arm64 ${PROJECT_SOURCE_CODE_DIR}
	# push to a public registry
	${MUILT_ARCH_PUSH_CMD} -i ${DATALOAD_INIT_IMAGE_NAME}:${RELEASE_TAG}

#### for Dataset Manager controller ##########
DS_ACCL_CONTROLLER_MODULE_NAME = dataset-manager
DS_ACCL_CONTROLLER_BUILD_INPUT = ${CMDS_DIR}/${DS_ACCL_CONTROLLER_MODULE_NAME}/dataset-manager.go

.PHONY: compile_ds_accl
compile_ds_accl:
	GOARCH=amd64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${DS_ACCL_CONTROLLER_BUILD_OUTPUT} ${DS_ACCL_CONTROLLER_BUILD_INPUT}

.PHONY: compile_ds_accl_arm64
compile_ds_accl_arm64:
	GOARCH=arm64 ${BUILD_ENVS} ${BUILD_CMD} ${BUILD_OPTIONS} -o ${DS_ACCL_CONTROLLER_BUILD_OUTPUT} ${DS_ACCL_CONTROLLER_BUILD_INPUT}

.PHONY: build_ds_accl_image
build_ds_accl_image:
	@echo "Build dataset-manager-controller image ${DS_ACCL_CONTROLLER_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_ds_accl
	docker build -t ${DS_ACCL_CONTROLLER_IMAGE_NAME}:${IMAGE_TAG} -f ${DS_ACCL_CONTROLLER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: build_ds_accl_image_arm64
build_ds_accl_image_arm64:
	@echo "Build dataset-manager-controller image ${DS_ACCL_CONTROLLER_IMAGE_NAME}:${IMAGE_TAG}"
	${DOCKER_MAKE_CMD} make compile_ds_accl_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${DS_ACCL_CONTROLLER_IMAGE_NAME}:${IMAGE_TAG} -f ${DS_ACCL_CONTROLLER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}

.PHONY: release_ds_accl
release_ds_accl:
	# build for amd64 version
	${DOCKER_MAKE_CMD} make compile_ds_accl
	${DOCKER_BUILDX_CMD_AMD64} -t ${DS_ACCL_CONTROLLER_IMAGE_NAME}:${RELEASE_TAG}-amd64 -f ${DS_ACCL_CONTROLLER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# build for arm64 version
	${DOCKER_MAKE_CMD} make compile_ds_accl_arm64
	${DOCKER_BUILDX_CMD_ARM64} -t ${DS_ACCL_CONTROLLER_IMAGE_NAME}:${RELEASE_TAG}-arm64 -f ${DS_ACCL_CONTROLLER_IMAGE_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	# push to a public registry
	${MUILT_ARCH_PUSH_CMD} -i ${DS_ACCL_CONTROLLER_IMAGE_NAME}:${RELEASE_TAG}

.PHONY: apis
apis:
	${DOCKER_MAKE_CMD} make _gen-apis

.PHONY: builder
builder:
	${DOCKER_BUILDX_CMD_AMD64} -t ${BUILDER_NAME}:${BUILDER_TAG} -f ${BUILDER_DOCKERFILE} ${PROJECT_SOURCE_CODE_DIR}
	docker push ${BUILDER_NAME}:${BUILDER_TAG}

.PHONY: juicesync
juicesync:
	${DOCKER_BUILDX_CMD_AMD64} -t ${JUICESYNC_NAME}:${JUICESYNC_TAG}-amd64 -f ${JUICESYNC_DOCKERFILE}.amd64 ${PROJECT_SOURCE_CODE_DIR}
	# build for arm64 version
	${DOCKER_BUILDX_CMD_ARM64} -t ${JUICESYNC_NAME}:${JUICESYNC_TAG}-arm64 -f ${JUICESYNC_DOCKERFILE}.arm64 ${PROJECT_SOURCE_CODE_DIR}
	# push to a public registry
	${MUILT_ARCH_PUSH_CMD} -i ${JUICESYNC_NAME}:${JUICESYNC_TAG}


.PHONY: _gen-apis
_gen-apis:
	${OPERATOR_CMD} generate k8s
	${OPERATOR_CMD} generate crds
	GOPROXY=https://goproxy.cn,direct /code-generator/generate-groups.sh all github.com/hwameistor/datastore/pkg/apis/client github.com/hwameistor/datastore/pkg/apis "datastore:v1alpha1" --go-header-file /go/src/github.com/hwameistor/datastore/build/boilerplate.go.txt

.PHONY: release
release: release_dataload_init release_dataload_manager release_ds_accl

