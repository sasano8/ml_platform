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

# k0s-init:
# 	@docker compose down kube
# 	@docker volume rm platform-k0s || true
# 	@docker volume create platform-k0s

k0s-setup:
	@docker compose up -d kube
	@docker compose exec -it kube /root/setup/02_kube_setup.sh
	@docker compose exec -it kube /root/setup/03_kube_check.sh

k0s-test:
	@docker compose exec -it kube /root/setup/04_kube_test.sh

env-clean:
	@docker compose down
	@docker volume rm platform-k0s || true
	@docker volume create platform-k0s
	@rm -rf ./volumes/step

env-init:
	@docker compose down
	@docker compose build kube
	@make config-update
	@docker compose up -d kube
	@make ca-init
	@make env-setup

env-update-k0s:
	@docker compose down
	@make config-update
	@docker compose up -d kube
	@make k0s-setup
	@make k0s-test
	@make env-up

env-update-ca:
	@make ca-certificate

env-update:
	@docker compose down
	@make config-update
	@make env-update-ca
	@make env-up
	@./bootstrap/ca_show_certpath.sh

env-up:
	@docker compose up -d kube  # ポートが衝突するので先に上げておく
	@docker compose up -d


test-loop:
	@export SSL_CERT_FILE=/usr/local/share/ca-certificates/root_ca.crt; while :; do uv run pytest -svx --color=yes .; echo "\n[EXECUTED]"$$(date --iso-8601=seconds); cat TODO.md; sleep 10; done
