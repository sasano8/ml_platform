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

test: container-restart
	@uv run pytest -svx .

test-loop: container-restart
	@watch --color -n 10 'date --iso-8601=seconds; echo "===== run ====="; uv run pytest --color=yes -svx .'

git-commit:
	@uvx ruff format .
	@git commit -e
