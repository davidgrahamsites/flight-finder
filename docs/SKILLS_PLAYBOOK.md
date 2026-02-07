# FlightFinder Skills Playbook

This project now uses a curated subset from the VoltAgent awesome-agent-skills list that directly supports FlightFinder development.

## Installed Skills

- `frontend-design` (anthropics/skills)
- `webapp-testing` (anthropics/skills)
- `mcp-builder` (anthropics/skills)
- `playwright-skill` (lackeyjb/playwright-skill)
- `swiftui-expert-skill` (AvdLee/SwiftUI-Agent-Skill)
- `swift-patterns` (efremidze/swift-patterns-skill)
- `verification-before-completion` (obra/superpowers)
- `test-driven-development` (obra/superpowers)

## Why These Skills

- Browser automation and E2E testing are required for provider-site checks.
- SwiftUI architecture and pattern skills improve maintainability of the macOS app.
- Verification and TDD skills enforce reliable delivery quality.
- MCP builder gives a path to exposing provider operations through MCP tools.

## Project Integrations Added

- `scripts/install_recommended_skills.sh`
  - Reinstalls this exact skills set on any machine.

- `scripts/provider_smoke_playwright.mjs`
  - Runs browser reachability checks against flight providers.
  - Supports `--china-mode` to validate China-oriented targets.

- `config/provider-smoke.targets.json`
  - Centralized provider targets for smoke checks.

- `scripts/validate_with_skills.sh`
  - Runs project generation + tests.
  - Optionally runs Playwright smoke checks if Playwright is available.

## Typical Workflow

1. Install/refresh skills:
   - `./scripts/install_recommended_skills.sh`
2. Restart Codex.
3. Validate project:
   - `./scripts/validate_with_skills.sh`
4. If browser checks fail, inspect `docs/provider_smoke_latest.json`.

## Notes

- Playwright smoke checks require Node + Playwright in the local environment.
- Skills are installed in `~/.codex/skills` and are not checked into this repo.
