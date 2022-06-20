SHELL := /bin/bash

args = `arg="$(filter-out $(firstword $(MAKECMDGOALS)),$(MAKECMDGOALS))" && echo $${arg:-${1}}`

green  = $(shell printf "\e[32;01m$1\e[0m")
yellow = $(shell printf "\e[33;01m$1\e[0m")
red    = $(shell printf "\e[33;31m$1\e[0m")

format = $(shell printf "%-40s %s" "$(call green,bin/$1)" $2)

comma:= ,

.DEFAULT_GOAL:=help

%:
	@:

help:
	@echo ""
	@echo "$(call yellow,Use the following CLI commands:)"
	@echo "$(call red,===============================)"
	@echo "$(call format,package,'Package your cloudformation template to be deployed.')"
	@echo "$(call format,deploy,'Deploy your packed deploy.template file')"
	@echo "$(call format,packageAndDeploy,'Packages and deploy your template')"

package:
	@./bin/package

deploy:
	@./bin/deploy

packageAndDeploy:
	@./bin/packageAndDeploy