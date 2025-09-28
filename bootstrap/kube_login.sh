#!/bin/sh

set -e

docker compose exec kube sh -lc 'printf "%s\n" "#!/usr/bin/env sh" "exec k0s kubectl \"\$@\"" > /usr/local/bin/kubectl'
docker compose exec kube chmod +x /usr/local/bin/kubectl
docker compose exec -it kube /bin/ash -l
