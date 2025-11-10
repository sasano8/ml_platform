config-init:
	@python3 -m tools conf_init

config-update:
	@docker compose down
	@python3 -m tools conf_calculate
	@gomplate -d cfg=.env.json -f tools/templates/docker-compose.tmpl.yml -o docker-compose.yml
	@gomplate -d cfg=.env.json -f tools/templates/kong.tmpl.yml -o configs/kong/kong.yaml

ca-init:
	@docker compose down stepca
	@rm -rf volumes/step
	@./bootstrap/ca_init.sh
	@./bootstrap/ca_show_certpath.sh

ca-certificate:
	@./bootstrap/ca_certificate.sh

k0s-init:
	@docker compose down kube
	@docker volume rm platform-k0s || true
	@docker volume create platform-k0s

k0s-setup:
	@docker compose up -d kube
	@docker compose exec -it kube /root/setup/02_kube_setup.sh
	@docker compose exec -it kube /root/setup/03_kube_check.sh

k0s-test:
	@docker compose exec -it kube /root/setup/04_kube_test.sh

containers-up:
	@docker compose up -d kube  # ポートが衝突するので先に上げておく
	@docker compose up -d

env-init:
	@docker compose down
	@make config-update
	@make ca-init
	@make ca-certificate
	@make k0s-init
	@make k0s-setup
	@make k0s-test
	@make containers-up
	@./bootstrap/ca_show_certpath.sh

env-update:
	@docker compose down
	@make config-update
	@make ca-certificate
	@make k0s-setup
	@make containers-up


kong-restart: config-update
	@docker compose down kong kube stepca
	@docker compose up -d kong kube stepca
# 	@curl -v -fs -H "Host: hello-ksvc-http.default.172-31-97-7.sslip.io" http://localhost

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
