---
name: tankerkoenig-api
description: Summarizes the free Tankerkönig JSON API (endpoints, parameters, response shapes, rate limits, licensing, and decoding pitfalls). Use when integrating German fuel station prices, implementing TankerkoenigClient or Station decoding, or when the user mentions Tankerkönig, Tankerkoenig, MTS-K, list.php, prices.php, detail.php, or creativecommons.tankerkoenig.de.
---

# Tankerkönig API

Primary reference: [API information (Tankerkönig)](https://creativecommons.tankerkoenig.de/?page=info).

## Base URL

JSON endpoints live under:

`https://creativecommons.tankerkoenig.de/json/`

## Operations

| Method | HTTP | Purpose |
|--------|------|---------|
| `list.php` | GET | Stations + prices in radius around `lat`/`lng` |
| `prices.php` | GET | Current prices for up to **10** station UUIDs (`ids` comma-separated) |
| `detail.php` | GET | Extra fields for one station (`openingTimes`, `overrides`, `wholeDay`, `state`, …) — not for high-frequency polling |
| `complaint.php` | POST | Forward data corrections to MTS-K via Tankerkönig |

All calls require `apikey` (UUID). Responses are JSON and include an **`ok`** boolean — **always validate `ok`** before using payloads; on failure expect e.g. `{ "ok": false, "message": "parameter error" }`.

## `list.php` parameters

- `lat`, `lng` — search center (float)
- `rad` — radius in km, **max 25**
- `type` — `'e5'`, `'e10'`, `'diesel'`, or `'all'`
- `sort` — `price` or `dist` (with `type=all`, sorting defaults to distance)
- `apikey`

### Response shape

Top-level includes `license`, `data`, `status`, and **`stations`** (array of station objects).

Typical station fields: `id` (UUID string), `name`, `brand`, `street`, `place`, `lat`, `lng`, `dist` (km), `diesel`, `e5`, `e10` (prices in EUR/liter as floats in list responses), `isOpen`, `houseNumber`, `postCode` (often integer in JSON).

**Important:** If `type` is **not** `all`, the JSON uses a single field **`price`** for the requested grade instead of naming `e5` / `e10` / `diesel` explicitly.

## `prices.php`

- `ids` — up to 10 UUIDs, comma-separated  
- `apikey`

`prices` is an object keyed by station UUID. Each value has:

- `status`: `"open"` | `"closed"` | `"no prices"`
- `e5`, `e10`, `diesel`: **either a number or boolean `false`** when that grade is not sold — clients must decode both.

## `detail.php`

- `id` — station UUID  
- `apikey`

Returns `station` with opening hours (`openingTimes`: `{ text, start, end }[]`), `overrides` (strings), `wholeDay`, optional `state`, plus coordinates and price fields.

## Rate limits and etiquette (free tier)

Documentation states constraints including **search radius capped at 25 km**, a **low per-minute request budget** for the free API, and **best-effort** availability. For home automation–style use it recommends **not polling more than once per ~5 minutes**, jittering away from round clock times, and using **`list.php` / `prices.php`** to batch updates instead of hammering `detail.php`. Bulk mirroring of all stations is discouraged; commercial/offline mirroring needs separate agreement with Tankerkönig.

## Licensing and eligibility

Responses carry **CC BY 4.0** licensing metadata (`license` field). Follow Tankerkönig’s attribution and terms on the info page. The free API **must not** be used by mineral oil companies, station operators (and related entities), or IT vendors serving that industry; keys may be blocked.

## Secrets

Never commit real API keys or paste them into public repos/snippets — use placeholders and local config (see project `APIKeys` patterns).

## Before implementing Linear tickets (Tankerkönig-related)

When a ticket touches this API or derived models:

1. Re-read this skill and reconcile the ticket’s scope and acceptance criteria with it (and with [the official info page](https://creativecommons.tankerkoenig.de/?page=info) if anything is ambiguous).
2. If the ticket assumes wrong endpoints, fields, limits, or behaviors, **update the Linear issue** (description / acceptance criteria) before or as you start coding, and note the fix in a short Linear comment.

Project rule: `.cursor/rules/tankerkoenig-ticket-precheck.mdc`.

## Implementation notes (this repo)

- Domain models: `TankRadar/Models/FuelType.swift`, `TankRadar/Models/Station.swift`.
- `Station` decoding treats `prices.php`-style `false` fuel prices as absent (`nil`).
- **`list.php` with a single `type`:** responses use **`price`**, not separate `e5`/`e10`/`diesel` keys — align clients and tickets if they assume only the multi-key shape.

## Further reading

- Full parameter tables, `complaint.php` fields, and examples: [Tankerkönig API info](https://creativecommons.tankerkoenig.de/?page=info).
