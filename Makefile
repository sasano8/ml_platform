platform-configurate:
	@[ -f ".env" ] || ./bootstrap/env_init.sh > .env

platform-recreate:
	@docker compose down
	@rm -rf ./volumes/step
	@./bootstrap/ca_init.sh
	@./bootstrap/ca_certificate.sh
	@docker compose up -d
	@sleep 10
	@make test

container-build:
	@docker compose down kube
	@docker volume rm platform-k0s 2>/dev/null || true
	@docker compose build kube --progress plain
	@docker compose up -d kube
	@sleep 30
	@docker compose exec kube /root/setup/02_kube_setup_kanative.sh

container-up:
	@docker compose up -d
	@./bootstrap/kube_deploy.sh

container-down:
	@docker compose down

container-clean:
	@docker compose down
	@docker volume rm platform-k0s 2>/dev/null || true

container-restart:
	@docker compose down
	@docker compose up -d

container-login:
	@docker compose exec -it kube /bin/ash -l

test:
	# root_ca（自己署名証明書） 含むバンドル証明書を使う場合
	# @export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt; while :; do uv run pytest -svx --color=yes .; echo "\n[EXECUTED]"$$(date --iso-8601=seconds); cat TODO.md; sleep 10; done
	# root_ca（自己署名証明書） だけ
	@export SSL_CERT_FILE=/usr/local/share/ca-certificates/root_ca.crt; uv run pytest -svx .

test-loop:
	@export SSL_CERT_FILE=/usr/local/share/ca-certificates/root_ca.crt; while :; do uv run pytest -svx --color=yes .; echo "\n[EXECUTED]"$$(date --iso-8601=seconds); cat TODO.md; sleep 10; done

source-format:
	@uvx ruff format .
