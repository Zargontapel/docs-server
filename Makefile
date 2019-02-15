# Makefile for the documentation

SHELL ?= bash

FONTS_DIR ?= fonts
STYLES_DIR ?= resources/themes

STYLE ?= owncloud
REVDATE ?= "$(shell date +'%B %d, %Y')"

ifndef VERSION
	ifneq ($(DRONE_TAG),)
		VERSION ?= $(subst v,,$(DRONE_TAG))
	else
		ifneq ($(DRONE_BRANCH),)
			VERSION ?= $(subst /,,$(DRONE_BRANCH))
		else
			VERSION ?= master
		endif
	endif
endif

ifndef OUTPUT_USER
	ifneq ($(VERSION),master)
		OUTPUT_USER ?= build/server/$(VERSION)/user_manual
	else
		OUTPUT_USER ?= build/server/user_manual
	endif
endif

ifndef OUTPUT_ADMIN
	ifneq ($(VERSION),master)
		OUTPUT_ADMIN ?= build/server/$(VERSION)/administration_manual
	else
		OUTPUT_ADMIN ?= build/server/administration_manual
	endif
endif

ifndef OUTPUT_DEVELOPER
	ifneq ($(VERSION),master)
		OUTPUT_DEVELOPER ?= build/server/$(VERSION)/developer_manual
	else
		OUTPUT_DEVELOPER ?= build/server/developer_manual
	endif
endif

.PHONY: help
help: ## Print a basic help about the targets
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/:/'`); \
	printf "%-30s %s\n" "target" "help" ; \
	printf "%-30s %s\n" "------" "----" ; \
	for help_line in $${help_lines[@]}; do \
		IFS=$$':' ; \
		help_split=($$help_line) ; \
		help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
		help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
		printf '\033[36m'; \
		printf "%-30s %s" $$help_command ; \
		printf '\033[0m'; \
		printf "%s\n" $$help_info; \
	done

.PHONY: setup
setup: ## Install Antora's command tools locally
	yarn install

.PHONY: clean
clean: ## Remove build artifacts from output dir
	-rm -rf build/

.PHONY: pdf
pdf: pdf-user pdf-admin pdf-developer ## Generate PDF version of the manuals

.PHONY: pdf-user
pdf-user: ## Generate PDF version of the user manual
	asciidoctor-pdf \
		-a pdf-stylesdir=$(STYLES_DIR)/ \
		-a pdf-style=$(STYLE) \
		-a pdf-fontsdir=$(FONTS_DIR) \
		-a examplesdir=modules/user_manual/examples \
		-a imagesdir=modules/user_manual/assets/images \
		-a revnumber=$(VERSION) \
		-a revdate=$(REVDATE) \
		--base-dir $(CURDIR) \
		--out-file $(OUTPUT_USER)/ownCloud_User_Manual.pdf \
		books/ownCloud_User_Manual.adoc

.PHONY: pdf-admin
pdf-admin: ## Generate PDF version of the administration manual
	asciidoctor-pdf \
		-a pdf-stylesdir=$(STYLES_DIR)/ \
		-a pdf-style=$(STYLE) \
		-a pdf-fontsdir=$(FONTS_DIR) \
		-a examplesdir=modules/administration_manual/examples \
		-a imagesdir=modules/administration_manual/assets/images \
		-a revnumber=$(VERSION) \
		-a revdate=$(REVDATE) \
		--base-dir $(CURDIR) \
		--out-file $(OUTPUT_ADMIN)/ownCloud_Admin_Manual.pdf \
		books/ownCloud_Admin_Manual.adoc

.PHONY: pdf-developer
pdf-developer: ## Generate PDF version of the developer manual
	asciidoctor-pdf \
		-a pdf-stylesdir=$(STYLES_DIR)/ \
		-a pdf-style=$(STYLE) \
		-a pdf-fontsdir=$(FONTS_DIR) \
		-a examplesdir=modules/developer_manual/examples \
		-a imagesdir=modules/developer_manual/assets/images \
		-a revnumber=$(VERSION) \
		-a revdate=$(REVDATE) \
		--base-dir $(CURDIR) \
		--out-file $(OUTPUT_DEVELOPER)/ownCloud_Developer_Manual.pdf \
		books/ownCloud_Developer_Manual.adoc

XMLLINT_INSTALLED := $(shell command -v xmllint 2>/dev/null)

.PHONY: validate-xml
validate-xml: ## Validate all XML files
ifneq ($(XMLLINT_INSTALLED),)
	@-find ./modules/*_manual/examples -type f -name "*.xml" -exec xmllint --noout {} \;
else
	@echo "Command xmllint not found, please install."
endif

PHPCLI_INSTALLED := $(shell command -v php 2>/dev/null)

.PHONY: validate-php
validate-php: ## Validate all PHP files
ifneq ($(PHPCLI_INSTALLED),)
	@-find ./modules/*_manual/examples -type f -name "*.php" -exec php -l {} \;
	@echo
else
	@echo "Command php not found, please install."
endif

YAMLLINT_INSTALLED := $(shell command -v yamllint 2>/dev/null)

.PHONY: validate-yaml
validate-yaml: ## Validate all YAML files
ifneq ($(YAMLLINT_INSTALLED),)
	@-find . -type f -name "*.yml" ! -path "./node_modules/*" ! -path "**/vendor/*" ! -path "./.git/*" -exec sh -c 'echo Linting {} && yamllint -f parsable {} && echo' \;
else
	@echo "Command yamllint not found, please install."
endif

JSONLINT_INSTALLED := $(shell command -v jsonlint 2>/dev/null)
JSONLINTPHP_INSTALLED := $(shell command -v jsonlint-php 2>/dev/null)

.PHONY: validate-json
validate-json: ## Validate all JSON files
ifneq ($(JSONLINT_INSTALLED),)
	@-find . -type f -name "*.json" ! -path "./node_modules/*" ! -path "**/vendor/*" ! -path "./.git/*" -exec sh -c 'echo Linting {} && jsonlint -qp {} && echo' \;
else ifneq ($(JSONLINTPHP_INSTALLED),)
	@-find . -type f -name "*.json" ! -path "./node_modules/*" ! -path "**/vendor/*" ! -path "./.git/*" -exec sh -c 'echo Linting {} && jsonlint-php -qp {} && echo' \;
else
	@echo "Command jsonlint not found, please install."
endif
