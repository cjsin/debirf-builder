SOURCES   := $(shell find . -type f)
VERSION   := $(shell date +%Y%m%d-%H%M%S)
TAG       := debirf-builder
APT_PROXY := http://172.17.0.1:3142
APT_REPOS := main contrib non-free
EXTRAS    := $(shell egrep -v '^\#' builder-extras )
PACKAGES  := $(shell egrep -v "^\#" builder-packages) $(EXTRAS)

ARGS      := --build-arg APT_PROXY="$(APT_PROXY)" \
             --build-arg APT_REPOS="$(APT_REPOS)" \
             --build-arg PACKAGES="$(PACKAGES)"
BUILD     := DOCKER_BUILDKIT=1 docker build $(ARGS)

.PHONY: all base user

all: .base .user

base:
	$(BUILD) --tag $(TAG)-$@:$(VERSION) -f Dockerfile.base .
	docker tag $(TAG)-$@:$(VERSION) $(TAG)-$@:latest
	touch .base

user:
	$(BUILD) --tag $(TAG)-$@:$(VERSION) -f Dockerfile.user .
	docker tag $(TAG)-$@:$(VERSION) $(TAG)-$@:latest
	touch .user

.base: $(SOURCES) builder-packages builder-extras Dockerfile.base
	make base

.user: base Dockerfile.user
	make user
