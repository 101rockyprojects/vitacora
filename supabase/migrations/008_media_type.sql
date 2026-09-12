-- ============================================================
-- Vitacora — Add media_type to movie_watchlist
-- ============================================================

ALTER TABLE vitacora.movie_watchlist
  ADD COLUMN IF NOT EXISTS media_type TEXT NOT NULL DEFAULT 'movie';

-- Recreate the view to include media_type
DROP VIEW IF EXISTS vitacora.movie_watchlist_with_ratings;

CREATE OR REPLACE VIEW vitacora.movie_watchlist_with_ratings
WITH (security_invoker = true)
AS
SELECT
  mw.id,
  mw.added_by,
  mw.title,
  mw.poster_url,
  mw.resources,
  mw.media_type,
  mw.created_at,
  (AVG(mr.rating)::float8) AS avg_rating,
  (COUNT(mr.rating)::int) AS total_ratings,
  (MAX(mr.rating) FILTER (WHERE mr.user_id = auth.uid()))::int AS user_rating,
  (
    MAX(mr.rating) FILTER (
      WHERE mr.user_id = (
        SELECT pr.partner_id
        FROM vitacora.partner_relations pr
        WHERE pr.user_id = auth.uid()
        LIMIT 1
      )
    )
  )::int AS partner_rating
FROM vitacora.movie_watchlist mw
LEFT JOIN vitacora.movie_ratings mr
  ON mr.movie_id = mw.id
GROUP BY mw.id;
