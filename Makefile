.DEFAULT_GOAL := help

## preview
preview:
	npx zenn preview

## article
article:
	npx zenn new:article

## help
help:
	@make2help $(MAKEFILE_LIST)

.PHONY: help
.SILENT: