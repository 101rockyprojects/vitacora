-- ============================================================
-- Vitacora — Expenses and Calendar Todos
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- CALENDAR TODOS (Quick task list in Calendar)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.calendar_todos (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name        TEXT NOT NULL,
  todo_date   DATE NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE vitacora.calendar_todos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "calendar_todos_select_own" ON vitacora.calendar_todos FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "calendar_todos_insert_own" ON vitacora.calendar_todos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "calendar_todos_update_own" ON vitacora.calendar_todos FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "calendar_todos_delete_own" ON vitacora.calendar_todos FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- EXPENSES
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.expenses (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name        TEXT NOT NULL,
  category    TEXT NOT NULL,
  cost        DECIMAL(10,2) NOT NULL,
  expense_date DATE NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE vitacora.expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "expenses_select_own" ON vitacora.expenses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "expenses_insert_own" ON vitacora.expenses FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "expenses_update_own" ON vitacora.expenses FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "expenses_delete_own" ON vitacora.expenses FOR DELETE USING (auth.uid() = user_id);

-- Index for faster filtering
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON vitacora.expenses(user_id, expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_user_category ON vitacora.expenses(user_id, category);