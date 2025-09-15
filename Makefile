.PHONY: bootstrap
bootstrap:
	@[ -f ".env" ] || ./bootstrap/env_init.sh > .env
	@./bootstrap/ca_init.sh
	@./bootstrap/ca_certificate.sh

up:
	@docker compose up -d

test: up
	@uv run pytest -svx .

test-loop: up
	@watch -n 10 'uv run pytest -svx .'
