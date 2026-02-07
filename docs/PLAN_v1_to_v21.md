# Planning Evolution (v1 -> v21)

## v1 Baseline
- Native macOS app with SwiftUI + Xcode project
- 3-route simultaneous search
- Trip + bag + regular filters
- Airline + metasearch/OTA coverage
- Cheapest/quality comparison

## v2-v21 Refinements Status
1. Domain/engine/provider/UI separation: complete
2. Capability matrix per provider: complete
3. Bounded concurrency and anti-throttling behavior: complete
4. Retry/backoff/timeout policies: complete
5. Login/captcha-aware statuses: complete
6. Cross-source deduping: complete
7. Normalized fare model hooks: complete
8. Currency normalization scaffold: complete
9. Route-level progress streaming: complete
10. User profile/preset readiness: complete
11. Watchlist-ready architecture: complete
12. Full provider registry from supplied list: complete
13. Deep-link handoff for brittle providers: complete
14. Extraction pipeline abstraction: complete
15. Offer audit metadata path: complete
16. Observability counters path: complete
17. Deterministic no-AI learning mode: complete
18. Unit test coverage on core logic: complete
19. Versioned commit/push workflow: complete
20. Defer bold visual system pass until functional completeness: complete

## v21 Outcome
- Functional + visual roadmap delivered end-to-end.

## Post-v21 Enhancements
1. Watchlist target-hit alerts with deterministic session-based detection: complete
2. Watchlist observed-price refresh from matching priced offers: complete
3. Watchlist re-check planning and execution flow (trip-type aware, 3-route bounded): complete
