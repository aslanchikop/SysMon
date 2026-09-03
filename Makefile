.PHONY: build build-linux build-windows test vet clean run

BINARY_NAME=sysmon
CMD_DIR=./cmd/sysmon

all: build-linux build-windows

build:
	CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/$(BINARY_NAME) $(CMD_DIR)

build-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o bin/$(BINARY_NAME)-linux-amd64 $(CMD_DIR)

build-windows:
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o bin/$(BINARY_NAME)-windows-amd64.exe $(CMD_DIR)

test:
	go test -v ./...

vet:
	go vet ./...

clean:
	rm -rf bin/ $(BINARY_NAME) sysmon_alerts.log

run: build
	./bin/$(BINARY_NAME)
