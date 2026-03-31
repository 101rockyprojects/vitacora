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
CREATE POLICY "books_select_own" ON lumina.books FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "books_insert_own" ON lumina.books FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "books_update_own" ON lumina.books FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "books_delete_own" ON lumina.books FOR DELETE USING (auth.uid() = user_id);

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
CREATE POLICY "learning_select_own" ON lumina.learning FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "learning_insert_own" ON lumina.learning FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "learning_update_own" ON lumina.learning FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "learning_delete_own" ON lumina.learning FOR DELETE USING (auth.uid() = user_id);

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
CREATE POLICY "memory_select_own" ON lumina.memory_album FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "memory_insert_own" ON lumina.memory_album FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "memory_update_own" ON lumina.memory_album FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "memory_delete_own" ON lumina.memory_album FOR DELETE USING (auth.uid() = user_id);

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
CREATE POLICY "calendar_select_own" ON lumina.calendar_events FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "calendar_insert_own" ON lumina.calendar_events FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "calendar_update_own" ON lumina.calendar_events FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "calendar_delete_own" ON lumina.calendar_events FOR DELETE USING (auth.uid() = user_id);

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
CREATE POLICY "success_select_own" ON lumina.success_experiences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "success_insert_own" ON lumina.success_experiences FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "success_update_own" ON lumina.success_experiences FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "success_delete_own" ON lumina.success_experiences FOR DELETE USING (auth.uid() = user_id);

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
CREATE POLICY "rewards_select_own" ON lumina.rewards FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "rewards_insert_own" ON lumina.rewards FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "rewards_update_own" ON lumina.rewards FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "rewards_delete_own" ON lumina.rewards FOR DELETE USING (auth.uid() = user_id);

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
CREATE POLICY "tasks_select_own" ON lumina.tasks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "tasks_insert_own" ON lumina.tasks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "tasks_update_own" ON lumina.tasks FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "tasks_delete_own" ON lumina.tasks FOR DELETE USING (auth.uid() = user_id);

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
CREATE POLICY "projects_select_own" ON lumina.projects FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "projects_insert_own" ON lumina.projects FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "projects_update_own" ON lumina.projects FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "projects_delete_own" ON lumina.projects FOR DELETE USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- USEFUL LINKS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lumina.useful_links (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title      TEXT NOT NULL,
  url        TEXT NOT NULL,
  link_type  TEXT NOT NULL DEFAULT 'general' CHECK (link_type IN ('general', 'vision_board_image', 'vision_board_canva')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE lumina.useful_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY "links_select_own" ON lumina.useful_links FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "links_insert_own" ON lumina.useful_links FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "links_update_own" ON lumina.useful_links FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "links_delete_own" ON lumina.useful_links FOR DELETE USING (auth.uid() = user_id);

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
CREATE POLICY "skills_select_own" ON lumina.skills_md FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "skills_insert_own" ON lumina.skills_md FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "skills_update_own" ON lumina.skills_md FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "skills_delete_own" ON lumina.skills_md FOR DELETE USING (auth.uid() = user_id);

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
CREATE POLICY "date_ideas_select_own" ON lumina.date_ideas FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "date_ideas_insert_own" ON lumina.date_ideas FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "date_ideas_update_own" ON lumina.date_ideas FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "date_ideas_delete_own" ON lumina.date_ideas FOR DELETE USING (auth.uid() = user_id);

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
CREATE POLICY "xp_select_own" ON lumina.xp_log FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "xp_insert_own" ON lumina.xp_log FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "xp_update_own" ON lumina.xp_log FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "xp_delete_own" ON lumina.xp_log FOR DELETE USING (auth.uid() = user_id);

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
CREATE POLICY "user_badges_select_own" ON lumina.user_badges FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_badges_insert_own" ON lumina.user_badges FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_badges_update_own" ON lumina.user_badges FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_badges_delete_own" ON lumina.user_badges FOR DELETE USING (auth.uid() = user_id);

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
