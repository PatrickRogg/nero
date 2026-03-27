# nero

Dockerized OpenCode for a VPS with:

- Traefik reverse proxy
- automatic Let's Encrypt SSL via Cloudflare DNS challenge
- OpenCode web UI exposed on a custom domain
- built-in OpenCode HTTP basic auth for both the UI and API
- persistent agent workspace mounted from the host

## Why this setup

Current OpenCode docs support protecting `opencode serve` and `opencode web` with:

- `OPENCODE_SERVER_PASSWORD`
- optional `OPENCODE_SERVER_USERNAME`

That means the simplest internet-safe default is:

1. Traefik handles TLS and renewal
2. OpenCode handles UI and API password protection
3. The agent only sees its dedicated workspace mount

## Project layout

```text
nero/
  compose.yaml
  .env.example
  AGENTS.md
  config/opencode/opencode.json
  opencode/
    Dockerfile
    entrypoint.sh
  scripts/
    bootstrap-ubuntu-24.sh
    install.sh
    update.sh
  workspace/agent/
```

## Quick start

1. On a fresh Ubuntu 24.04 VPS, run `sudo bash ./scripts/bootstrap-ubuntu-24.sh`
2. Copy `.env.example` to `.env` if you want to prefill infra values
3. Run `bash ./scripts/install.sh`
4. Answer the onboarding prompts:
   - domain
   - Let's Encrypt email
   - Cloudflare DNS token
   - OpenCode login password
   - provider choice
   - model choice
   - provider API key if needed
5. Open `https://<your-domain>`

## Fresh Ubuntu 24 VM

If you just cloned the repo onto a clean Ubuntu 24.04 server:

```bash
sudo bash ./scripts/bootstrap-ubuntu-24.sh
cp .env.example .env
nano .env
bash ./scripts/install.sh
```

The bootstrap script installs the host dependencies Nero expects:

- Docker Engine
- Docker Compose plugin
- git, curl, rsync, nano
- UFW with `OpenSSH`, `80/tcp`, and `443/tcp` allowed

## One-command install target

The installer is designed so this can later be wrapped as a one-liner like:

```bash
curl -fsSL https://your-domain/install-nero.sh | bash
```

For now it assumes the project files are already present on the VPS.

## Authentication

This stack intentionally uses OpenCode's built-in server auth instead of adding a second password layer at Traefik.

- `OPENCODE_SERVER_PASSWORD` secures the UI and API
- `OPENCODE_SERVER_USERNAME` defaults to `opencode`
- TLS is terminated at Traefik

Optional hardening you can add later:

- Cloudflare Access in front of the domain
- IP allowlists
- Fail2ban on the VPS

## Provider onboarding

The installer handles provider and model setup interactively so `.env.example` can stay minimal.

Current default path:

- provider: OpenAI
- model: `openai/gpt-5.4`

Why this default:

- Default to the newest OpenAI model for the shortest high-quality setup path
- OpenCode's built-in OpenAI provider works directly with Codex-capable models
- for a headless VPS install, prompting once for an OpenAI API key is the shortest usable setup flow

The installer currently supports:

- OpenAI
- Anthropic
- OpenRouter

## Domains

This initial scaffold exposes one hostname:

- `OPENCODE_DOMAIN` -> OpenCode web UI and API

The future admin service for integrations and permissions should be added as a second hostname, for example:

- `ADMIN_DOMAIN` -> admin UI

## Persistence

- OpenCode config: `config/opencode/`
- OpenCode data: `data/opencode/`
- Traefik ACME data: `data/traefik/`
- Agent workspace: `workspace/agent/`

## Notes

- The container starts OpenCode in `/workspace/agent`
- The default model is configured from installer onboarding via `OPENCODE_MODEL`
- `AGENTS.md` gives the instance a default personality inspired by OpenClaw's `SOUL.md` style
- The default OpenCode permissions config is conservative and asks before sensitive actions
- SSL uses the Cloudflare DNS challenge, so certificate renewal stays automatic
