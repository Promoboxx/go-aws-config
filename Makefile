SERVICE ?= go-aws-config
REGISTRY ?= pbxx
COMMIT = $(shell git rev-parse --short HEAD 2>/dev/null)
LDFLAGS ?=
DOCKER_BUILD_ARGS ?=

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: analyze
analyze: fmt lint vet test ## run fmt, lint, vet, and test

.PHONY: build
build: build-linux ## run go build for linux

.PHONY: build-linux
build-linux: 
	GOOS=linux GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o bin/app src/main/*.go

.PHONY: build-native
build-native: ## run go build for current OS
	go build -ldflags "$(LDFLAGS)" -o bin/app src/main/*.go

.PHONY: docker-build
docker-build: ## build docker image
	docker build -t $(REGISTRY)/$(SERVICE):$(COMMIT) $(DOCKER_BUILD_ARGS) .

.PHONY: docker-push
docker-push: ## push docker image to Docker Hub
	docker push $(REGISTRY)/$(SERVICE):$(COMMIT)

.PHONY: fmt
fmt: ## verify all files have been `gofmt`ed.
	@gofmt -s -l . | grep -v vendor | tee /dev/stderr

.PHONY: generate
generate: ## runs go generate to create mocks or any other automatically generated code
	go generate ./...

.PHONY: lint
lint: ## verify `golint` passes.
	@golint ./... | grep -v vendor | tee /dev/stderr

.PHONY: logs
logs: ## get the logs of a service ex `make logs service_name=<my_service_name>`
	docker-compose logs $(service_name)

.PHONY: test
test: ## run the go tests.
	@go test -v -cover -race $(shell go list ./... | grep -v vendor)

.PHONY: vendor
vendor: ## starts a docker container with a fresh env to run govendor in
	docker run -v $(GOPATH)/src:/go/src/ --name govendor -it --rm govendor-build

.PHONY: vendor-missing
vendor-missing: ## updates your project to get all missing dependencies
	docker run -v $(GOPATH)/src:/go/src/ --name govendor --rm \
	-w /go/src/github.com/promoboxx/go-aws-config --entrypoint='govendor' \
	-it pbxx/govendor fetch +outside

.PHONY: vet
vet: ## verify `go vet` passes.
	@go vet $(shell go list ./... | grep -v vendor) | tee /dev/stderr