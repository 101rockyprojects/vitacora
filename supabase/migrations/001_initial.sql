-- ============================================================
-- Lumina — Full Supabase Migration
-- Run this in Supabase SQL Editor (or use supabase db push)
-- ============================================================

CREATE SCHEMA IF NOT EXISTS lumina;

GRANT USAGE ON SCHEMA lumina TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA lumina TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA lumina TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA lumina TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lumina GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lumina GRANT ALL ON ROUTINES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lumina GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ────────────────────────────────────────────────────────────
-- BOOKS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.books (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title       TEXT NOT NULL,
  current_page INTEGER DEFAULT 0,
  total_pages INTEGER DEFAULT 0,
  notes       TEXT,
  cover_url   TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE lumina.books ENABLE ROW LEVEL SECURITY;
CREATE POLICY "books_own" ON lumina.books FOR ALL USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- LEARNING
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.learning (
  id            UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  topic         TEXT NOT NULL,
  resource_link TEXT,
  notes         TEXT,
  image_url     TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE lumina.learning ENABLE ROW LEVEL SECURITY;
CREATE POLICY "learning_own" ON lumina.learning FOR ALL USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- MEMORY ALBUM
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.memory_album (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  date        DATE NOT NULL,
  photo_url   TEXT,
  description TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE lumina.memory_album ENABLE ROW LEVEL SECURITY;
CREATE POLICY "memory_own" ON lumina.memory_album FOR ALL USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- CALENDAR EVENTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.calendar_events (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  event_name  TEXT NOT NULL,
  event_date  DATE NOT NULL,
  type        TEXT DEFAULT 'event' CHECK (type IN ('special_day','event')),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE lumina.calendar_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "calendar_own" ON lumina.calendar_events FOR ALL USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- SUCCESS EXPERIENCES
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.success_experiences (
  id               UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  goal_description TEXT NOT NULL,
  completed_date   TIMESTAMPTZ,
  done             BOOLEAN DEFAULT FALSE,
  reflection       TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE lumina.success_experiences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "success_own" ON lumina.success_experiences FOR ALL USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- REWARDS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.rewards (
  id               UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  achievement_name TEXT NOT NULL,
  reward_given     TEXT NOT NULL,
  date_awarded     DATE NOT NULL,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE lumina.rewards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rewards_own" ON lumina.rewards FOR ALL USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- TASKS (Kanban)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.tasks (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title       TEXT NOT NULL,
  description TEXT,
  status      TEXT DEFAULT 'to_do' CHECK (status IN ('to_do','doing','done','to_review')),
  due_date    DATE,
  tags        TEXT[],
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE lumina.tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tasks_own" ON lumina.tasks FOR ALL USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- PROJECTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.projects (
  id               UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name             TEXT NOT NULL,
  description      TEXT,
  inspiration_link TEXT,
  github_link      TEXT,
  deploy_link      TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE lumina.projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "projects_own" ON lumina.projects FOR ALL USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- USEFUL LINKS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.useful_links (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title      TEXT NOT NULL,
  url        TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE lumina.useful_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY "links_own" ON lumina.useful_links FOR ALL USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- SKILLS MD
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.skills_md (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  content    TEXT DEFAULT '',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE lumina.skills_md ENABLE ROW LEVEL SECURITY;
CREATE POLICY "skills_own" ON lumina.skills_md FOR ALL USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- DATE IDEAS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.date_ideas (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  idea_text  TEXT NOT NULL,
  status     TEXT DEFAULT 'pending' CHECK (status IN ('pending','done')),
  link       TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE lumina.date_ideas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "date_ideas_own" ON lumina.date_ideas FOR ALL USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- XP LOG
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.xp_log (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  source_type TEXT NOT NULL,
  source_id   UUID,
  xp_gained   INTEGER NOT NULL DEFAULT 0,
  area        TEXT NOT NULL DEFAULT 'general',
  date        TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE lumina.xp_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "xp_own" ON lumina.xp_log FOR ALL USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- BADGES
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.badges (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name            TEXT NOT NULL UNIQUE,
  description     TEXT NOT NULL,
  icon            TEXT DEFAULT '🏅',
  condition_type  TEXT NOT NULL,
  condition_value INTEGER NOT NULL DEFAULT 1
);
-- Badges are public readable (no RLS needed for reads)
ALTER TABLE lumina.badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "badges_read" ON lumina.badges FOR SELECT USING (true);
CREATE POLICY "badges_insert" ON lumina.badges FOR INSERT WITH CHECK (true);

-- ────────────────────────────────────────────────────────────
-- USER BADGES
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.user_badges (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  badge_id   UUID REFERENCES lumina.badges(id) ON DELETE CASCADE NOT NULL,
  awarded_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, badge_id)
);
ALTER TABLE lumina.user_badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_badges_own" ON lumina.user_badges FOR ALL USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- STORAGE BUCKETS
-- Run these in Supabase Dashboard > Storage or via API:
-- ────────────────────────────────────────────────────────────
-- INSERT INTO storage.buckets (id, name, public) VALUES ('memories', 'memories', true);
-- CREATE POLICY "mem_upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'memories' AND auth.uid()::text = (storage.foldername(name))[1]);
-- CREATE POLICY "mem_select" ON storage.objects FOR SELECT USING (bucket_id = 'memories' AND auth.uid()::text = (storage.foldername(name))[1]);
-- CREATE POLICY "mem_delete" ON storage.objects FOR DELETE USING (bucket_id = 'memories' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ────────────────────────────────────────────────────────────
-- SEED: Predefined badges (optional, app also auto-seeds)
-- ────────────────────────────────────────────────────────────
INSERT INTO lumina.badges (name, description, icon, condition_type, condition_value) VALUES
  ('Primera Lectura', 'Termina tu primer libro', '📖', 'books_finished', 1),
  ('Lector Dedicado', 'Termina 5 libros', '📚', 'books_finished', 5),
  ('Primer Logro', 'Completa tu primera meta', '🏆', 'successes', 1),
  ('Constancia', 'Completa 10 tareas', '⚡', 'tasks_done', 10),
  ('Proyecto Master', 'Crea 3 proyectos', '🚀', 'projects', 3),
  ('Nivel 5', 'Alcanza el nivel 5 global', '🌟', 'global_level', 5),
  ('Memorias', 'Agrega 10 fotos al álbum', '📸', 'memories', 10),
  ('Aprendiz', 'Registra 5 temas de aprendizaje', '🧠', 'learning', 5)
ON CONFLICT (name) DO NOTHING;
