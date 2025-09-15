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

test-loop:
	# root_ca（自己署名証明書） 含むバンドル証明書を使う場合
	# @export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt; while :; do uv run pytest -svx --color=yes .; echo "\n[EXECUTED]"$$(date --iso-8601=seconds); cat TODO.md; sleep 10; done
	# root_ca（自己署名証明書） だけ
	@export SSL_CERT_FILE=/usr/local/share/ca-certificates/root_ca.crt; while :; do uv run pytest -svx --color=yes .; echo "\n[EXECUTED]"$$(date --iso-8601=seconds); cat TODO.md; sleep 10; done

source-format:
	@uvx ruff format .
