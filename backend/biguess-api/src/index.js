export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Standard CORS headers
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
      return Response.json({ status: "ok", timestamp: new Date().toISOString() }, { headers: corsHeaders });
    }

    // GET /records - Fetch latest 50 records
    if (request.method === "GET" && url.pathname === "/records") {
      try {
        const { results } = await env.biguess_db
          .prepare("SELECT * FROM game_records ORDER BY created_at DESC LIMIT 50")
          .all();
        return Response.json(results || [], { headers: corsHeaders });
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
          return Response.json(
            { error: "Missing required fields: topic, pack, winner, totalTurns" },
            { status: 400, headers: corsHeaders }
          );
        }

        const info = await env.biguess_db
          .prepare(
            "INSERT INTO game_records (topic, pack, winner, total_turns, duration_seconds) VALUES (?, ?, ?, ?, ?)"
          )
          .bind(topic, pack, winner, totalTurns, durationSeconds || 0)
          .run();

        return Response.json(
          {
            success: true,
            id: info.meta.last_row_id,
          },
          { status: 201, headers: corsHeaders }
        );
      } catch (err) {
        return Response.json({ error: err.message }, { status: 500, headers: corsHeaders });
      }
    }

    return new Response("Not Found", { status: 404, headers: corsHeaders });
  },
};
