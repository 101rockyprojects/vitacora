import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

const UPSTREAM = 'https://meloday.rockybarrios10.workers.dev/api/v1';

export const GET: RequestHandler = async () => {
  try {
    const candidates = [UPSTREAM, `${UPSTREAM}/`];
    let res: Response | null = null;
    let lastUrl: string | null = null;

    for (const url of candidates) {
      lastUrl = url;
      const attempt = await fetch(url, { headers: { accept: 'application/json' } });
      if (attempt.ok) {
        res = attempt;
        break;
      }
      if (attempt.status !== 404) {
        res = attempt;
        break;
      }
    }

    if (!res) {
      return json({ error: 'Upstream error: no response' }, { status: 502 });
    }

    if (!res.ok) {
      let detail: string | null = null;
      try {
        detail = (await res.text()).slice(0, 500);
      } catch {
        detail = null;
      }
      return json(
        { error: `Upstream error: HTTP ${res.status}`, upstream: lastUrl, detail },
        { status: 502 }
      );
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
