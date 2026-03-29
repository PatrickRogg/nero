#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

if [[ -f "${PROJECT_DIR}/.env" ]]; then
  set -a
  . "${PROJECT_DIR}/.env"
  set +a
fi

compose_config_hash() {
  sha256sum "${PROJECT_DIR}/compose.yaml" "${PROJECT_DIR}/.env" 2>/dev/null | sha256sum | awk '{print $1}'
}

read_compose_stamp() {
  local stamp="$1"
  [[ -f "${stamp}" ]] || return 1
  if [[ -r "${stamp}" ]]; then
    cat "${stamp}"
    return 0
  fi
  ${SUDO} cat "${stamp}" 2>/dev/null
}

printf 'Nero doctor\n\n'
printf 'Project dir: %s\n' "${PROJECT_DIR}"
printf 'Proxy mode: %s\n' "${TRAEFIK_MODE:-self}"
printf 'Domain: %s\n' "${OPENCODE_DOMAIN:-unset}"
printf 'Bind port: %s\n' "${OPENCODE_BIND_PORT:-4096}"

stamp_path="${PROJECT_DIR}/data/.nero-compose-signature"
current_hash="$(compose_config_hash)"
printf '\nCompose stack signature\n'
printf 'Current hash: %s\n' "${current_hash}"
stored=""
if [[ -f "${stamp_path}" ]]; then
  stored="$(read_compose_stamp "${stamp_path}" 2>/dev/null)" || true
  if [[ -n "${stored}" ]]; then
    printf 'Stored stamp: %s\n' "${stored}"
  else
    printf 'Stored stamp: (empty or unreadable)\n'
  fi
else
  printf 'Stored stamp: (none)\n'
fi
if [[ ! -f "${stamp_path}" ]]; then
  printf 'Signature status: no stamp\n'
elif [[ -z "${stored}" ]]; then
  printf 'Signature status: stamp unreadable\n'
elif [[ "${stored}" == "${current_hash}" ]]; then
  printf 'Signature status: match\n'
else
  printf 'Signature status: mismatch\n'
fi

printf '\nContainers\n'
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | (grep -E 'NAMES|opencode|traefik' || true)

printf '\nWorkspace\n'
if [[ -f "${PROJECT_DIR}/scripts/workspace-setup.sh" ]]; then
  printf 'ok  workspace-setup hook: %s\n' "${PROJECT_DIR}/scripts/workspace-setup.sh"
elif [[ -n "${WORKSPACE_SETUP_SCRIPT:-}" ]] && [[ -f "${WORKSPACE_SETUP_SCRIPT}" ]]; then
  printf 'ok  workspace-setup hook: %s (from WORKSPACE_SETUP_SCRIPT)\n' "${WORKSPACE_SETUP_SCRIPT}"
else
  printf 'info workspace-setup.sh not present (optional; see workspace-setup.sh.example)\n'
fi
for path in \
  "${PROJECT_DIR}/workspace/agents/drop" \
  "${PROJECT_DIR}/workspace/agents/knowledge" \
  "${PROJECT_DIR}/workspace/agents/memory" \
  "${PROJECT_DIR}/workspace/agents/output" \
  "${PROJECT_DIR}/workspace/agents/code" \
  "${PROJECT_DIR}/workspace/agents/scripts" \
  "${PROJECT_DIR}/workspace/agents/.agents" \
  "${PROJECT_DIR}/workspace/agents/agents"; do
  if [[ -e "${path}" ]]; then
    printf 'ok  %s\n' "${path}"
  else
    printf 'miss %s\n' "${path}"
  fi
done

if [[ -n "${OPENCODE_DOMAIN:-}" ]]; then
  printf '\nHTTP check\n'
  curl -k -I --max-time 10 "https://${OPENCODE_DOMAIN}" || true
fi
