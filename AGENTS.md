# Vitacora - AI Agent Context

## Quick Reference

### Key Files
- `src/routes/work/+page.svelte` - Kanban, Projects, Links, Skills.md
- `src/routes/goals/+page.svelte` - Vision, Books, Learning, Memories, Calendar, Successes, Rewards, Expenses
- `src/routes/dashboard/+page.svelte` - Dashboard with stats, tasks, books, charts
- `src/lib/services/repository.ts` - Supabase data access layer
- `src/lib/types/index.ts` - TypeScript interfaces
- `src/lib/components/WeekPlanner.svelte` - Calendar week view
- `src/lib/components/PieChart.svelte` - Bar/Pie charts (ApexCharts)
- `src/lib/components/Sidebar.svelte` - Navigation sidebar
- `src/app.css` - Global styles, CSS variables

### Database Tables (Supabase)
- All tables in `vitacora` schema with RLS enabled
- Key tables: `tasks`, `projects`, `books`, `learning`, `memories`, `calendar_events`, `calendar_todos`, `expenses`, `skills_md`, `xp_log`, `badges`, `user_badges`

### Important Patterns

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

**Styling:**
- Use CSS variables from `src/app.css`
- Follow existing component patterns
- Flowbite components available (see DESIGN.md)

### Commands
```bash
npm run dev      # Start dev server
npm run build    # Production build
npm run check    # Type checking
```

### MCP Tools Available
- Flowbite-Svelte component discovery: `findComponent`, `getComponentList`, `getComponentDoc`, `searchDocs`
- Use for discovering Flowbite components and getting documentation

### Common Tasks
- Add new section: modify corresponding `+page.svelte` in `src/routes/` and create migration if needed
- Add new table: create migration + types + repository
- Add new route: create `+page.svelte` in `src/routes/`
- Add chart: use `PieChart` component with `type="bar"` or `type="pie"`
- Modal pattern: see existing modals in work/+page.svelte or goals/+page.svelte

### Code Style
- Svelte 5 with runes syntax
- TypeScript strict
- No comments unless explicitly requested
- CSS variables for theming
- Accessible (keyboard navigation, ARIA roles)