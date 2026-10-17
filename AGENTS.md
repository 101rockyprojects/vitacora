# Vitacora - AI Agent Context

## Purpose

VitaCora is a personal life-management app with gamification. Track goals, books, kanban tasks, expenses, memories, and partner date ideas — earning XP, levels, and badges as you progress. UI is in Spanish. See `README.md` for user-facing docs, `SPEC.md` for the full technical spec, and `DESIGN.md` for design details.

## Technologies

- **Framework**: SvelteKit 2 + Svelte 5 (runes) + TypeScript (strict)
- **Build**: Vite 5
- **Styling**: CSS variables, Flowbite-Svelte components
- **Charts**: ApexCharts (via `@flowbite-svelte-plugins/chart`), wrapped in `PieChart.svelte`
- **Backend**: Supabase (PostgreSQL with RLS, Auth, Storage)
- **Auth session**: `@supabase/ssr` in `src/hooks.server.ts`
- **Drag & drop**: `svelte-dnd-action`
- **Photo grid**: `gridstack`; PNG export: `html2canvas`
- **Deploy**: Cloudflare Pages (`@sveltejs/adapter-cloudflare`, `wrangler.toml`)

## Key Files

- `src/routes/work/+page.svelte` - Kanban, Projects, Links, Skills.md
- `src/routes/goals/+page.svelte` - Vision, Books, Learning, Memories, Calendar, Successes, Rewards, Expenses
- `src/routes/dashboard/+page.svelte` - Dashboard with stats, tasks, books, charts
- `src/routes/partner/+page.svelte` - Partner connection (6-char code), date ideas
- `src/lib/services/repository.ts` - Supabase data access layer
- `src/lib/types/index.ts` - TypeScript interfaces
- `src/lib/utils/xp.ts` - XP values, level formula, badges
- `src/lib/supabase.ts` - Supabase client
- `src/lib/components/WeekPlanner.svelte` - Calendar week view
- `src/lib/components/PieChart.svelte` - Bar/Pie charts (ApexCharts)
- `src/lib/components/Sidebar.svelte` - Navigation sidebar
- `src/app.css` - Global styles, CSS variables

## Database (Supabase)

- All tables in the `vitacora` schema with RLS enabled, scoped by `auth.uid()`
- Key tables: `tasks`, `projects`, `books`, `learning`, `memory_album`, `calendar_events`, `calendar_todos`, `expenses`, `skills_md`, `useful_links`, `date_ideas`, `xp_log`, `badges`, `user_badges`
- Migrations live in `supabase/migrations/` (numbered `00N_*.sql`)
- Storage bucket: `memories` (public) for photo uploads, folders keyed by user ID
- Partner pairing uses user metadata (`partner_code`, `partner_id`), not tables

## Routing & Features

- `/` - redirect to `/dashboard` or `/auth`
- `/dashboard` - global XP/level, area bars, today's tasks, books, expense chart, week planner
- `/work` - tabs: kanban (4 columns: to_do, doing, done, to_review), projects, links, skills.md editor
- `/goals` - tabs: vision, books, learning, memories, calendar, successes, rewards, expenses
- `/partner` - connect via 6-char code, shared date ideas, movie roulette
- `/profile` - XP per area, badges, activity log, PNG export
- Tab state persists via URL search params

## XP System

- Areas: work, education, selfcare, social, health, finance
- Level formula: `level = floor(sqrt(totalXP / 100)) + 1`
- Values in `XP_VALUES` (`src/lib/utils/xp.ts`): task 10, book 50, book page 2, success 30, learning 15, memory 5, reward 20
- XP gains logged to `xp_log`; badges in `PREDEFINED_BADGES`

## Important Patterns

**Adding a new feature:**
1. Create migration in `supabase/migrations/`
2. Add type in `src/lib/types/index.ts`
3. Add repository method in `src/lib/services/repository.ts`
4. Implement component in route page
5. Run `npm run check` to verify types

**State management:**
- Use Svelte 5 runes: `$state()`, `$derived()`, `$effect()`
- Access user via `page.data.user?.id`
- Use repository pattern for data access

**Modals:** follow existing modal patterns in `work/+page.svelte` or `goals/+page.svelte`; `Modal.svelte` provides the shared backdrop.

## Style Guide

- **Colors** (CSS variables from `src/app.css`): `--bg #0f1117`, `--bg2 #161b25`, `--bg3 #1e2535`, `--surface #242b3d`, `--surface2 #2e3650`, `--border #333d57`, `--text #e8eaf0`, `--text2 #9aa3bd`, `--text3 #636d8a`, accents: `--accent-green #73e7bd`, `--accent-yellow #ebd57f`, `--accent-orange #ee9863`, `--accent-blue #5d99ee`, `--accent-purple #9294f5`, `--accent-red #ee8888`
- **Typography**: Syne (display), DM Sans (body), Space Mono (mono); loaded in `app.html`
- **Spacing**: 32px main content padding; border-radius 10px (small), 16px (large); sidebar 240px
- **Buttons**: `btn-primary`, `btn-secondary`, `btn-ghost`; custom card and modal-backdrop patterns
- **Responsive**: desktop > 900px, tablet 640-900px, mobile < 640px
- Use CSS variables for theming — never hardcode hex values in components
- Accessible: keyboard navigation, ARIA roles

## Code Style

- Svelte 5 with runes syntax (no Svelte 4 stores/exports for reactive state)
- TypeScript strict
- No comments unless explicitly requested
- All UI copy in Spanish

## Commands

```bash
npm run dev      # Start dev server
npm run build    # Production build
npm run check    # Type checking (svelte-check)
npm run watch    # wrangler tail (production logs)
```

## Deployment Policy

- When user says "deploy", use the deploy skill (trigger: "deploy", "push to production")
- Requires `CLOUDFLARE_API_TOKEN` env variable
- Build: `npm run build` (takes 1-3 min)
- Merge with master before push. Notify conflicts, user is responsible to solve them, not you
- Deploy by pushing changes: `git push origin master`
- After code changes: commit and push to master first, then offer to deploy

## MCP Tools Available

- Flowbite-Svelte component discovery: `findComponent`, `getComponentList`, `getComponentDoc`, `searchDocs`
- Use for discovering Flowbite components and getting documentation

## Common Tasks

- Add new section: modify corresponding `+page.svelte` in `src/routes/` and create migration if needed
- Add new table: create migration + types + repository method
- Add new route: create `+page.svelte` in `src/routes/`
- Add chart: use `PieChart` component with `type="bar"` or `type="pie"`

## Workflow

- ALWAYS use `pnpm` not `npm`
- Creating always a branch for a feature/fix or a group of universal changes
- Always review consistency of codebase and the new code added
- Avoid use of type `any` in .ts files, avoid hard-coded colors in styles (recycle already created colors)
- NEVER execute `npm run` commands without explicit user authorization
- ONLY AFTER deploy, all the local branches merged has to be deleted

## Contraints

- ALWAYS refer to secrets with '$env/dynamic/public' in server-side codebase exclusively
- DO NOT read .env.* files