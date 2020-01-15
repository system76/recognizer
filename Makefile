#!/usr/bin/make -f

SHELL                   := /usr/bin/env bash
REPO_NAMESPACE          ?= system76
AWS_DEFAULT_REGION      ?= us-west-2
IMAGE_NAME              ?= recognizer
BASE_IMAGE              ?= alpine:3.10
VERSION                 := $(shell git describe --tags --abbrev=0 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null)
VCS_REF                 := $(shell git rev-parse --short HEAD 2>/dev/null || echo "0000000")
BUILD_DATE              := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Default target is to build container
.PHONY: default
default: build

# Build the docker image
.PHONY: build
build:
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VCS_REF=$(VCS_REF) \
		--build-arg VERSION=$(VERSION) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):latest \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VCS_REF) \
		--tag $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION) \
		--file Dockerfile .

# List built images
.PHONY: list
list:
	docker images $(REPO_NAMESPACE)/$(IMAGE_NAME) --filter "dangling=false"

# Run any tests
.PHONY: test
test:
	docker run -t $(REPO_NAMESPACE)/$(IMAGE_NAME) env | grep VERSION | grep $(VERSION)

# Push images to repo
.PHONY: push
push:
	export AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID_PERSONAL); \
		export AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY_PERSONAL); \
		export AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION); \
		$$(aws ecr get-login --no-include-email --region $$AWS_DEFAULT_REGION); \
		docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):latest; \
		docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VCS_REF); \
		docker push  $(REPO_NAMESPACE)/$(IMAGE_NAME):$(VERSION);

# Remove existing images
.PHONY: clean
clean:
	docker rmi $$(docker images $(REPO_NAMESPACE)/$(IMAGE_NAME) --format="{{.Repository}}:{{.Tag}}") --force
