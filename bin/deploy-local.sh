#!/usr/bin/env sh

set -e

timestamp=$(date +%s)
docker build . -t level10:$timestamp
kubectl set image deployments/level10 level10=level10:$timestamp
kubectl rollout status deployments/level10
