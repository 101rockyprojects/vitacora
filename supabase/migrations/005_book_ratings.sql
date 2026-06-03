-- Book Rating Categories (global, user-defined)
CREATE TABLE IF NOT EXISTS vitacora.book_rating_categories (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name       TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, name)
);

-- Book Category Ratings (per book, per category)
CREATE TABLE IF NOT EXISTS vitacora.book_category_ratings (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  book_id     UUID REFERENCES vitacora.books(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES vitacora.book_rating_categories(id) ON DELETE CASCADE NOT NULL,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  rating      INTEGER CHECK (rating BETWEEN 0 AND 5) DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(book_id, category_id)
);

ALTER TABLE vitacora.books ADD COLUMN IF NOT EXISTS rating INTEGER CHECK (rating BETWEEN 1 AND 5);
ALTER TABLE vitacora.books ADD COLUMN IF NOT EXISTS rating_mode TEXT DEFAULT 'default' CHECK (rating_mode IN ('default', 'calculated'));

ALTER TABLE vitacora.book_rating_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users select own rating categories"
  ON vitacora.book_rating_categories FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users insert own rating categories"
  ON vitacora.book_rating_categories FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own rating categories"
  ON vitacora.book_rating_categories FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users delete own rating categories"
  ON vitacora.book_rating_categories FOR DELETE
  USING (auth.uid() = user_id);

-- RLS policies for book_category_ratings
ALTER TABLE vitacora.book_category_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users select own book category ratings"
  ON vitacora.book_category_ratings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users insert own book category ratings"
  ON vitacora.book_category_ratings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own book category ratings"
  ON vitacora.book_category_ratings FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users delete own book category ratings"
  ON vitacora.book_category_ratings FOR DELETE
  USING (auth.uid() = user_id);
