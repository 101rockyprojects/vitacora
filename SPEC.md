# Vitacora - Technical Specification

## Overview
Personal life management application with gamification (XP system, badges, levels). Built with SvelteKit, Supabase, and Flowbite.

## Tech Stack
- **Frontend**: SvelteKit 2.x (Svelte 5), TypeScript
- **Styling**: CSS Variables, Flowbite-Svelte components
- **Charts**: ApexCharts with Flowbite plugin
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **Build**: Vite
- **Deploy**: Cloudflare Pages

## Database Schema

### Core Tables
- `books` - Reading progress tracking
- `learning` - Learning topics/resources
- `memory_album` - Photo memories
- `calendar_events` - Events and special dates
- `calendar_todos` - Quick tasks in calendar
- `success_experiences` - Goals with reflections
- `rewards` - Achievement rewards
- `tasks` - Kanban tasks (status: to_do, doing, done, to_review)
- `projects` - Project tracking
- `useful_links` - Links and vision board
- `skills_md` - Markdown skills documentation
- `date_ideas` - Partner date ideas
- `xp_log` - XP gain tracking
- `badges` / `user_badges` - Achievement system
- `expenses` - Financial tracking

## XP System
- Areas: work, education, selfcare, social, health, finance
- Level formula: `level = floor(sqrt(totalXP / 100)) + 1`
- Each level requires progressively more XP

## Feature Modules

### Dashboard
- Global XP and level display
- Stats row (total XP, active tasks, books, badges)
- Area XP progress bars
- Today's pending tasks
- Books in progress (3 most recent)
- Week planner (mini calendar)
- Current month expenses chart

### Work (Kanban)
- 4-column board: Por hacer, En progreso, Hecho, Revisar
- Collapsible columns (to_do, doing open by default)
- Drag-and-drop task movement
- Tags with filtering
- Task details with description, due date

### Projects
- Name, description, links (GitHub, Deploy, Inspiration)
- Grid display

### Links
- Useful links list with delete

### Skills.md
- Markdown editor with preview
- Copy button (❏) for quick content copy

### Goals (Vision & Metas)
- **Vision**: Vision board embed (Canva/image), motivational phrases
- **Books**: Progress tracking, toggle for notes
- **Learning**: Topics with resources
- **Memories**: Gridstack photo grid
- **Calendar**: Week view + To Do section + event list
- **Successes**: Goal tracking with reflections
- **Rewards**: Achievement rewards
- **Expenses**: Financial tracking with category filter, date range, monthly grouping, pie/bar charts

### Partner
- Date ideas management
- Photo memories

### Profile
- User settings

## UI/UX Design System

### Colors (CSS Variables)
```
--bg: #0f1117
--bg2: #161b25
--bg3: #1e2535
--surface: #242b3d
--surface2: #2e3650
--border: #333d57
--text: #e8eaf0
--text2: #9aa3bd
--text3: #636d8a
--accent-green: #73e7bd
--accent-yellow: #ebd57f
--accent-orange: #ee9863
--accent-blue: #5d99ee
--accent-purple: #9294f5
--accent-red: #ee8888
```

### Typography
- Display: Syne
- Body: DM Sans
- Mono: Space Mono

### Spacing & Layout
- Padding: 32px main content
- Border radius: 10px (small), 16px (large)
- Sidebar: 240px width

### Components Used
- Card (custom)
- Modal (custom backdrop)
- Buttons: btn-primary, btn-secondary, btn-ghost
- Form elements: input, textarea, select
- Progress bars
- Tags

## Routing
- `/` - Dashboard
- `/work` - Work & Projects (tabs: kanban, projects, links, skills)
- `/goals` - Vision & Metas (tabs: vision, books, learning, memories, calendar, successes, rewards, expenses)
- `/partner` - Partner section
- `/profile` - User profile
- `/auth` - Authentication

## State Management
- Svelte 5 runes (`$state`, `$derived`, `$effect`)
- URL search params for tab state
- Supabase client via repository pattern

## Responsive Breakpoints
- Desktop: > 900px
- Tablet: 640-900px
- Mobile: < 640px