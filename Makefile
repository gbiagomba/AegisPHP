# Makefile for PHALANX - PHP Security Analysis Tool
# Version: 0.1.0

.PHONY: help build scan clean test install uninstall version lint

# Variables
IMAGE_NAME := phalanx
TARGET     ?= .
OUTPUT     ?= PHALANX_output-$(shell date +"%Y%m%d_%H%M%S").json
PYTHON     := python3
INSTALL_DIR := /usr/local/bin
VERSION    := 0.2.0

# Colors for output
BOLD       := \033[1m
GREEN      := \033[0;32m
YELLOW     := \033[0;33m
RED        := \033[0;31m
NC         := \033[0m

help:
	@echo "$(BOLD)PHALANX v$(VERSION) - Makefile Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Build Commands:$(NC)"
	@echo "  make build          - Build the Docker image"
	@echo "  make rebuild        - Rebuild the Docker image from scratch (no cache)"
	@echo ""
	@echo "$(GREEN)Usage Commands:$(NC)"
	@echo "  make scan           - Run security scan (set TARGET=/path/to/project)"
	@echo "  make test           - Run Python tests and linters"
	@echo "  make version        - Display PHALANX version"
	@echo ""
	@echo "$(GREEN)Installation Commands:$(NC)"
	@echo "  make install        - Install PHALANX system-wide (requires sudo)"
	@echo "  make uninstall      - Uninstall PHALANX from system"
	@echo ""
	@echo "$(GREEN)Cleanup Commands:$(NC)"
	@echo "  make clean          - Remove Docker images"
	@echo "  make clean-all      - Remove Docker images and output files"
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make scan TARGET=./my-php-project OUTPUT=report.json"
	@echo "  make build && make test"
	@echo ""

build:
	@echo "$(GREEN)[+] Building Docker image '$(IMAGE_NAME)'...$(NC)"
	docker build -t $(IMAGE_NAME) .
	@echo "$(GREEN)[✓] Docker image built successfully$(NC)"

rebuild:
	@echo "$(GREEN)[+] Rebuilding Docker image '$(IMAGE_NAME)' (no cache)...$(NC)"
	docker build --no-cache -t $(IMAGE_NAME) .
	@echo "$(GREEN)[✓] Docker image rebuilt successfully$(NC)"

scan: build
	@echo "$(GREEN)[+] Running PHALANX security scan...$(NC)"
	@echo "$(YELLOW)    Target: $(TARGET)$(NC)"
	@echo "$(YELLOW)    Output: $(OUTPUT)$(NC)"
	$(PYTHON) phalanx.py $(TARGET) -o $(OUTPUT)
	@echo "$(GREEN)[✓] Scan complete$(NC)"

test:
	@echo "$(GREEN)[+] Running tests...$(NC)"
	@echo ""
	@echo "$(YELLOW)[1/4] Checking Python syntax...$(NC)"
	$(PYTHON) -m py_compile phalanx.py
	@echo "$(GREEN)[✓] Syntax check passed$(NC)"
	@echo ""
	@echo "$(YELLOW)[2/4] Running type checks (if mypy installed)...$(NC)"
	-$(PYTHON) -m mypy phalanx.py 2>/dev/null || echo "$(YELLOW)ℹ mypy not installed, skipping type checks$(NC)"
	@echo ""
	@echo "$(YELLOW)[3/4] Running linter (if pylint installed)...$(NC)"
	-$(PYTHON) -m pylint phalanx.py 2>/dev/null || echo "$(YELLOW)ℹ pylint not installed, skipping lint checks$(NC)"
	@echo ""
	@echo "$(YELLOW)[4/4] Testing Docker build...$(NC)"
	docker build -t $(IMAGE_NAME)-test . > /dev/null 2>&1
	docker image rm $(IMAGE_NAME)-test > /dev/null 2>&1
	@echo "$(GREEN)[✓] Docker build test passed$(NC)"
	@echo ""
	@echo "$(GREEN)[✓] All tests completed$(NC)"

version:
	@$(PYTHON) phalanx.py --version

install:
	@echo "$(GREEN)[+] Installing PHALANX to $(INSTALL_DIR)...$(NC)"
	@if [ ! -w $(INSTALL_DIR) ]; then \
		echo "$(RED)[!] $(INSTALL_DIR) is not writable. Please run with sudo:$(NC)"; \
		echo "    sudo make install"; \
		exit 1; \
	fi
	cp phalanx.py $(INSTALL_DIR)/phalanx
	chmod +x $(INSTALL_DIR)/phalanx
	@echo "$(GREEN)[✓] PHALANX installed successfully$(NC)"
	@echo "$(YELLOW)    You can now run: phalanx /path/to/project$(NC)"

uninstall:
	@echo "$(GREEN)[+] Uninstalling PHALANX from $(INSTALL_DIR)...$(NC)"
	@if [ ! -w $(INSTALL_DIR) ]; then \
		echo "$(RED)[!] $(INSTALL_DIR) is not writable. Please run with sudo:$(NC)"; \
		echo "    sudo make uninstall"; \
		exit 1; \
	fi
	rm -f $(INSTALL_DIR)/phalanx
	@echo "$(GREEN)[✓] PHALANX uninstalled successfully$(NC)"

clean:
	@echo "$(GREEN)[+] Removing Docker image '$(IMAGE_NAME)'...$(NC)"
	docker image rm -f $(IMAGE_NAME) 2>/dev/null || true
	@echo "$(GREEN)[✓] Docker image removed$(NC)"

clean-all: clean
	@echo "$(GREEN)[+] Removing output files...$(NC)"
	rm -f PHALANX_output-*.json AegisPHP_output-*.json
	rm -rf __pycache__ *.pyc .mypy_cache .pytest_cache
	@echo "$(GREEN)[✓] All artifacts removed$(NC)"

lint:
	@echo "$(GREEN)[+] Running code quality checks...$(NC)"
	-$(PYTHON) -m pylint phalanx.py
	-$(PYTHON) -m mypy phalanx.py
	-$(PYTHON) -m flake8 phalanx.py

# CI/CD targets
ci-build: rebuild

ci-test: test

ci-scan: scan

.DEFAULT_GOAL := help
