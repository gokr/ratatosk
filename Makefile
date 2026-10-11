# Ratatosk: build, test, run.
#
# The front door for both halves: a Go server and a Flutter client that meet on
# one Protobuf contract.
SHELL := /bin/bash
.DEFAULT_GOAL := help

GO           ?= go
FLUTTER      ?= flutter
BUF          ?= buf
SERVER_DIR   := server
APP_DIR      := app
BIN          := var/bin
DATA         ?= var/data
ADDR         ?= :8080
PUBLIC_URL   ?= http://localhost:8080
WEB_DIR      := $(APP_DIR)/build/web
# The address the client's interop tests talk to.
TEST_URL     ?= http://localhost:8080

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

# --- code generation ---------------------------------------------------------

.PHONY: proto
proto: ## Regenerate Go and Dart code from proto/ (needs buf + plugins)
	$(BUF) lint
	$(BUF) generate

.PHONY: proto-tools
proto-tools: ## Install the code generators buf drives
	$(GO) install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	$(GO) install connectrpc.com/connect/cmd/protoc-gen-connect-go@latest
	dart pub global activate protoc_plugin
	dart pub global activate connectrpc
	@echo 'Make sure $$(go env GOPATH)/bin and ~/.pub-cache/bin are on PATH.'

# --- server ------------------------------------------------------------------

.PHONY: server
server: build-server web ## Build the web app and the server, then run both on $(ADDR)
	mkdir -p $(DATA)
	@echo
	@echo '  Ratatosk is on $(PUBLIC_URL)'
	@echo '  Open that address in a browser: it serves the app, the API and invite links.'
	@echo
	$(BIN)/ratatoskd --addr $(ADDR) --data $(DATA) --public-url $(PUBLIC_URL) --web $(WEB_DIR)

.PHONY: web
web: ## Build the Flutter web app that the server serves
	cd $(APP_DIR) && $(FLUTTER) build web --release

.PHONY: build-server
build-server: ## Build the server binary into var/bin
	mkdir -p $(BIN)
	cd $(SERVER_DIR) && $(GO) build -o ../$(BIN)/ratatoskd ./cmd/ratatoskd

.PHONY: server-test
server-test: ## Run the Go test suite
	cd $(SERVER_DIR) && $(GO) vet ./... && $(GO) test ./...

# --- client ------------------------------------------------------------------

.PHONY: app
app: ## Run the Flutter app (pass DEVICE=web, linux, ... to pick a target)
	cd $(APP_DIR) && $(FLUTTER) run $(if $(DEVICE),-d $(DEVICE),)

.PHONY: app-test
app-test: ## Run the Flutter tests; interop tests need a server on $(TEST_URL)
	cd $(APP_DIR) && $(FLUTTER) analyze && RATATOSK_URL=$(TEST_URL) $(FLUTTER) test

.PHONY: app-build-linux
app-build-linux: ## Build the Linux desktop app (needs libsecret-1-dev)
	cd $(APP_DIR) && $(FLUTTER) build linux --release

# --- everything --------------------------------------------------------------

.PHONY: demo
demo: server ## Start the server and seed it with two accounts and a conversation
	@./scripts/seed-demo.sh

.PHONY: smoke
smoke: build-server web ## Run scripts/verify-run.sh: a real server, two clients, an invite
	./scripts/verify-run.sh

.PHONY: test
test: server-test app-test ## Run both test suites

.PHONY: check
check: proto server-test ## Lint the contract and run the server tests

.PHONY: clean
clean: ## Remove build output and the local data directory
	rm -rf $(BIN) $(APP_DIR)/build $(APP_DIR)/.dart_tool
	@echo 'Left $(DATA) alone; remove it by hand if you want a fresh server.'
