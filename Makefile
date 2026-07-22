SHELL := /usr/bin/env bash

ENV_FILE := environments/local/.env
COMPOSE := docker compose --env-file $(ENV_FILE) -f compose.local.yml

.PHONY: \
	help \
	env \
	certs \
	validate \
	build \
	pull \
	up \
	down \
	restart \
	ps \
	logs \
	health \
	install \
	reset \
	shell-corporate \
	shell-store \
	shell-blog \
	wp-corporate \
	wp-store \
	wp-blog \
	db \
	clean


# --------------------------------------------------
# Help
# --------------------------------------------------

help:
	@printf '%s\n' \
		'make env              Generate local secrets' \
		'make certs            Generate local TLS certificates' \
		'make validate         Validate Compose configuration' \
		'make pull             Pull pinned dependency images' \
		'make build            Build CETECH images' \
		'make up               Start the complete local stack' \
		'make down             Stop containers without deleting data' \
		'make restart          Restart the stack' \
		'make ps               Show service status' \
		'make logs             Follow logs' \
		'make health           Run local health checks' \
		'make install          Install all three WordPress sites' \
		'make wp-corporate     Open WP-CLI shell for corporate' \
		'make wp-store         Open WP-CLI shell for store' \
		'make wp-blog          Open WP-CLI shell for blog' \
		'make db               Open MariaDB client' \
		'make reset            Delete local containers and volumes' \
		'make clean            Remove local build cache'


# --------------------------------------------------
# Environment & Certificates
# --------------------------------------------------

env:
	./scripts/local/generate-env.sh


certs:
	./scripts/local/generate-certificates.sh


# --------------------------------------------------
# Docker Compose Operations
# --------------------------------------------------

validate:
	$(COMPOSE) config --quiet
	$(COMPOSE) config > /tmp/cetech-compose-rendered.yml


pull:
	$(COMPOSE) pull --ignore-buildable


build:
	DOCKER_BUILDKIT=$${DOCKER_BUILDKIT:-0} $(COMPOSE) build --pull


up:
	$(COMPOSE) up -d --remove-orphans


down:
	$(COMPOSE) down --remove-orphans


restart:
	$(COMPOSE) restart


ps:
	$(COMPOSE) ps


logs:
	$(COMPOSE) logs --follow --tail=200


# --------------------------------------------------
# Application Operations
# --------------------------------------------------

health:
	./scripts/local/health-check.sh


install:
	./scripts/local/install-wordpress.sh


# --------------------------------------------------
# WordPress Shell Access
# --------------------------------------------------

shell-corporate:
	$(COMPOSE) exec corporate-php bash


shell-store:
	$(COMPOSE) exec store-php bash


shell-blog:
	$(COMPOSE) exec blog-php bash


# --------------------------------------------------
# WP-CLI Access
# --------------------------------------------------

wp-corporate:
	$(COMPOSE) run --rm corporate-cli bash


wp-store:
	$(COMPOSE) run --rm store-cli bash


wp-blog:
	$(COMPOSE) run --rm blog-cli bash


# --------------------------------------------------
# Database Access
# --------------------------------------------------

db:
	$(COMPOSE) exec mariadb mariadb -uroot -p


# --------------------------------------------------
# Cleanup
# --------------------------------------------------

reset:
	$(COMPOSE) down --volumes --remove-orphans
	@echo "Local databases, WordPress core volumes and Valkey data deleted."


clean:
	docker builder prune --force