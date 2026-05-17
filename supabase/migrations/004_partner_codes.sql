CREATE TABLE IF NOT EXISTS vitacora.partner_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  code VARCHAR(6) NOT NULL UNIQUE,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE vitacora.partner_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "partner_codes_select" ON vitacora.partner_codes FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "partner_codes_insert_own" ON vitacora.partner_codes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "partner_codes_update_own" ON vitacora.partner_codes FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "partner_codes_delete_own" ON vitacora.partner_codes FOR DELETE USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS vitacora.partner_relations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  partner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  connected_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

ALTER TABLE vitacora.partner_relations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "partner_relations_select" ON vitacora.partner_relations FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "partner_relations_insert_own" ON vitacora.partner_relations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "partner_relations_update_own" ON vitacora.partner_relations FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "partner_relations_delete_own" ON vitacora.partner_relations FOR DELETE USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION vitacora.connect_partners(user_a_id UUID, user_b_id UUID)
RETURNS VOID AS $$
BEGIN
  INSERT INTO vitacora.partner_relations (user_id, partner_id, connected_at)
  VALUES (user_a_id, user_b_id, NOW()), (user_b_id, user_a_id, NOW())
  ON CONFLICT (user_id) DO UPDATE SET partner_id = EXCLUDED.partner_id, connected_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION vitacora.disconnect_partners(user_a_id UUID, user_b_id UUID)
RETURNS VOID AS $$
BEGIN
  DELETE FROM vitacora.partner_relations WHERE user_id = user_a_id;
  DELETE FROM vitacora.partner_relations WHERE user_id = user_b_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE POLICY "movie_watchlist_select_self_or_partner"
  ON vitacora.movie_watchlist
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND (
      added_by = auth.uid()
      OR added_by = (
        SELECT partner_id FROM vitacora.partner_relations WHERE user_id = auth.uid() LIMIT 1
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
        SELECT partner_id FROM vitacora.partner_relations WHERE user_id = auth.uid() LIMIT 1
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