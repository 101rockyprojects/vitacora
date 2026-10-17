# Definition of Done — Vitacora features

A branch is DONE when all apply:

- [ ] Branch created per feature; only planned files touched.
- [ ] New table → numbered migration (RLS + 4 policies + index), added to schema doc notes
      if AGENTS/SPEC list tables.
- [ ] Types in `src/lib/types/index.ts` (strict, no `any`).
- [ ] Repository method added in `src/lib/services/repository.ts` when data is accessed.
- [ ] Component follows existing patterns (modal/section/card) in the same page family.
- [ ] UI copy in Spanish; ARIA/keyboard support on new interactive elements.
- [ ] Colors only via CSS variables; new global tokens go in `src/app.css` `:root`.
- [ ] `pnpm run check` passes (user-authorized run).
- [ ] Auditor verdict ≥ PASS-with-fixes, and blockers resolved by developer.
- [ ] Orchestrator reviewed the final diff and committed on the branch.
