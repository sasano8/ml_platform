.PHONY: bootstrap
bootstrap:
	@[ -f ".env" ] || ./bootstrap/env_init.sh > .env
	@./bootstrap/ca_init.sh
	@./bootstrap/ca_certificate.sh

container-up:
	@docker compose up -d

container-restart:
	@docker compose down
	@docker compose up -d

test: up
	@uv run pytest -svx .

test-loop: up
	@watch -n 10 'uv run pytest -svx .'

git-commit:
	@uvx ruff format .
	@git commit -e
