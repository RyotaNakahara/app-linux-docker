.PHONY: help up down restart build logs shell artisan migrate seed test clean scan

# Default target
.DEFAULT_GOAL := help

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(GREEN)Laravel Docker Environment$(NC)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

up: ## Start all containers
	@echo "$(GREEN)Starting containers...$(NC)"
	docker compose up -d
	@echo "$(GREEN)Containers started successfully!$(NC)"
	@echo "App: http://localhost:${APP_PORT:-80}"
	@echo "Mailhog: http://localhost:${MAILHOG_WEB_PORT:-8025}"

down: ## Stop all containers
	@echo "$(YELLOW)Stopping containers...$(NC)"
	docker compose down
	@echo "$(GREEN)Containers stopped.$(NC)"

down-volumes: ## Stop containers and remove volumes
	@echo "$(RED)Stopping containers and removing volumes...$(NC)"
	docker compose down -v
	@echo "$(GREEN)Containers and volumes removed.$(NC)"

restart: ## Restart all containers
	@echo "$(YELLOW)Restarting containers...$(NC)"
	docker compose restart
	@echo "$(GREEN)Containers restarted.$(NC)"

build: ## Build/rebuild containers
	@echo "$(GREEN)Building containers...$(NC)"
	docker compose build --no-cache
	@echo "$(GREEN)Build complete!$(NC)"

rebuild: ## Rebuild and start containers
	@echo "$(GREEN)Rebuilding containers...$(NC)"
	docker compose down
	docker compose build --no-cache
	docker compose up -d
	@echo "$(GREEN)Rebuild complete!$(NC)"

logs: ## Show container logs (usage: make logs SERVICE=app)
	@if [ -z "$(SERVICE)" ]; then \
		docker compose logs -f; \
	else \
		docker compose logs -f $(SERVICE); \
	fi

ps: ## Show running containers
	docker compose ps

shell: ## Access app container shell
	docker compose exec app bash

shell-root: ## Access app container shell as root
	docker compose exec -u root app bash

artisan: ## Run artisan command (usage: make artisan CMD="migrate")
	@if [ -z "$(CMD)" ]; then \
		echo "$(RED)Error: Please specify CMD (e.g., make artisan CMD=\"migrate\")$(NC)"; \
		exit 1; \
	fi
	docker compose exec app php artisan $(CMD)

migrate: ## Run database migrations
	@echo "$(GREEN)Running migrations...$(NC)"
	docker compose exec app php artisan migrate --force
	@echo "$(GREEN)Migrations complete!$(NC)"

migrate-fresh: ## Drop all tables and re-run all migrations
	@echo "$(RED)WARNING: This will drop all tables!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose exec app php artisan migrate:fresh --force; \
		echo "$(GREEN)Database reset complete!$(NC)"; \
	fi

seed: ## Run database seeders
	@echo "$(GREEN)Running seeders...$(NC)"
	docker compose exec app php artisan db:seed --force
	@echo "$(GREEN)Seeding complete!$(NC)"

migrate-seed: ## Run migrations and seeders
	@echo "$(GREEN)Running migrations and seeders...$(NC)"
	docker compose exec app php artisan migrate --seed --force
	@echo "$(GREEN)Complete!$(NC)"

composer-install: ## Install composer dependencies
	@echo "$(GREEN)Installing composer dependencies...$(NC)"
	docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader
	@echo "$(GREEN)Installation complete!$(NC)"

composer-update: ## Update composer dependencies
	@echo "$(GREEN)Updating composer dependencies...$(NC)"
	docker compose exec app composer update --no-interaction --prefer-dist
	@echo "$(GREEN)Update complete!$(NC)"

test: ## Run tests
	@echo "$(GREEN)Running tests...$(NC)"
	docker compose exec app php artisan test

test-coverage: ## Run tests with coverage
	@echo "$(GREEN)Running tests with coverage...$(NC)"
	docker compose exec app php artisan test --coverage

cache-clear: ## Clear all caches
	@echo "$(GREEN)Clearing caches...$(NC)"
	docker compose exec app php artisan cache:clear
	docker compose exec app php artisan config:clear
	docker compose exec app php artisan route:clear
	docker compose exec app php artisan view:clear
	@echo "$(GREEN)Caches cleared!$(NC)"

optimize: ## Optimize application
	@echo "$(GREEN)Optimizing application...$(NC)"
	docker compose exec app php artisan config:cache
	docker compose exec app php artisan route:cache
	docker compose exec app php artisan view:cache
	@echo "$(GREEN)Optimization complete!$(NC)"

clean: ## Clean up containers, volumes, and images
	@echo "$(RED)WARNING: This will remove all containers, volumes, and images!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v --rmi all; \
		echo "$(GREEN)Cleanup complete!$(NC)"; \
	fi

scan: ## Scan Docker images for vulnerabilities (requires Trivy)
	@echo "$(GREEN)Scanning Docker images for vulnerabilities...$(NC)"
	@if command -v trivy > /dev/null; then \
		trivy image --severity HIGH,CRITICAL $$(docker compose images -q app); \
	else \
		echo "$(RED)Error: Trivy is not installed. Install it from https://github.com/aquasecurity/trivy$(NC)"; \
		exit 1; \
	fi

init: ## Initialize Laravel application (first time setup)
	@echo "$(GREEN)Initializing Laravel application...$(NC)"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN)Created .env file$(NC)"; \
	fi
	docker compose up -d
	@echo "$(YELLOW)Waiting for database to be ready...$(NC)"
	@sleep 5
	docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader
	docker compose exec app php artisan key:generate
	docker compose exec app php artisan migrate --seed --force
	@echo "$(GREEN)Initialization complete!$(NC)"
	@echo ""
	@echo "$(GREEN)Application is ready!$(NC)"
	@echo "App: http://localhost:${APP_PORT:-80}"
	@echo "Mailhog: http://localhost:${MAILHOG_WEB_PORT:-8025}"

status: ## Show application status
	@echo "$(GREEN)Application Status$(NC)"
	@echo ""
	docker compose ps
	@echo ""
	@echo "$(GREEN)URLs:$(NC)"
	@echo "App: http://localhost:${APP_PORT:-80}"
	@echo "Mailhog: http://localhost:${MAILHOG_WEB_PORT:-8025}"


