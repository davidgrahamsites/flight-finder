# UI Planning Evolution (v1 -> v21)

## v1 Baseline
- Keep all existing functional controls visible and searchable.
- Preserve a two-pane desktop layout: configuration on the left, results on the right.
- Use a flat visual language with no shadows and clear color blocks.

## Iterative Improvements
1. Define strict color tokens from the provided palette (`Background`, `Foreground`, `Primary`, `Secondary`, `Accent`, `Muted`, `Border`).
2. Introduce a hero banner section to communicate app purpose and route limits at a glance.
3. Convert generic section boxes into poster-style color blocks with clear spacing hierarchy.
4. Add a visual “Search Presets” strip for one-click scenarios (`US West Coast`, `USA to Shanghai`, `US Triangle`).
5. Emphasize route editor cards with stronger labels, larger input hit areas, and consistent corner radii.
6. Rework trip/site mode toggles into segmented controls with stronger typography contrast.
7. Separate passenger and bag controls into distinct grouped blocks for scanability.
8. Convert provider kind toggles into high-contrast chips with instant state feedback.
9. Add clear status messaging for China-access mode and learning behavior.
10. Upgrade action bar with primary/secondary button contrast and stronger disabled states.
11. Surface route-level progress as dedicated progress cards rather than inline thin bars.
12. Add route result headers with key metadata (dates, best offer) before listing offers.
13. Add compact status badges (`Priced`, `Login Needed`, etc.) with semantic colors and no depth effects.
14. Normalize all paddings/margins to a strict 4pt grid rhythm for consistency.
15. Add decorative low-opacity geometric background elements for visual identity.
16. Replace default typography hierarchy with geometric, bold-forward sizing strategy aligned to Outfit.
17. Add subtle scale/color hover interactions for chips, cards, and action buttons.
18. Improve keyboard and accessibility states with explicit high-contrast focus rings.
19. Ensure responsive behavior for smaller desktop widths without collapsing critical controls.
20. Perform final contrast and usability pass so style changes never reduce functional clarity.

## v21 Final Direction
- Flat, bold, geometric macOS UI.
- Strong color blocking with no shadows.
- Fast scan, fast edit, fast launch workflow.
- Functional parity with clearer hierarchy and a more distinctive brand identity.
