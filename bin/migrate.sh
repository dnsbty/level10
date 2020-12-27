#!/usr/bin/env sh

set -e

sed -i "s/{{IMAGE_TAG}}/$1/g" k8s/migrations.yaml
kubectl apply -f k8s/migrations.yaml >/dev/null
kubectl wait --for=condition=complete --timeout=1m jobs/level10-migrator >/dev/null
kubectl logs jobs/level10-migrator
kubectl delete jobs/level10-migrator >/dev/null
