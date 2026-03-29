#!/usr/bin/env bash
set -euo pipefail

NERO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${NERO_DIR}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  printf 'Missing %s\n' "${ENV_FILE}" >&2
  exit 1
fi

set -a
# shellcheck source=/dev/null
. "${ENV_FILE}"
set +a

export XDG_CONFIG_HOME="${NERO_DIR}/config"
export XDG_DATA_HOME="${NERO_DIR}/data/opencode"
export GH_CONFIG_DIR="${NERO_DIR}/config/gh"
export GIT_CONFIG_GLOBAL="${NERO_DIR}/config/git/.gitconfig"
export SHELL="${SHELL:-/bin/bash}"

exec opencode web \
  --hostname "${OPENCODE_BIND_ADDR}" \
  --port "${OPENCODE_BIND_PORT:-4096}"
