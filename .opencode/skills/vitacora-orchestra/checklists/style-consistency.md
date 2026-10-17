# Style Consistency — token map & forbidden list

## Palette (from SPEC.md / app.css) — never hardcode hex in components

- Backgrounds: --bg #0f1117, --bg2 #161b25, --bg3 #1e2535, --surface #242b3d,
  --surface2 #2e3650, --border #333d57
- Text: --text #e8eaf0, --text2 #9aa3bd, --text3 #636d8a
- Accents: --accent-green #73e7bd, --accent-yellow #ebd57f, --accent-orange #ee9863,
  --accent-blue #5d99ee, --accent-purple #9294f5, --accent-red #ee8888

## Typography & spacing

- Fonts via variables: --font-display (Syne), --font-body (DM Sans), --font-mono (Space Mono).
- Main content padding 32px; radius 10px (small) / 16px (large); sidebar 240px.
- Breakpoints honored today: mobile <640px, tablet 640–900px, desktop >900px,
  dashboard bento ≥1280px.

## Reusable primitives

- Buttons: btn-primary / btn-secondary / btn-ghost; card + card-title patterns;
  modal-backdrop pattern; small-btn for inline actions.

## Forbidden / do-not-touch (pre-existing debt, report as NIT only)

- PieChart.svelte hardcoded hex palette and its `chart: any` — do not reformat around
  them; leave as-is unless the brief says otherwise.
- Global md-* checkbox styles are global on purpose.
- Do not refactor other components' styles "in passing".
