.PHONY: help vars clean deps docs-build docs-live format lint test-files test test-cov-html flit-build flit-publish git
.DEFAULT_GOAL := help

BUMP := patch  # major|minor|patch
IMAGE := bapy
VERSION := latest

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT
SHELL := $(shell command -v bash)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
CURRENT := $(shell git describe --abbrev=0 --tags 2>/dev/null; true)
DIR := $(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")
PROJECT := $(shell basename $(DIR))
PACKAGE := typer
ACTIVATE := $(DIR)/venv/bin/activate

help: ## help
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

vars:  ## vars
	@echo "BUMP: $(BUMP)"
	@echo "BRANCH: $(BRANCH)"
	@echo "CURRENT: $(CURRENT)"
	@echo "DIR: $(DIR)"
	@echo "PROJECT: $(PROJECT)"
	@echo "PACKAGE: $(PACKAGE)"

clean:  ## clean
	@/bin/rm -fr build/ > /dev/null 2>&1 | true
	@/bin/rm -fr dist/ > /dev/null 2>&1 | true
	@/bin/rm -fr site/ > /dev/null 2>&1 | true
	@/bin/rm -fr .coverage > /dev/null 2>&1 | true
	@/bin/rm -fr coverage.xml > /dev/null 2>&1 | true
	@/bin/rm -fr .eggs/ > /dev/null 2>&1 | true
	@find . -name '*.egg-info' -exec /bin/rm -fr {} + > /dev/null 2>&1 | true
	@find . -name '*.egg' -exec /bin/rm -f {} + > /dev/null 2>&1 | true
	@find . -name '*.pyc' -exec /bin/rm -f {} + > /dev/null 2>&1 | true
	@find . -name '*.pyo' -exec /bin/rm -f {} + > /dev/null 2>&1 | true
	@find . -name '*~' -exec /bin/rm -f {} + > /dev/null 2>&1 | true
	@find . -name '__pycache__' -exec /bin/rm -fr {} + > /dev/null 2>&1 | true
	@/bin/rm -fr .tox/ > /dev/null 2>&1 | true
	@/bin/rm -fr .pytest_cache > /dev/null 2>&1 | true
	@find . -name '.mypy_cache' -exec /bin/rm -rf {} + > /dev/null 2>&1 | true

deps: clean ## installs dev dependencies
	@source "$(ACTIVATE)" && python -m pip install flit
	@source "$(ACTIVATE)" && python -m flit install --deps all

docs-build: clean  ## build docs
	@source "$(ACTIVATE)" && python -m mkdocs build
	cp ./docs/index.md ./README.md

docs-live:  ## docs-live
	@source "$(ACTIVATE)" && set -e; mkdocs serve --dev-addr 127.0.0.1:8008

format:  ## format
	@source "$(ACTIVATE)" && set -x; isort --force-single-line-imports $(PACKAGE) tests docs_src
	@source "$(ACTIVATE)" && set -x; autoflake --remove-all-unused-imports --recursive --remove-unused-variables --in-place docs_src $(PACKAGE) tests --exclude=__init__.py
	@source "$(ACTIVATE)" && set -x; black $(PACKAGE) tests docs_src
	@source "$(ACTIVATE)" && set -x; isort $(PACKAGE) tests docs_src

lint:  ## lint
	@source "$(ACTIVATE)" && set -e; set -x; mypy $(PACKAGE)
	@source "$(ACTIVATE)" && set -e; set -x; black $(PACKAGE) tests docs_src --check
	@source "$(ACTIVATE)" && set -e; set -x; isort $(PACKAGE) tests docs_src --check-only

test-files:  ## test-files
	@source "$(ACTIVATE)" && set -e; set -x; diff --brief docs/index.md README.md
	@source "$(ACTIVATE)" && set -e; set -x; if grep -r --include "*.md" "Usage: tutorial" ./docs ; then echo "Incorrect console demo"; exit 1 ; fi
	@source "$(ACTIVATE)" && set -e; set -x; if grep -r --include "*.md" "python tutorial" ./docs ; then echo "Incorrect console demo"; exit 1 ; fi

test: clean test-files lint  ## test
	@source "$(ACTIVATE)" && set -e; set -x; pytest --cov=$(PACKAGE) --cov=tests --cov=docs_src --cov-report=term-missing --cov-report=xml -o console_output_style=progress --forked --numprocesses=auto

test-cov-html:
	@source "$(ACTIVATE)" && set -e; set -x; pytest --cov-report=html --cov=$(PACKAGE) --cov=tests --cov=docs_src --cov-report=term-missing --cov-report=xml -o console_output_style=progress --forked --numprocesses=auto pwd

flit-build: clean ## publish
	@source "$(ACTIVATE)" && set -e; flit build

flit-publish: clean ## publish
	@source "$(ACTIVATE)" && set -e; flit publish --repository j5pu

git:  ## git add all
	@git add . --all
	@source "$(ACTIVATE)" && bump2version --allow-dirty $(BUMP)
	@git push -u origin $(BRANCH) --tags

