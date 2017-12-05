SHELL := /bin/bash

COMMIT = $(shell git rev-parse --verify --short HEAD)
VERSION = $(shell git describe --tags --dirty='+dev' 2> /dev/null)
LDFLAGS = -w -X main.commit=$(COMMIT) -X main.version=$(VERSION)
XBUILD = go build -a -tags netgo -ldflags '$(LDFLAGS)'
RELEASE_DIR = bin/$(VERSION)

dependencies:
	glide install --strip-vendor

build:
	go build -o bin/svcat ./cmd/svcat

linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(XBUILD) -o $(RELEASE_DIR)/Linux/x86_64/svcat ./cmd/svcat
	cd $(RELEASE_DIR)/Linux/x86_64 && shasum -a 256 svcat > svcat.sha256

darwin:
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 $(XBUILD) -o $(RELEASE_DIR)/Darwin/x86_64/svcat ./cmd/svcat
	cd $(RELEASE_DIR)/Darwin/x86_64 && shasum -a 256 svcat > svcat.sha256

windows:
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 $(XBUILD) -o $(RELEASE_DIR)/Windows/x86_64/svcat.exe ./cmd/svcat
	cd $(RELEASE_DIR)/Windows/x86_64 && shasum -a 256 svcat.exe > svcat.exe.sha256

cross-build: linux darwin windows

test:
	go test $$(glide nv)

deploy: clean cross-build
	cp -R $(RELEASE_DIR) bin/latest/
	# AZURE_STORAGE_CONNECTION_STRING will be used for auth in the following command
	az storage blob upload-batch -d cli -s bin

clean:
	-rm -r bin
