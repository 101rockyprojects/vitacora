import { json, type RequestHandler } from '@sveltejs/kit';

async function fetchOGMetadata(url: string): Promise<{
  title?: string;
  description?: string;
  image?: string;
}> {
  try {
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; Vitacora/1.0)'
      }
    });

    if (!response.ok) {
      return {};
    }

    const html = await response.text();
    const titleMatch = html.match(/<meta\s+property=["']og:title["']\s+content=["']([^"']+)["']/i) ||
                       html.match(/<title[^>]*>([^<]+)<\/title>/i);
    const descriptionMatch = html.match(/<meta\s+property=["']og:description["']\s+content=["']([^"']+)["']/i) ||
                            html.match(/<meta\s+name=["']description["']\s+content=["']([^"']+)["']/i);
    const imageMatch = html.match(/<meta\s+property=["']og:image["']\s+content=["']([^"']+)["']/i);

    return {
      title: titleMatch?.[1] || url,
      description: descriptionMatch?.[1],
      image: imageMatch?.[1]
    };
  } catch (error) {
    console.error('OG fetch error:', error);
    return {};
  }
}

export const GET: RequestHandler = async ({ url }) => {
  const targetUrl = url.searchParams.get('url');

  if (!targetUrl) {
    return json({ error: 'Missing url parameter' }, { status: 400 });
  }

  try {
    const metadata = await fetchOGMetadata(targetUrl);
    return json({
      url: targetUrl,
      ...metadata
    });
  } catch (error) {
    return json({ error: 'Failed to fetch metadata' }, { status: 500 });
  }
};
