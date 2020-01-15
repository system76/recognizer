#!/usr/bin/make -f

SHELL                   := /usr/bin/env bash
IMAGE_URL               ?= system76/recognizer
AWS_DEFAULT_REGION      ?= us-east-2
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
		--tag $(IMAGE_URL):latest \
		--tag $(IMAGE_URL):$(VCS_REF) \
		--tag $(IMAGE_URL):$(VERSION) \
		--file Dockerfile .

# List built images
.PHONY: list
list:
	docker images $(IMAGE_URL) --filter "dangling=false"

# Run any tests
.PHONY: test
test:
	docker run -t $(IMAGE_URL) env | grep VERSION | grep $(VERSION)

# Push images to repo
.PHONY: push
push:
	export AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION); \
	  $$(aws ecr get-login --no-include-email --region $$AWS_DEFAULT_REGION); \
		docker push $(IMAGE_URL):latest; \
		docker push $(IMAGE_URL):$(VCS_REF); \
		docker push $(IMAGE_URL):$(VERSION);

# Remove existing images
.PHONY: clean
clean:
	docker rmi $$(docker images $(IMAGE_URL) --format="{{.Repository}}:{{.Tag}}") --force
