-- ============================================================
-- Vitacora — Subscriptions
-- ============================================================

CREATE TABLE IF NOT EXISTS vitacora.subscriptions (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name            TEXT NOT NULL,
  category        TEXT NOT NULL DEFAULT '',
  cost            DECIMAL(10,2) NOT NULL,
  start_date      DATE NOT NULL,
  period_months   INTEGER NOT NULL DEFAULT 1,
  is_active       BOOLEAN NOT NULL DEFAULT true,
  last_paid_date  DATE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE vitacora.subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "subscriptions_select_own" ON vitacora.subscriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "subscriptions_insert_own" ON vitacora.subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "subscriptions_update_own" ON vitacora.subscriptions FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "subscriptions_delete_own" ON vitacora.subscriptions FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_active ON vitacora.subscriptions(user_id, is_active);
