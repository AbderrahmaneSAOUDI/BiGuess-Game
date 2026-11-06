---
name: backend-development
description: Change or debug BiGuess's optional Cloudflare Worker/D1 game-record API and its Dart client, including JSON contracts, local development, and offline isolation.
---

# Develop the game-record API

Use this skill for `backend/biguess-api/`, `CloudDatabaseService`, or `GameRecord`. Read `.agents/sidecars/integrations.md` for boundaries and current limitations. The service/provider currently has no gameplay call sites; do not assume records are uploaded or queued offline.

## Locate the contract

| Responsibility | Source |
| --- | --- |
| HTTP routing, CORS, validation, SQL | `backend/biguess-api/src/index.js` |
| D1 binding `biguess_db` | `backend/biguess-api/wrangler.json` |
| Table/index creation | `backend/biguess-api/schema.sql` |
| Dart HTTP client and injectable Dio | `lib/services/cloud_database_service.dart` |
| Request/response conversion | `lib/domain/models/game_record.dart` |
| Existing Dart checks | `test/unit/cloud_database_service_test.dart` |

`POST /records` accepts `topic`, `pack`, `winner`, `totalTurns`, and optional `durationSeconds`; success is HTTP 201 with `success` and `id`. `GET /records` returns up to 50 rows ordered by `created_at DESC`, including `total_turns`, `duration_seconds`, and `created_at`. Preserve this camelCase request/snake_case row boundary. `GameRecord.fromJson` also accepts camelCase numeric fields and string numbers.

## Local workflow

From `backend/biguess-api/`, use the package's actual scripts:

```bash
npm install
npm run dev
```

If dependencies are already installed, skip installation. There is no lockfile or backend test script in the checked-in package. Consult the installed `npx wrangler d1 execute --help` to initialize `schema.sql` against the **local** database; do not copy the `--remote` provisioning example from `cloudflare.md` for local testing.

Exercise the local server's reported URL for health, an empty/recent records list, a valid insert followed by a read, missing required fields, malformed JSON, unknown routes, preflight OPTIONS, and database failures. Check both status and response body. The health route reports process health without querying D1.

For a contract change, update the Worker, schema if necessary, Dart codec, service expectations, and focused tests together. Use injected `Dio` or `baseUrl` for client tests; avoid production requests. Core character selection/countdown must remain independent of API availability.

## Validation and delivery

```bash
flutter test test/unit/cloud_database_service_test.dart
```

Add behavioral tests for changes to routing/serialization/error handling. Existing tests cover model serialization and service construction; they do not verify HTTP behavior. Run the full Flutter suite before completion. `npm run deploy` publishes the Worker; schema application with `--remote` mutates D1. Use them only when deployment/database changes are in the user's authorized scope.

The current Worker permits wildcard CORS, has no authentication/rate-limit layer, and validates presence rather than complete types/ranges. Record these as existing properties when relevant; do not silently expand a small backend task into a security redesign.
