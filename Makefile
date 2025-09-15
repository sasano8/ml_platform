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
	@while :; do uv run pytest -svx --color=yes .; echo "\n[EXECUTED]"$$(date --iso-8601=seconds); cat TODO.md; sleep 10; done

git-commit:
	@uvx ruff format .
	@git commit -e
