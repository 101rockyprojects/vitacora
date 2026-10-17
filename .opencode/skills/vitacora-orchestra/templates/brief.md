# Brief template

Copy per role per feature. The orchestrator fills this; subagents read it as their task input.

```
Feature: <name>
Branch: <branch>
Objective (user-confirmed): <1–3 lines from the approved plan>

Scope — you WILL change:
- <files> — <what exactly>

Out of scope — you will NOT touch:
- <files/concerns>

Read first:
- AGENTS.md, SPEC.md (§ relevant), skill role file
- <source files listed exactly>

Conventions in force:
- <any feature-specific constraints>

Expected self-review before reporting:
- <checks from role checklist>

Report back:
- Files changed + summary of decisions
- Deviations from brief (must be zero unless flagged)
- What you could not verify and why
```

## Dispute rules for subagents

- If the brief conflicts with the repo: report, stop, wait for orchestrator.
- Never modify files outside scope, never run `npm run` / `pnpm run` commands.
- Never touch databases, `.env*`, or open a PR.
