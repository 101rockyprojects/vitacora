-- Couple Links table for shared URLs with OG metadata
CREATE TABLE couple_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  title TEXT,
  description TEXT,
  og_image TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT user_url_unique UNIQUE(user_id, url)
);

-- Enable RLS
ALTER TABLE couple_links ENABLE ROW LEVEL SECURITY;

-- RLS policy: users can only see their own couple links
CREATE POLICY couple_links_user_access ON couple_links
  FOR ALL
  USING (auth.uid() = user_id);

-- Index for performance
CREATE INDEX couple_links_user_id_idx ON couple_links(user_id);
CREATE INDEX couple_links_created_at_idx ON couple_links(created_at DESC);
