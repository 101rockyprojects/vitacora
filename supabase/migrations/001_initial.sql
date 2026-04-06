-- ============================================================
-- Vitacora — Full Supabase Migration
-- Run this in Supabase SQL Editor (or use supabase db push)
-- ============================================================

CREATE SCHEMA IF NOT EXISTS vitacora;

GRANT USAGE ON SCHEMA vitacora TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA vitacora TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA vitacora TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA vitacora TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA vitacora GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA vitacora GRANT ALL ON ROUTINES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA vitacora GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ────────────────────────────────────────────────────────────
-- BOOKS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.books (
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
ALTER TABLE vitacora.books ENABLE ROW LEVEL SECURITY;
CREATE POLICY "books_select_own" ON vitacora.books FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "books_insert_own" ON vitacora.books FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "books_update_own" ON vitacora.books FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "books_delete_own" ON vitacora.books FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- LEARNING
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.learning (
  id            UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  topic         TEXT NOT NULL,
  resource_link TEXT,
  notes         TEXT,
  image_url     TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE vitacora.learning ENABLE ROW LEVEL SECURITY;
CREATE POLICY "learning_select_own" ON vitacora.learning FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "learning_insert_own" ON vitacora.learning FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "learning_update_own" ON vitacora.learning FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "learning_delete_own" ON vitacora.learning FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- MEMORY ALBUM
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.memory_album (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  date        DATE NOT NULL,
  photo_url   TEXT,
  description TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE vitacora.memory_album ENABLE ROW LEVEL SECURITY;
CREATE POLICY "memory_select_own" ON vitacora.memory_album FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "memory_insert_own" ON vitacora.memory_album FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "memory_update_own" ON vitacora.memory_album FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "memory_delete_own" ON vitacora.memory_album FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- CALENDAR EVENTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.calendar_events (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  event_name  TEXT NOT NULL,
  event_date  DATE NOT NULL,
  type        TEXT DEFAULT 'event' CHECK (type IN ('special_day','event')),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE vitacora.calendar_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "calendar_select_own" ON vitacora.calendar_events FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "calendar_insert_own" ON vitacora.calendar_events FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "calendar_update_own" ON vitacora.calendar_events FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "calendar_delete_own" ON vitacora.calendar_events FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- SUCCESS EXPERIENCES
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.success_experiences (
  id               UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  goal_description TEXT NOT NULL,
  completed_date   TIMESTAMPTZ,
  done             BOOLEAN DEFAULT FALSE,
  reflection       TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE vitacora.success_experiences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "success_select_own" ON vitacora.success_experiences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "success_insert_own" ON vitacora.success_experiences FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "success_update_own" ON vitacora.success_experiences FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "success_delete_own" ON vitacora.success_experiences FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- REWARDS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.rewards (
  id               UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  achievement_name TEXT NOT NULL,
  reward_given     TEXT NOT NULL,
  date_awarded     DATE NOT NULL,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE vitacora.rewards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rewards_select_own" ON vitacora.rewards FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "rewards_insert_own" ON vitacora.rewards FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "rewards_update_own" ON vitacora.rewards FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "rewards_delete_own" ON vitacora.rewards FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- TASKS (Kanban)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.tasks (
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
ALTER TABLE vitacora.tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tasks_select_own" ON vitacora.tasks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "tasks_insert_own" ON vitacora.tasks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "tasks_update_own" ON vitacora.tasks FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "tasks_delete_own" ON vitacora.tasks FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- PROJECTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.projects (
  id               UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name             TEXT NOT NULL,
  description      TEXT,
  inspiration_link TEXT,
  github_link      TEXT,
  deploy_link      TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE vitacora.projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "projects_select_own" ON vitacora.projects FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "projects_insert_own" ON vitacora.projects FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "projects_update_own" ON vitacora.projects FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "projects_delete_own" ON vitacora.projects FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- USEFUL LINKS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.useful_links (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title      TEXT NOT NULL,
  url        TEXT NOT NULL,
  link_type  TEXT NOT NULL DEFAULT 'general' CHECK (link_type IN ('general', 'vision_board_image', 'vision_board_canva')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE vitacora.useful_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY "links_select_own" ON vitacora.useful_links FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "links_insert_own" ON vitacora.useful_links FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "links_update_own" ON vitacora.useful_links FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "links_delete_own" ON vitacora.useful_links FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- SKILLS MD
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.skills_md (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  content    TEXT DEFAULT '',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE vitacora.skills_md ENABLE ROW LEVEL SECURITY;
CREATE POLICY "skills_select_own" ON vitacora.skills_md FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "skills_insert_own" ON vitacora.skills_md FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "skills_update_own" ON vitacora.skills_md FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "skills_delete_own" ON vitacora.skills_md FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- DATE IDEAS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.date_ideas (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  idea_text  TEXT NOT NULL,
  status     TEXT DEFAULT 'pending' CHECK (status IN ('pending','done')),
  link       TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE vitacora.date_ideas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "date_ideas_select_own" ON vitacora.date_ideas FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "date_ideas_insert_own" ON vitacora.date_ideas FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "date_ideas_update_own" ON vitacora.date_ideas FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "date_ideas_delete_own" ON vitacora.date_ideas FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- XP LOG
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.xp_log (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  source_type TEXT NOT NULL,
  source_id   UUID,
  xp_gained   INTEGER NOT NULL DEFAULT 0,
  area        TEXT NOT NULL DEFAULT 'general',
  date        TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE vitacora.xp_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "xp_select_own" ON vitacora.xp_log FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "xp_insert_own" ON vitacora.xp_log FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "xp_update_own" ON vitacora.xp_log FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "xp_delete_own" ON vitacora.xp_log FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- BADGES
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.badges (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name            TEXT NOT NULL UNIQUE,
  description     TEXT NOT NULL,
  icon            TEXT DEFAULT '🏅',
  condition_type  TEXT NOT NULL,
  condition_value INTEGER NOT NULL DEFAULT 1
);
-- Badges are public readable (no RLS needed for reads)
ALTER TABLE vitacora.badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "badges_read" ON vitacora.badges FOR SELECT USING (true);
CREATE POLICY "badges_insert" ON vitacora.badges FOR INSERT WITH CHECK (true);

-- ────────────────────────────────────────────────────────────
-- USER BADGES
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vitacora.user_badges (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  badge_id   UUID REFERENCES vitacora.badges(id) ON DELETE CASCADE NOT NULL,
  awarded_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, badge_id)
);
ALTER TABLE vitacora.user_badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_badges_select_own" ON vitacora.user_badges FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_badges_insert_own" ON vitacora.user_badges FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_badges_update_own" ON vitacora.user_badges FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_badges_delete_own" ON vitacora.user_badges FOR DELETE USING (auth.uid() = user_id);

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
INSERT INTO vitacora.badges (name, description, icon, condition_type, condition_value) VALUES
  ('Primera Lectura', 'Termina tu primer libro', '📖', 'books_finished', 1),
  ('Lector Dedicado', 'Termina 5 libros', '📚', 'books_finished', 5),
  ('Primer Logro', 'Completa tu primera meta', '🏆', 'successes', 1),
  ('Constancia', 'Completa 10 tareas', '⚡', 'tasks_done', 10),
  ('Proyecto Master', 'Crea 3 proyectos', '🚀', 'projects', 3),
  ('Nivel 5', 'Alcanza el nivel 5 global', '🌟', 'global_level', 5),
  ('Memorias', 'Agrega 10 fotos al álbum', '📸', 'memories', 10),
  ('Aprendiz', 'Registra 5 temas de aprendizaje', '🧠', 'learning', 5)
ON CONFLICT (name) DO NOTHING;


-- BUCKET POLICIES
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'memories') THEN
        PERFORM storage.create_bucket('memories', false); -- false = no público
    END IF;
END $$;

CREATE POLICY "Give users access to own folder 1ohtrhb_0" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'memories' AND (select auth.uid()::text) = (storage.foldername(name))[1]);

CREATE POLICY "Give users access to own folder 1ohtrhb_1" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'memories' AND (select auth.uid()::text) = (storage.foldername(name))[1]);

CREATE POLICY "Give users access to own folder 1ohtrhb_2" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'memories' AND (select auth.uid()::text) = (storage.foldername(name))[1]);

CREATE POLICY "Give users access to own folder 1ohtrhb_3" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'memories' AND (select auth.uid()::text) = (storage.foldername(name))[1]);
