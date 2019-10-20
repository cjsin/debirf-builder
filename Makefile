SOURCES   := $(shell find . -mindepth 1 -maxdepth 1 -type f -not -iname ".*")
VERSION   := $(shell date +%Y%m%d-%H%M%S)
TAG       := debirf-builder

# Uncomment/edit if you have a local apt-cacher-ng instance.
# Comment it out if you don't
APT_PROXY := http://172.17.0.1:3142

APT_REPOS := main contrib non-free
EXTRAS    := $(shell egrep -v '^\#' builder-extras )
PACKAGES  := $(shell egrep -v "^\#" builder-packages) $(EXTRAS)

ARGS      := --build-arg APT_PROXY="$(APT_PROXY)" \
             --build-arg APT_REPOS="$(APT_REPOS)" \
             --build-arg PACKAGES="$(PACKAGES)"
BUILD     := DOCKER_BUILDKIT=1 docker build $(ARGS)

.PHONY: all base user clean

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

.user: .base Dockerfile.user
	make user

clean:
	rm -f .user .base
