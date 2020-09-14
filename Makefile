.PHONY: help vars deps clean format test git flit-build flit-publish git
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
TAG := $(shell git describe --abbrev=0 --tags 2>/dev/null; true)
DIR := $(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")
PROJECT := $(shell basename $(DIR))
PACKAGE := typer
ACTIVATE := $(DIR)/venv/bin/activate

help: ## help
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

vars:  ## vars
	@echo "BUMP: $(BUMP)"
	@echo "BRANCH: $(BRANCH)"
	@echo "TAG: $(TAG)"
	@echo "DIR: $(DIR)"
	@echo "PROJECT: $(PROJECT)"
	@echo "PACKAGE: $(PACKAGE)"

deps: clean ## installs dev dependencies
	@source "$(ACTIVATE)" && python -m pip install --upgrade flit pip setuptools wheel pytest-runner setuptools_scm
	@source "$(ACTIVATE)" && python -m flit install --deps all

clean:  ## clean
	@/bin/rm -fr build/ > /dev/null 2>&1 | true
	@/bin/rm -fr dist/ > /dev/null 2>&1 | true
	@/bin/rm -fr site/ > /dev/null 2>&1 | true
	@/bin/rm -fr .coverage > /dev/null 2>&1 | true
	@/bin/rm -fr coverage.xml > /dev/null 2>&1 | true
	@/bin/rm -fr htmlcov > /dev/null 2>&1 | true
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

format:  ## format
	@source "$(ACTIVATE)" && set -x; isort --force-single-line-imports $(PACKAGE) tests docs_src
	@source "$(ACTIVATE)" && set -x; autoflake --remove-all-unused-imports --recursive --remove-unused-variables \
                                               --in-place docs_src $(PACKAGE) tests --exclude=__init__.py
	@source "$(ACTIVATE)" && set -x; black $(PACKAGE) tests docs_src
	@source "$(ACTIVATE)" && set -x; isort $(PACKAGE) tests docs_src

test: clean  ## test
	@source "$(ACTIVATE)" && darglint -v 2 -s google --log-level DEBUG --strictness full $(PROJECT)/*.py
	@source "$(ACTIVATE)" && set -e; set -x; mypy $(PACKAGE)
	@source "$(ACTIVATE)" && set -e; set -x; black $(PACKAGE) tests docs_src --check
	@source "$(ACTIVATE)" && set -e; set -x; isort $(PACKAGE) tests docs_src --check-only
	@source "$(ACTIVATE)" && set -e; set -x; pytest --ignore docs_src --tb=short --strict --doctest-modules \
                                                    --doctest-continue-on-failure
	@source "$(ACTIVATE)" && set -e; set -x; pytest --cov=$(PACKAGE) --cov-report=html --cov=tests --cov=docs_src \
                                                    --cov-report=term-missing --cov-report=xml \
                                                    -o console_output_style=progress --forked --numprocesses=auto

git:  ## git add all
	@echo "BRANCH: $(BRANCH), TAG: $(TAG)"
	@git add . --all
	@source "$(ACTIVATE)" && bump2version --allow-dirty $(BUMP)
	@git push -u origin $(BRANCH) --tags
	@echo "BRANCH: $$(git rev-parse --abbrev-ref HEAD), TAG: $$(git describe --abbrev=0 --tags 2>/dev/null; true)"

flit-build: clean ## publish
	@source "$(ACTIVATE)" && set -e; flit build

flit-publish: clean ## publish
	@source "$(ACTIVATE)" && set -e; flit publish --repository j5pu
