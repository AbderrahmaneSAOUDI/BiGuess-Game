# Cloudflare D1 Database Integration for BiGuess

## 1. Database Configuration
Your D1 database is created:

```json
{
  "d1_databases": [
    {
      "binding": "biguess_db",
      "database_name": "biguess-db",
      "database_id": "2b192cea-fd0c-4393-8449-15e4accd323e"
    }
  ]
}
```

Equivalent `wrangler.toml` format:
```toml
[[d1_databases]]
binding = "biguess_db"
database_name = "biguess-db"
database_id = "2b192cea-fd0c-4393-8449-15e4accd323e"
```

---

## 2. Define the Database Schema

Create a SQL migration file (e.g. `schema.sql`):

```sql
-- Game match records table
CREATE TABLE IF NOT EXISTS game_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    pack TEXT NOT NULL,
    winner TEXT NOT NULL,
    total_turns INTEGER NOT NULL,
    duration_seconds INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for fast topic/pack filtering
CREATE INDEX IF NOT EXISTS idx_records_topic_pack ON game_records(topic, pack);
```

### Apply Schema to Remote D1:
Run this command from your terminal:
```bash
npx wrangler d1 execute biguess-db --file=./schema.sql --remote
```

---

## 3. Set Up the Cloudflare Worker API

Because Flutter client apps communicate with Cloudflare D1 via HTTPS, create a Worker to serve as the secure API layer.

### Create Worker Directory
```bash
mkdir -p backend/biguess-api
cd backend/biguess-api
npm init -y
npm install wrangler --save-dev
```

### Create `wrangler.json`
Inside `backend/biguess-api/wrangler.json`:
```json
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "biguess-api",
  "main": "src/index.js",
  "compatibility_date": "2024-04-01",
  "d1_databases": [
    {
      "binding": "biguess_db",
      "database_name": "biguess-db",
      "database_id": "2b192cea-fd0c-4393-8449-15e4accd323e"
    }
  ]
}
```

### Create Worker Handler (`src/index.js`)
Inside `backend/biguess-api/src/index.js`:
```javascript
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // CORS headers for mobile and web requests
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    // Health check endpoint
    if (url.pathname === "/health") {
      return Response.json({ status: "ok" }, { headers: corsHeaders });
    }

    // GET /records - Fetch latest 50 records
    if (request.method === "GET" && url.pathname === "/records") {
      try {
        const { results } = await env.biguess_db
          .prepare("SELECT * FROM game_records ORDER BY created_at DESC LIMIT 50")
          .all();
        return Response.json(results, { headers: corsHeaders });
      } catch (err) {
        return Response.json({ error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    // POST /records - Insert a completed game result
    if (request.method === "POST" && url.pathname === "/records") {
      try {
        const data = await request.json();
        const { topic, pack, winner, totalTurns, durationSeconds } = data;

        if (!topic || !pack || !winner || totalTurns === undefined) {
          return Response.json({ error: "Missing required fields" }, { status: 400, headers: corsHeaders });
        }

        await env.biguess_db
          .prepare(
            "INSERT INTO game_records (topic, pack, winner, total_turns, duration_seconds) VALUES (?, ?, ?, ?, ?)"
          )
          .bind(topic, pack, winner, totalTurns, durationSeconds || 0)
          .run();

        return Response.json({ success: true }, { status: 201, headers: corsHeaders });
      } catch (err) {
        return Response.json({ error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    return new Response("Not Found", { status: 404, headers: corsHeaders });
  }
};
```

---

## 4. Deploy the Worker
Deploy your API directly to Cloudflare's global edge network (Free tier):
```bash
npx wrangler deploy
```

Wrangler will output your live URL:
`https://biguess-api.<your-account-subdomain>.workers.dev`

---

## 5. Flutter Integration (`BiGuess-Game`)

In the Flutter app, use `Dio` (already present in `pubspec.yaml`) to interact with your Worker endpoint:

```dart
import 'package:dio/dio.dart';

class CloudDatabaseService {
  final Dio _dio;

  // Replace with your deployed Worker URL
  static const String _defaultBaseUrl = 'https://biguess-api.<your-account-subdomain>.workers.dev';

  CloudDatabaseService({Dio? dio, String baseUrl = _defaultBaseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  /// Fetch recent game records
  Future<List<Map<String, dynamic>>> fetchRecords() async {
    try {
      final response = await _dio.get('/records');
      return List<Map<String, dynamic>>.from(response.data as List);
    } on DioException catch (e) {
      throw Exception('Failed to load records from Cloudflare D1: ${e.message}');
    }
  }

  /// Save game result after a duel ends
  Future<void> saveGameRecord({
    required String topic,
    required String pack,
    required String winner,
    required int totalTurns,
    int durationSeconds = 0,
  }) async {
    try {
      await _dio.post('/records', data: {
        'topic': topic,
        'pack': pack,
        'winner': winner,
        'totalTurns': totalTurns,
        'durationSeconds': durationSeconds,
      });
    } on DioException catch (e) {
      throw Exception('Failed to save record to Cloudflare D1: ${e.message}');
    }
  }
}
```
