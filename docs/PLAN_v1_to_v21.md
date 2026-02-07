# Planning Evolution (v1 -> v21)

## v1 Baseline
- Native macOS app with SwiftUI + Xcode project
- 3-route simultaneous search
- Trip + bag + regular filters
- Airline + metasearch/OTA coverage
- Cheapest/quality comparison

## v2-v21 Refinements
1. Domain/engine/provider/UI separation
2. Capability matrix per provider
3. Bounded concurrency and anti-throttling behavior
4. Retry/backoff/timeout policies
5. Login/captcha-aware statuses
6. Cross-source deduping
7. Normalized fare model hooks
8. Currency normalization scaffold
9. Route-level progress streaming
10. User profile/preset readiness
11. Watchlist-ready architecture
12. Full provider registry from supplied list
13. Deep-link handoff for brittle providers
14. Extraction pipeline abstraction
15. Offer audit metadata path
16. Observability counters path
17. Deterministic no-AI learning mode
18. Unit test coverage on core logic
19. Versioned commit/push workflow
20. Defer bold visual system pass until functional completeness
