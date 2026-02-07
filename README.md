# FlightFinder (macOS)

FlightFinder is a native macOS SwiftUI app that compares flight options across airline websites, metasearch providers, OTAs, and China-focused portals.

## Functional Scope

- Search up to 3 routes simultaneously.
- One-way and round-trip.
- Passenger mix, cabin class, bag options, nonstop toggle, max stops, flexible days.
- Scenario presets (`US West Coast`, `USA to Shanghai`, `US Triangle`) for fast setup.
- Persistent defaults for routes/options/provider kinds between app launches.
- Provider types can be enabled/disabled: Airline, Metasearch, OTA, China Portal.
- Results are ranked by normalized score (price, stops, confidence, and availability state).
- Cross-source offer deduplication before ranking.
- Session and route observability counters (attempts, dedupe counts, status mix, average latency).
- Offer-level audit trail metadata path (provider mode/status/timing per attempt).
- Persistent watchlist entries with merge/update behavior from best priced route offers.
- In-app watchlist target-hit alerts with open/dismiss controls and auto-refresh of observed prices.
- One-click watchlist re-check planner (trip-type aware, deterministic, capped to 3 concurrent routes).
- Optional auto watchlist re-check scheduler (configurable interval) with local desktop target-hit notifications.
- China accessibility diagnostics panel with one-click probe sweeps and ranked reachability snapshots by provider.
- Status-aware outputs: priced, handoff required, login required, unavailable.

## UI System

- Flat, bold, geometric SwiftUI interface with strict no-shadow styling.
- Tokenized palette and typography aligned to the provided design system.
- Dedicated UI planning evolution doc: `docs/UI_PLAN_v1_to_v21.md`.

## China Accessible Sites Mode

- Adds a dedicated mode for China-aware searching.
- Runs provider reachability probes and stores historical outcomes locally.
- Learns without AI models using deterministic scoring from observed probe success/failure.
- Prioritizes and filters providers using blended seed + learned reachability.
- Surfaces China reachability score in results.
- Adds an explicit "Probe Sites" sweep to test currently enabled provider categories and update local learning stats.

## Provider Coverage

Includes your provided provider set plus a China-focused expansion inspired by:

- https://routesofchina.com/booking-platforms-for-cheap-flights-to-china/

## Build and Test

```bash
xcodegen generate
xcodebuild -project FlightFinder.xcodeproj \
  -scheme FlightFinder \
  -destination 'platform=macOS' \
  -derivedDataPath .derivedData \
  test
```

## Skills Integration

This repo includes skill-oriented tooling aligned to the VoltAgent skills catalog:

- `scripts/install_recommended_skills.sh` installs the recommended skills set.
- `scripts/validate_with_skills.sh` runs build/test verification plus optional browser checks.
- `scripts/provider_smoke_playwright.mjs` performs provider reachability smoke tests.
- `docs/SKILLS_PLAYBOOK.md` explains skill usage and workflow.

## Notes

- This build disables code signing for local development in this environment.
- Some providers need interactive login/captcha; the app surfaces handoff/login states and deep links.
