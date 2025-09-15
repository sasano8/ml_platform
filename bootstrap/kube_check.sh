#!/bin/sh

set -e

# ノードの起動確認
docker compose exec kube k0s kubectl get nodes
docker compose exec kube k0s kubectl get pods -n kube-system
docker compose exec kube k0s kubectl get pods

# ハローワールド
docker compose exec kube k0s kubectl delete job hello-world || true
cat <<'YAML' | docker compose exec -T kube k0s kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: hello-world
spec:
  suspend: true
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: main
          image: hello-world
YAML

# 作成された pod を特定
RUNID="$(docker compose exec -T kube sh -lc '
set -e
JOB=hello-world
UID=$(k0s kubectl get job "$JOB" -o jsonpath="{.metadata.uid}")
BEFORE=$(k0s kubectl get pods -l controller-uid="$UID" --no-headers 2>/dev/null | wc -l)
k0s kubectl patch job "$JOB" -p "{\"spec\":{\"suspend\":false}}" >/dev/null
for i in $(seq 1 5); do
  NOW=$(k0s kubectl get pods -l controller-uid="$UID" --no-headers 2>/dev/null | wc -l)
  if [ "$NOW" -gt "$BEFORE" ]; then
    k0s kubectl get pods -l controller-uid="$UID" --sort-by=.metadata.creationTimestamp -o jsonpath="{.items[-1].metadata.name}"
    exit 0
  fi
  sleep 1
done
echo timeout >&2; exit 1
' )" || { echo "RUNID取得に失敗"; exit 1; }

# 完了まで待機
docker compose exec -T kube sh -lc '
set -e
POD='"$RUNID"'

for i in $(seq 1 600); do  # 最大600秒
  PHASE=$(k0s kubectl get pod "$POD" -o jsonpath="{.status.phase}" 2>/dev/null || true)
  if [ "$PHASE" = "Succeeded" ]; then
    EC=$(k0s kubectl get pod "$POD" -o jsonpath="{.status.containerStatuses[0].state.terminated.exitCode}")
    echo "DONE POD='$POD' EXIT_CODE=$EC"
    exit 0
  elif [ "$PHASE" = "Failed" ]; then
    echo "FAILED POD='$POD'" >&2
    k0s kubectl describe pod "$POD" >&2
    exit 1
  fi
  sleep 1
done

echo "TIMEOUT waiting POD='$POD'" >&2
exit 1
'

# 実行結果
docker compose exec kube k0s kubectl logs $RUNID
