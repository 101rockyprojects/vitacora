-- ============================================================
-- Vitacora — Work pending items
-- ============================================================

CREATE TABLE IF NOT EXISTS vitacora.work_todos (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name        TEXT NOT NULL,
  done        BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE vitacora.work_todos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "work_todos_select_own" ON vitacora.work_todos FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "work_todos_insert_own" ON vitacora.work_todos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "work_todos_update_own" ON vitacora.work_todos FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "work_todos_delete_own" ON vitacora.work_todos FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_work_todos_user ON vitacora.work_todos(user_id, done);
