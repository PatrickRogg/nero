#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "${PROJECT_DIR}/.env" ]]; then
  set -a
  . "${PROJECT_DIR}/.env"
  set +a
fi

if [[ "${TRAEFIK_MODE:-self}" == "self" ]]; then
  docker compose -f "${PROJECT_DIR}/compose.yaml" --env-file "${PROJECT_DIR}/.env" --profile self-proxy build --pull
  docker compose -f "${PROJECT_DIR}/compose.yaml" --env-file "${PROJECT_DIR}/.env" --profile self-proxy up -d
else
  docker compose -f "${PROJECT_DIR}/compose.yaml" --env-file "${PROJECT_DIR}/.env" build --pull
  docker compose -f "${PROJECT_DIR}/compose.yaml" --env-file "${PROJECT_DIR}/.env" up -d
fi
