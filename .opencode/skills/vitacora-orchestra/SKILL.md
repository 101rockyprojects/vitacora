---
name: Vitacora Orchestra
description: Coordinate the developer/designer/auditor subagent trio to implement features in Vitacora. Load when a task spans logic + UI + review, or when the user says "orchestrate".
---

# Vitacora Orchestra

Three-role implementation pipeline. The orchestrator (primary agent) plans, sequences,
resolves conflicts, and owns all communication with the user. Subagents never talk to
the user directly.

## Hard rules (from AGENTS.md — always re-read it first)

1. ALWAYS use `pnpm`, never `npm`.
2. NEVER execute `npm run` / `pnpm run` commands without explicit user authorization.
   Batch verification requests and ask the user once.
3. One branch per feature/fix or group of universal changes.
4. Migrations are numbered SQL files in `supabase/migrations/`, applied manually by the
   user via Supabase SQL Editor. Keep them idempotent.
5. No `any` in .ts files. No hardcoded colors — reuse tokens from `src/app.css`.
6. Svelte 5 runes only. TypeScript strict. Spanish UI copy. No comments unless asked.
7. Read AGENTS.md, SPEC.md, DESIGN.md before dispatching briefs.

## Roles

Read `agents/developer.md`, `agents/designer.md`, `agents/auditor.md` for the full
briefs. Summary:

- **developer** — logic, data layer, migrations, component code. SOLID/DRY/YAGNI.
- **designer** — UI/UX polish, componentization, style consistency with existing tokens.
- **auditor** — read-only review against objectives, DoD, clean architecture.

## Sequencing

1. Orchestrator produces a written brief per role per feature (use `templates/brief.md`).
2. developer implements → orchestrator reviews the diff.
3. designer adjusts/prefers styles on top of developer output.
4. auditor validates against `checklists/` and the feature objectives.
5. Orchestrator resolves conflicts (file disputes, style drift, scope creep) personally;
   re-dispatch a narrow fix cycle only if needed.
6. Orchestrator commits per branch. Type checking is batched and user-authorized.

## Conflict resolution ladder

- Content conflict (same file, two roles): developer owns structure/logic, designer owns
  style blocks; orchestrator arbitrates merges.
- Objective conflict with plan: plan wins only if user confirmed it; otherwise escalate
  to user — never let a subagent silently change scope.
- Principle conflict (e.g. DRY vs YAGNI): prefer readability and maintainability;
  YAGNI wins on speculative abstractions.

## Do not

- Do not launch parallel subagents editing the same files.
- Do not let subagents run migrations against any database.
- Do not push or deploy without explicit user instruction.
