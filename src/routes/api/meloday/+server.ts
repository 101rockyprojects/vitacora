import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

const UPSTREAM = 'https://meloday.rockybarrios10.workers.dev/api/v1/';

export const GET: RequestHandler = async () => {
  try {
    const res = await fetch(UPSTREAM, {
      headers: {
        accept: 'application/json'
      }
    });

    if (!res.ok) {
      return json({ error: `Upstream error: HTTP ${res.status}` }, { status: 502 });
    }

    const data = await res.json();
    return json(data, {
      headers: {
        'cache-control': 'public, max-age=60'
      }
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Upstream fetch failed';
    return json({ error: message }, { status: 502 });
  }
};

