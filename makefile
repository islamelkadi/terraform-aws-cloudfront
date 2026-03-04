# Terraform Module: Cloudfront
# This makefile provides common Terraform operations for the Cloudfront module

.PHONY: help bootstrap init validate fmt lint security docs clean all

# Default target
help:
	@echo "Available targets:"
	@echo "  bootstrap - Install required tools (macOS only)"
	@echo "  init      - Initialize Terraform (download providers)"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  fmt       - Format Terraform files"
	@echo "  lint      - Run tflint on configuration"
	@echo "  security  - Run security scan with checkov"
	@echo "  docs      - Generate module documentation"
	@echo "  clean     - Remove Terraform state and cache files"
	@echo "  all       - Run init, fmt, validate, lint, security, docs"

# Install required tools (macOS)
bootstrap:
	@echo "Bootstrapping development environment..."
	@which brew > /dev/null || (echo "Error: Homebrew is required. Install from https://brew.sh" && exit 1)
	@echo "Installing tfenv..."
	@brew list tfenv > /dev/null 2>&1 || brew install tfenv
	@echo "Installing Terraform via tfenv..."
	@tfenv install latest && tfenv use latest
	@echo "Installing tflint..."
	@brew list tflint > /dev/null 2>&1 || brew install tflint
	@echo "Installing terraform-docs..."
	@brew list terraform-docs > /dev/null 2>&1 || brew install terraform-docs
	@echo "Installing checkov..."
	@pip install --quiet --upgrade checkov
	@echo "Installing pre-commit..."
	@pip install --quiet --upgrade pre-commit
	@echo "Setting up pre-commit hooks..."
	@pre-commit install
	@echo "Bootstrap complete!"

# Initialize Terraform
init:
	@echo "Initializing Terraform..."
	terraform init -upgrade

# Validate configuration
validate: init
	@echo "Validating Terraform configuration..."
	terraform validate

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

# Run tflint
lint: init
	@echo "Running tflint..."
	tflint --init
	tflint --recursive

# Run security scan
security:
	@echo "Running security scan with checkov..."
	checkov -d . --config-file .checkov.yaml

# Generate documentation
docs:
	@echo "Generating module documentation..."
	terraform-docs markdown table --output-file README.md --output-mode inject .

# Clean Terraform files
clean:
	@echo "Cleaning Terraform files..."
	rm -rf .terraform .terraform.lock.hcl

# Run all checks
all: init fmt validate lint security docs
	@echo "All checks completed successfully!"
