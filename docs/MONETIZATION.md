# Monetization Plan (Cover Hosting Early)

## Priority model: Affiliate + Pro tier

1. Affiliate links on outbound provider handoff (fastest cash path)
2. Pro subscription for power users (alerts + saved presets + automation)
3. B2B/API access for travel agents later

## What is already implemented

- API can append affiliate tracking params to selected providers via env vars.
- Configure values in `web/.env.example`.

## Monthly break-even math (example)

Estimated early monthly costs:

- app host (Render/Railway starter): `$7-$25`
- domain + DNS + misc tooling: `$3-$10`
- total: **~$15-$35/month**

Break-even examples:

- At `$7` average affiliate commission per booking: `3-5 bookings/month` covers hosting
- At `$12` Pro plan: `2-3 subscribers/month` covers hosting
- Hybrid: `2 bookings + 1 subscriber` usually covers base stack

## Suggested pricing ladder

- Free: 3 routes, manual searches, standard deep links
- Pro (`$9-$15/month`):
  - persistent watchlist + automatic re-check schedules
  - price-drop notifications
  - China mode advanced analytics history
- Team (`$29-$79/month`): shared workspaces and exported reports

## First 30-day revenue sprint

1. Integrate real affiliate IDs for Trip.com + at least one metasearch source.
2. Add click tracking by provider (which source converts best).
3. Launch to one niche audience first:
   - USA->China frequent flyers
   - international students/families
4. Offer annual plan discount after first 10 paid users.

## Risk controls

- Keep terms clear: pricing shown is estimated until booking handoff confirmation.
- Respect each provider's affiliate and automation terms.
- Add consent + privacy policy before paid launch.
