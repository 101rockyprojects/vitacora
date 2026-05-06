# ◈ VitaCora — Personal Productivity Dashboard

A personal productivity dashboard built with SvelteKit 5 (runes) + Supabase. Track goals, books, kanban tasks, partner date ideas, and earn XP as you progress.

---

## Stack

- **Frontend**: SvelteKit 5 (Svelte runes) + TypeScript
- **Build**: Vite
- **Server**: `@sveltejs/adapter-node`
- **Database & Auth**: Supabase (PostgreSQL + RLS)
- **Storage**: Supabase Storage (photo uploads)

---

## Quick Start

### 1. Clone & Install

```bash
git clone <your-repo>
cd vitacora
npm install
```

### 2. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. In **Project Settings → API**, copy:
   - **Project URL** → `PUBLIC_SUPABASE_URL`
   - **anon / public key** → `PUBLIC_SUPABASE_ANON_KEY`

### 3. Configure Environment

```bash
cp .env.example .env
# Edit .env and paste your Supabase credentials
```

### 4. Run Database Migration

Go to **Supabase Dashboard → SQL Editor** and paste the entire contents of:

```
supabase/migrations/001_initial.sql
```

Click **Run**. This creates all tables, enables RLS policies, and seeds badges.

### 5. Set Up Storage Bucket (for photo uploads)

In **Supabase Dashboard → Storage → New Bucket**:
- Name: `memories`
- Public: ✓ (checked)

Then in **Storage → Policies → memories**, add these policies (or run the commented SQL at the bottom of the migration file):

| Operation | Policy |
|-----------|--------|
| INSERT | `auth.uid()::text = (storage.foldername(name))[1]` |
| SELECT | `auth.uid()::text = (storage.foldername(name))[1]` |
| DELETE | `auth.uid()::text = (storage.foldername(name))[1]` |

### 6. Run Locally

```bash
npm run dev
```

Visit `http://localhost:5173` → You'll be redirected to `/auth` to sign up.

---

## Features

| Section | Features |
|---------|----------|
| **Dashboard** | Global XP level, area bars, today's tasks, books in progress, expense pie chart |
| **Visión & Metas** | Vision board, motivational phrases, books, learning, memory album, calendar, success experiences, rewards, expenses tracker with category/month filters |
| **Trabajo** | Kanban board (drag & drop), projects grid, useful links, skills.md editor |
| **Partner** | Unique 6-char code for connection, connect with partner, shared date ideas list with purple indicator, random picker, mark as done, disconnect option |
| **Perfil & XP** | XP per area, global level, badges/achievements, activity log, export as PNG |
| **Notifications** | Toast notifications, bell icon with unread badge, auto-alerts for due tasks and calendar events |

### XP System

| Action | XP |
|--------|----|
| Task completed | 10 |
| Book finished | 50 |
| Book page update | 2 |
| Success experience | 30 |
| Learning topic added | 15 |
| Memory added | 5 |
| Reward earned | 20 |

## Partner Connection

Share your unique 6-character code with your partner to connect and share date ideas:

1. Visit **Partner** page - your code is displayed automatically
2. Copy your code and share it with your partner
3. Partner enters your code in "Conectar con pareja" form
4. Once connected, both see each other's date ideas (marked with purple border)
5. Either partner can disconnect at any time

No new tables needed - uses existing Supabase user metadata (`partner_code`, `partner_id`).

---

## Vision Board

To embed your Canva vision board, edit `src/routes/goals/+page.svelte` and replace the placeholder section:

```svelte
<!-- Replace this comment with your embed: -->
<iframe
  src="YOUR_CANVA_EMBED_URL"
  title="Vision Board"
  width="100%"
  height="500"
  frameborder="0"
  allowfullscreen
></iframe>
```

---

## Deploy with adapter-node

### Build

```bash
npm run build
```

The output is in `build/`. Run it with Node.js:

```bash
node build/index.js
```

Set the `PORT` environment variable if needed (default: 3000).

### Deploy to a VPS / Railway / Render

1. Push your code to a Git repo
2. Set environment variables on your hosting platform:
   - `PUBLIC_SUPABASE_URL`
   - `PUBLIC_SUPABASE_ANON_KEY`
3. Build command: `npm run build`
4. Start command: `node build/index.js`

### Deploy to Railway

```bash
npm install -g railway
railway login
railway init
railway add
railway up
```

Set env vars in Railway dashboard.

---

## Project Structure

```
src/
├── app.css              # Global design system
├── app.html             # HTML shell (Google Fonts loaded here)
├── app.d.ts             # TypeScript declarations
├── hooks.server.ts      # Supabase SSR session handling
├── lib/
│   ├── supabase.ts      # Supabase client
│   ├── types/index.ts   # All TypeScript types
│   ├── utils/xp.ts      # XP logic, levels, badges
│   └── components/
│       └── Sidebar.svelte
└── routes/
    ├── +layout.server.ts
    ├── +layout.svelte
    ├── +page.svelte      # Redirect to /dashboard or /auth
    ├── auth/+page.svelte
    ├── dashboard/+page.svelte
    ├── goals/+page.svelte
    ├── work/+page.svelte
    ├── partner/+page.svelte
    └── profile/+page.svelte

supabase/
└── migrations/
    └── 001_initial.sql
```

---

## Customization

- **Colors**: Edit CSS variables in `src/app.css` (`:root { }` block)
- **XP values**: Edit `XP_VALUES` in `src/lib/utils/xp.ts`
- **Badges**: Edit `PREDEFINED_BADGES` in `src/lib/utils/xp.ts`
- **Date ideas**: Pre-seeded on first login from `src/routes/partner/+page.svelte`

---

## License

Personal use. Built with ♥
