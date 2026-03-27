# nero

Dockerized OpenCode for a VPS with:

- Traefik reverse proxy when Nero owns `80/443`
- automatic fallback for boxes that already have a reverse proxy
- automatic Let's Encrypt SSL via Cloudflare DNS challenge
- OpenCode web UI exposed on a custom domain
- built-in OpenCode HTTP basic auth for both the UI and API
- persistent agent workspace mounted from the host

## Why this setup

Current OpenCode docs support protecting `opencode serve` and `opencode web` with:

- `OPENCODE_SERVER_PASSWORD`
- optional `OPENCODE_SERVER_USERNAME`

That means the simplest internet-safe default is:

1. Nero uses Traefik when the VM owns ports `80/443`, otherwise it reuses the existing reverse proxy
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
   - auth method for the provider
   - provider API key only if you choose API-key auth
5. Open `https://<your-domain>`
6. If you chose OpenAI subscription auth, run `/connect` in OpenCode and select `OpenAI` -> `ChatGPT Plus/Pro`

The installer now also:

- fixes ownership on mounted OpenCode directories automatically
- detects when ports `80/443` are already in use
- skips Nero Traefik automatically on boxes that already have another proxy

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

## Proxy modes

Nero supports two install modes automatically:

- `self`: Nero starts Traefik and manages TLS itself
- `external`: another proxy already owns `80/443`, so Nero only starts OpenCode on `127.0.0.1:4096`

When `external` mode is detected, point your existing proxy at `127.0.0.1:4096` for the Nero hostname.

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
- auth: ChatGPT Plus/Pro subscription via `/connect`

Why this default:

- Default to the newest OpenAI model for the shortest high-quality setup path
- OpenCode supports OpenAI account auth via `/connect` using `ChatGPT Plus/Pro`
- provider credentials are stored by OpenCode in persistent auth storage instead of forcing an API key into `.env`
- API keys still work, but subscription auth is the cleaner default when you already have the Codex/ChatGPT plan

The installer currently supports:

- OpenAI subscription auth
- OpenAI API key
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
- OpenCode provider credentials from `/connect` are persisted in the mounted data directory
- Mounted config/data/workspace directories are auto-owned by the `opencode` container user during install
- `AGENTS.md` gives the instance a default personality inspired by OpenClaw's `SOUL.md` style
- The default OpenCode permissions config is conservative and asks before sensitive actions
- SSL uses the Cloudflare DNS challenge, so certificate renewal stays automatic
