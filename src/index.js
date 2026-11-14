/**
 * NYIT Pool — Cloudflare Worker entry point.
 *
 * Routing:
 *   /api/*  -> handled here (future home of the Table Queue backend)
 *   *       -> static assets from public/ (the pool timer SPA)
 *
 * Env bindings (see wrangler.jsonc):
 *   env.ASSETS — Static Assets binding
 *   env.DB     — D1 database (Table Queue storage, placeholder)
 */

const json = (data, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });

async function handleApi(request, env, url) {
  const { pathname } = url;
  const method = request.method;

  // liveness probe
  if (pathname === '/api/health') {
    return json({ ok: true, time: new Date().toISOString() });
  }

  // ---- Table Queue placeholder endpoints (wired to D1 once the feature ships) ----
  if (pathname === '/api/queue') {
    if (!env.DB) return json({ error: 'D1 not bound' }, 501);

    if (method === 'GET') {
      const { results } = await env.DB
        .prepare('SELECT id, team_name, players, status, created_at FROM queue_entries ORDER BY id')
        .all();
      return json({ queue: results });
    }

    if (method === 'POST') {
      const body = await request.json().catch(() => null);
      const team = typeof body?.team_name === 'string' ? body.team_name.trim().slice(0, 32) : '';
      if (!team) return json({ error: 'team_name required' }, 400);
      const { meta } = await env.DB
        .prepare('INSERT INTO queue_entries (team_name, players) VALUES (?, ?)')
        .bind(team, typeof body?.players === 'string' ? body.players.slice(0, 128) : '')
        .run();
      return json({ ok: true, id: meta.last_row_id }, 201);
    }

    return json({ error: 'method not allowed' }, 405);
  }

  return json({ error: 'not found' }, 404);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname.startsWith('/api/')) {
      try {
        return await handleApi(request, env, url);
      } catch (err) {
        return json({ error: 'internal error', detail: String(err?.message || err) }, 500);
      }
    }

    // everything else: static assets (public/)
    return env.ASSETS.fetch(request);
  },
};
