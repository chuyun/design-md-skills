# DESIGN.md Catalog Guide

Use this guide for quick style family selection before opening a specific `DESIGN.md`.

## Category Shortlist

AI and machine learning:
- `claude`, `cohere`, `elevenlabs`, `minimax`, `mistral.ai`, `ollama`, `opencode.ai`, `replicate`, `runwayml`, `together.ai`, `voltagent`, `x.ai`

Developer tools and platforms:
- `cursor`, `expo`, `linear.app`, `lovable`, `mintlify`, `posthog`, `raycast`, `resend`, `sentry`, `supabase`, `vercel`, `warp`, `zapier`

Infrastructure and cloud:
- `clickhouse`, `composio`, `hashicorp`, `mongodb`, `sanity`, `stripe`

Design and productivity:
- `airtable`, `cal`, `clay`, `figma`, `framer`, `intercom`, `miro`, `notion`, `pinterest`, `webflow`

Fintech and crypto:
- `coinbase`, `kraken`, `revolut`, `wise`

Enterprise and consumer:
- `airbnb`, `apple`, `ibm`, `nvidia`, `spacex`, `spotify`, `uber`

Car brands:
- `bmw`, `ferrari`, `lamborghini`, `renault`, `tesla`

## Fast Matching Heuristics

If request emphasizes minimal, code-first, monochrome:
- Start with `vercel`, `linear.app`, `cursor`, `stripe`

If request emphasizes premium editorial and whitespace:
- Start with `apple`, `notion`, `ferrari`

If request emphasizes energetic dark visuals and neon accents:
- Start with `nvidia`, `raycast`, `tesla`, `superhuman`

If request emphasizes friendly consumer conversion:
- Start with `airbnb`, `intercom`, `webflow`, `zapier`

If request emphasizes dashboards and data density:
- Start with `sentry`, `posthog`, `kraken`, `coinbase`

## Canonical Sources

- Collection root: `design-md/`
- Style file: `design-md/<slug>/DESIGN.md`
- Preview files: `design-md/<slug>/preview.html`, `design-md/<slug>/preview-dark.html`

## Keep This Guide Current

Run these commands whenever new styles are added:

```bash
bash skills/design-md-router/scripts/list_styles.sh --count
bash skills/design-md-router/scripts/validate_library.sh
```
