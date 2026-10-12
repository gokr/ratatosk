# Ratatosk: build, test, run.
#
# The front door for both halves: a Go server and a Flutter client that meet on
# one Protobuf contract.
#
# `make setup` resolves the toolchains (go, flutter, dart, buf) and records them
# in var/tools/env, which this file includes. That is why the variables below
# use ?= after the include: a tool found by setup wins, and GO=… on the command
# line still overrides everything.
SHELL := /bin/bash
.DEFAULT_GOAL := help

-include var/tools/env

GO           ?= go
FLUTTER      ?= flutter
BUF          ?= buf
TOOLS        ?= $(CURDIR)/var/tools
# The directory holding the Dart SDK, for the generators that need it.
DARTDIR      := $(patsubst %/,%,$(dir $(DART)))
BUILD_ID     ?= $(shell git describe --always --dirty 2>/dev/null || echo dev)
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

# --- prerequisites -----------------------------------------------------------

.PHONY: setup
setup: ## Install what the build and code generation need (no sudo, nothing global)
	@./scripts/setup.sh

.PHONY: doctor
doctor: ## Report what is ready and what is missing, changing nothing
	@./scripts/doctor.sh

# --- code generation ---------------------------------------------------------

.PHONY: proto
proto: ## Regenerate Go and Dart code from proto/
	@if [ ! -x "$(BUF)" ] && ! command -v "$(BUF)" > /dev/null; then \
		echo "buf is not installed: run 'make setup' first (it needs no sudo)" >&2; \
		exit 1; \
	fi
	# The generators live in var/tools, which is not on anyone's PATH, and the
	# Dart ones are wrappers that shell out to `dart`. So this invocation gets a
	# PATH of its own: the plugins, then the SDK that runs them. Nothing outside
	# this target has to care, and it works from a shell whose PATH has neither.
	PATH="$(TOOLS):$(DARTDIR):$$PATH" $(BUF) lint
	PATH="$(TOOLS):$(DARTDIR):$$PATH" $(BUF) generate

# --- server ------------------------------------------------------------------

.PHONY: server
server: build-server web ## Build the web app and the server, then run both on $(ADDR)
	@mkdir -p $(DATA)
	@echo
	@echo '  Ratatosk is on $(PUBLIC_URL)'
	@echo '  Open that address in a browser: it serves the app, the API and invite links.'
	@echo
	$(BIN)/ratatoskd --addr $(ADDR) --data $(DATA) --public-url $(PUBLIC_URL) --web $(WEB_DIR)

.PHONY: web
web: ## Build the Flutter web app that the server serves
	@cd $(APP_DIR) && $(FLUTTER) build web --release --dart-define=BUILD_ID=$(BUILD_ID)

.PHONY: privacy-pdf
privacy-pdf: ## Regenerate the published privacy policy PDF from privacy_policy.md
	@./scripts/generate-privacy-pdf.sh

.PHONY: build-server
build-server: ## Build the server binary into var/bin
	@mkdir -p $(BIN)
	cd $(SERVER_DIR) && $(GO) build -ldflags "-X main.version=$(BUILD_ID)" -o ../$(BIN)/ratatoskd ./cmd/ratatoskd

.PHONY: server-test
server-test: ## Run the Go test suite
	cd $(SERVER_DIR) && $(GO) vet ./... && $(GO) test ./...

# --- client ------------------------------------------------------------------

.PHONY: app
app: ## Run the Flutter app (DEVICE=linux, chrome, … to pick a target)
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
	@./scripts/verify-run.sh

.PHONY: test
test: server-test app-test ## Run both test suites

.PHONY: check
check: proto server-test ## Lint the contract and run the server tests

.PHONY: clean
clean: ## Remove build output (keeps var/data and the tools)
	rm -rf $(BIN) $(APP_DIR)/build $(APP_DIR)/.dart_tool
	@echo 'Left var/data (your server) and var/tools (the generators) alone.'
	@echo 'Remove those by hand for a completely fresh start.'
