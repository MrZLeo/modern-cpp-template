.PHONY: configure build test headers coverage docs install format help
.DEFAULT_GOAL := help

BUILD_DIR ?= build
BUILD_TYPE ?= Debug
INSTALL_LOCATION ?= $(HOME)/.local
PROJECT_NAME ?= Project
CMAKE_FLAGS ?=

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "%-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

configure: ## Configure without deleting an existing build tree
	cmake -G Ninja -S . -B "$(BUILD_DIR)" -DCMAKE_BUILD_TYPE="$(BUILD_TYPE)" $(CMAKE_FLAGS)

build: configure ## Build the configured targets
	cmake --build "$(BUILD_DIR)" --parallel

test: build ## Run unit tests
	ctest --test-dir "$(BUILD_DIR)" --output-on-failure --no-tests=error

headers: configure ## Verify public, private and generated header sets
	cmake --build "$(BUILD_DIR)" --target all_verify_header_sets --parallel

coverage: ## Build and test with coverage in a separate directory
	cmake -G Ninja -S . -B "$(BUILD_DIR)-coverage" -DCMAKE_BUILD_TYPE=Debug $(CMAKE_FLAGS) -D$(PROJECT_NAME)_ENABLE_UNIT_TESTING=ON -D$(PROJECT_NAME)_ENABLE_CODE_COVERAGE=ON
	cmake --build "$(BUILD_DIR)-coverage" --parallel
	ctest --test-dir "$(BUILD_DIR)-coverage" --output-on-failure --no-tests=error
	@echo "Coverage data is in $(BUILD_DIR)-coverage; use gcovr with GCC or llvm-cov gcov with Clang."

docs: ## Generate Doxygen documentation in a separate build tree
	cmake -G Ninja -S . -B "$(BUILD_DIR)-docs" $(CMAKE_FLAGS) -D$(PROJECT_NAME)_ENABLE_UNIT_TESTING=OFF -D$(PROJECT_NAME)_ENABLE_DOXYGEN=ON
	cmake --build "$(BUILD_DIR)-docs" --target doxygen-docs

install: build ## Install the library and optional application
	cmake --install "$(BUILD_DIR)" --prefix "$(INSTALL_LOCATION)"

format: configure ## Format owned sources, excluding dependencies and generated files
	cmake --build "$(BUILD_DIR)" --target clang-format
