#!/usr/bin/env bash
set -euo pipefail
ENVIRONMENT="${1:-prod}"
DOCKERHUB_USER="${DOCKERHUB_USER:?export DOCKERHUB_USER first}"
export IMAGE="${DOCKERHUB_USER}/${ENVIRONMENT}:latest"
if [[ -n "${DOCKERHUB_TOKEN:-}" ]]; then
  echo "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USER}" --password-stdin
fi
echo ">> Pulling ${IMAGE}"
docker pull "${IMAGE}"
echo ">> Starting application on port 80"
docker compose up -d --remove-orphans
docker image prune -f >/dev/null
echo ">> Deployed ${IMAGE}"
docker ps --filter name=react-app
