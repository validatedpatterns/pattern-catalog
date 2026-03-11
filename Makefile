VERSION ?= 0.0.4
SUPPORTED_OCP_VERSIONS ?= v4.20-v4.21
REGISTRY ?= localhost
UPLOADREGISTRY ?= quay.io/validatedpatterns

# Image base URL of the pattern catalog
PATTERN_CATALOG_IMAGE_BASE ?= $(UPLOADREGISTRY)/pattern-catalog
PATTERN_CATALOG_IMAGE ?= $(PATTERN_CATALOG_IMAGE_BASE):$(VERSION)
PATTERN_CATALOG_DOCKERFILE ?= pattern-catalog.Dockerfile

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-40s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Pattern Catalog

.PHONY: generate-catalog
generate-catalog: ## Generates actual catalog yaml tree
	./generate-catalog.sh

# Generate Dockerfile for pattern catalog using the template
.PHONY: generate-dockerfile
generate-dockerfile: ## Generate Dockerfile from template
	VERSION=$(VERSION) SUPPORTED_OCP_VERSIONS=$(SUPPORTED_OCP_VERSIONS) envsubst < templates/pattern-catalog.Dockerfile.template > $(PATTERN_CATALOG_DOCKERFILE)

.PHONY: pattern-catalog-build
pattern-catalog-build: generate-dockerfile## Build the pattern catalog image
	@echo "Building pattern catalog image..."
	@podman pull $(PATTERN_CATALOG_IMAGE_BASE):latest 2>/dev/null || true
	podman build -f $(PATTERN_CATALOG_DOCKERFILE) -t ${PATTERN_CATALOG_IMAGE} .
	podman tag ${PATTERN_CATALOG_IMAGE} $(PATTERN_CATALOG_IMAGE_BASE):latest

.PHONY: pattern-catalog-push
pattern-catalog-push: ## Push the pattern catalog image
	podman push $(PATTERN_CATALOG_IMAGE)
