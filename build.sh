#!/usr/bin/env bash
set -euo pipefail
ENVIRONMENT="${1:-dev}"
DOCKERHUB_USER="${DOCKERHUB_USER:?export DOCKERHUB_USER first}"
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
  echo "Usage: $0 <dev|prod>" >&2
  exit 1
fi
TAG="$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)"
IMAGE="${DOCKERHUB_USER}/${ENVIRONMENT}"
echo ">> Building ${IMAGE}:${TAG}"
docker build -t "${IMAGE}:${TAG}" -t "${IMAGE}:latest" .
echo ">> Built ${IMAGE}:${TAG} and ${IMAGE}:latest"
