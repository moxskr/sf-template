# Agent guidance — Salesforce DX template

Shared instructions for Cursor, Claude Code, Codex, and other agents working in this repository.

## Project context

- Salesforce DX **source-format** project; default package directory is `force-app/`.
- API version is defined in `sfdx-project.json` (`sourceApiVersion`). Match new metadata to that version.
- Prefer the modern `sf` CLI over legacy `sfdx` commands.
- Auth and local org state live under `.sf/` / `.sfdx/` — never commit them, tokens, or credentials.

## Default models (project pins)

| Agent | Default |
|-------|---------|
| Claude Code | `claude-sonnet-5`, effort `medium` (see `.claude/settings.json`) |
| Codex | `gpt-5.6-sol`, reasoning `medium`, personality `pragmatic` (see `.codex/config.toml`) |
| Cursor IDE | No stable project-level model pin; prefer Composer / Auto in the UI. CLI permissions live in `.cursor/cli.json`. |

## Salesforce DX constraints

- Work in source format under `force-app`; do not invent alternate project layouts without an explicit ask.
- Use scratch orgs for ephemeral feature work; treat sandboxes/production as higher-risk and require explicit confirmation before deploy.
- Deploy/retrieve through the DX project (CLI or Salesforce DX MCP), not ad-hoc Metadata API scripts, unless the task requires it.
- Never hard-code secrets, Connected App secrets, passwords, or session IDs in source, scripts, or agent configs.
- Keep `.forceignore`, lint, Prettier, and Husky pre-commit behavior intact; fix failures rather than bypassing hooks.
- Prefer plan → generate metadata → deploy → test → fix over large speculative rewrites.

## Apex (2026)

- Default to `with sharing` unless there is a documented reason for `without sharing`.
- Bulkify everything: no SOQL/DML/SOSL inside loops; prefer maps/sets and single-pass collection handling.
- Respect governor limits; design for bulk trigger and async volumes.
- Avoid SOQL injection: bind variables; do not concatenate untrusted input into dynamic queries.
- Use meaningful test classes (`@IsTest`, `SeeAllData=false`), assert behavior (not only coverage), and cover positive, negative, and bulk paths for non-trivial logic.
- For non-trivial domains, prefer selector / service / domain-style separation over “god” classes and triggers with mixed concerns.
- Prefer clear, platform-idiomatic Apex over clever abstractions that obscure governor usage.

## Lightning Web Components (2026)

- Prefer Lightning base components and SLDS patterns before custom UI primitives.
- Keep `@api` surface small and intentional; avoid unnecessary reactivity/`@track` on primitives.
- Use `@wire` for reactive cacheable reads; use imperative Apex for user-driven or non-cacheable calls.
- Do not scrape or depend on undocumented Salesforce internal DOM.
- Add Jest unit tests for non-trivial JS logic; keep HTML/CSS accessible (labels, keyboard, contrast).
- Colocate component metadata (`.js`, `.html`, `.css`, `.js-meta.xml`) and follow existing LWC folder conventions.

## Skills and MCP

- Salesforce agent skills live under `.agents/skills/` (canonical). Agent-specific skill dirs are symlinks.
- Refresh skills (project-local):

```bash
npx skills add forcedotcom/sf-skills -a claude-code -a cursor -a codex -s '*' -y
```

- MCP: Salesforce DX is configured in `.mcp.json` (Claude) and `.cursor/mcp.json` (symlink). Codex uses `.codex/config.toml` (`mcp_servers.salesforce_dx`).
- Before inventing metadata by hand, prefer Salesforce skills and DX MCP tools (orgs, metadata, data, users/permission sets, LWC experts, testing, code analysis).
- MCP requires a locally authorized default org / Dev Hub, for example:

```bash
sf org login web --alias my-org
sf config set target-org my-org
# optional Dev Hub
sf config set target-dev-hub my-devhub
```

## Agent operating constraints

- Prefer small, reviewable diffs scoped to the request.
- Do not deploy to production or unexpected default orgs without an explicit user ask.
- After Apex or LWC changes, run relevant tests (`sf apex run test`, LWC Jest) when practical.
- Do not disable security, sharing, or CRUD/FLS checks “for convenience.”
- If requirements are ambiguous for org-impacting work (scratch vs sandbox, object model, permissions), ask before large generation or deploy.
