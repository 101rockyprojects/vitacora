CREATE TABLE IF NOT EXISTS vitacora.movie_watchlist (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  added_by   UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title      TEXT NOT NULL,
  poster_url TEXT,
  resources  TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(added_by, title)
);
ALTER TABLE vitacora.movie_watchlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY "movie_watchlist_insert_own" ON vitacora.movie_watchlist FOR INSERT WITH CHECK (auth.uid() = added_by);
CREATE POLICY "movie_watchlist_update_own" ON vitacora.movie_watchlist FOR UPDATE USING (auth.uid() = added_by) WITH CHECK (auth.uid() = added_by);
CREATE POLICY "movie_watchlist_delete_own" ON vitacora.movie_watchlist FOR DELETE USING (auth.uid() = added_by);

CREATE TABLE IF NOT EXISTS vitacora.movie_ratings (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  movie_id   UUID REFERENCES vitacora.movie_watchlist(id) ON DELETE CASCADE NOT NULL,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  rating     INTEGER CHECK (rating BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(movie_id, user_id)
);
ALTER TABLE vitacora.movie_ratings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "movie_ratings_insert_own" ON vitacora.movie_ratings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "movie_ratings_update_own" ON vitacora.movie_ratings FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "movie_ratings_delete_own" ON vitacora.movie_ratings FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "movie_watchlist_select_self_or_partner"
  ON vitacora.movie_watchlist
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND (
      added_by = auth.uid()
      OR added_by = (
        CASE
          WHEN (auth.jwt() -> 'user_metadata' ->> 'partner_id') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          THEN (auth.jwt() -> 'user_metadata' ->> 'partner_id')::uuid
          ELSE NULL
        END
      )
    )
  );

CREATE POLICY "movie_ratings_select_self_or_partner"
  ON vitacora.movie_ratings
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND (
      user_id = auth.uid()
      OR user_id = (
        CASE
          WHEN (auth.jwt() -> 'user_metadata' ->> 'partner_id') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          THEN (auth.jwt() -> 'user_metadata' ->> 'partner_id')::uuid
          ELSE NULL
        END
      )
    )
  );

CREATE OR REPLACE VIEW vitacora.movie_watchlist_with_ratings
WITH (security_invoker = true)
AS
SELECT
  mw.id,
  mw.added_by,
  mw.title,
  mw.poster_url,
  mw.resources,
  mw.created_at,
  (AVG(mr.rating)::float8) AS avg_rating,
  (COUNT(mr.rating)::int) AS total_ratings,
  (MAX(mr.rating) FILTER (WHERE mr.user_id = auth.uid()))::int AS user_rating,
  (
    MAX(mr.rating) FILTER (
      WHERE mr.user_id = (
        CASE
          WHEN (auth.jwt() -> 'user_metadata' ->> 'partner_id') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          THEN (auth.jwt() -> 'user_metadata' ->> 'partner_id')::uuid
          ELSE NULL
        END
      )
    )
  )::int AS partner_rating
FROM vitacora.movie_watchlist mw
LEFT JOIN vitacora.movie_ratings mr
  ON mr.movie_id = mw.id
GROUP BY mw.id;