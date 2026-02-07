# FlightFinder (macOS)

FlightFinder is a native macOS SwiftUI app that compares flight options across airline websites, metasearch providers, OTAs, and China-focused portals.

## Functional Scope

- Search up to 3 routes simultaneously.
- One-way and round-trip.
- Passenger mix, cabin class, bag options, nonstop toggle, max stops, flexible days.
- Provider types can be enabled/disabled: Airline, Metasearch, OTA, China Portal.
- Results are ranked by normalized score (price, stops, confidence, and availability state).
- Status-aware outputs: priced, handoff required, login required, unavailable.

## China Accessible Sites Mode

- Adds a dedicated mode for China-aware searching.
- Runs provider reachability probes and stores historical outcomes locally.
- Learns without AI models using deterministic scoring from observed probe success/failure.
- Prioritizes and filters providers using blended seed + learned reachability.
- Surfaces China reachability score in results.

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
