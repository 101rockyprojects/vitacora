import type { User } from '@supabase/supabase-js';

export type SectionId =
  | 'dashboard'
  | 'goals'
  | 'projects'
  | 'work'
  | 'expenses'
  | 'partner'
  | 'profile';

export type TabGroup = 'goals' | 'projects' | 'partner';

export interface TabDef {
  id: string;
  label: string;
  icon: string;
}

export interface SectionDef {
  id: SectionId;
  label: string;
  icon: string;
  href: string;
}

export interface VitacoraSettings {
  display_name: string;
  palette: string;
  sections: Record<SectionId, boolean>;
  tab_order: Record<TabGroup, string[]>;
  hidden_tabs: string[];
}

export const SECTIONS: SectionDef[] = [
  { id: 'dashboard', label: 'Dashboard', icon: '◈', href: '/dashboard' },
  { id: 'goals', label: 'Visión & Metas', icon: '⊶', href: '/goals' },
  { id: 'projects', label: 'Proyectos', icon: '◉', href: '/projects' },
  { id: 'work', label: 'Work', icon: '⌘', href: '/work' },
  { id: 'expenses', label: 'Gastos', icon: '$', href: '/expenses' },
  { id: 'partner', label: 'Partner', icon: '♥', href: '/partner' },
  { id: 'profile', label: 'Perfil & XP', icon: '◎', href: '/profile' }
];

export const TABS: Record<TabGroup, TabDef[]> = {
  goals: [
    { id: 'calendar', label: 'Calendario', icon: '📅' },
    { id: 'vision', label: 'Visión', icon: '⊶' },
    { id: 'books', label: 'Libros', icon: '📚' },
    { id: 'learning', label: 'Aprendizaje', icon: '🧠' },
    { id: 'memories', label: 'Memorias', icon: '📸' },
    { id: 'successes', label: 'Logros', icon: '🏆' },
    { id: 'rewards', label: 'Recompensas', icon: '🎁' }
  ],
  projects: [
    { id: 'kanban', label: 'Kanban', icon: '⌘' },
    { id: 'projects', label: 'Proyectos', icon: '🚀' },
    { id: 'links', label: 'Links útiles', icon: '🔗' },
    { id: 'skills', label: 'Markdown', icon: '📝' }
  ],
  partner: [
    { id: 'connection', label: 'Conexión', icon: '♥' },
    { id: 'movies', label: 'Películas', icon: '🎬' },
    { id: 'ideas', label: 'Ideas', icon: '💡' },
    { id: 'links', label: 'Enlaces útiles', icon: '🔗' }
  ]
};

// ponytail: labels only; the palette values live in app.css ([data-palette="…"])
export const PALETTES = [
  { id: 'default', label: 'Vitacora' },
  { id: 'ocean', label: 'Abisal' },
  { id: 'forest', label: 'Soto' },
  { id: 'sunset', label: 'Ocaso' },
  { id: 'mono', label: 'Domino' }
];

export function tabKey(group: TabGroup, id: string): string {
  return `${group}:${id}`;
}


export const DEFAULT_SETTINGS: VitacoraSettings = {
  display_name: '',
  palette: 'default',
  sections: Object.fromEntries(SECTIONS.map((section) => [section.id, true])) as Record<
    SectionId,
    boolean
  >,
  tab_order: {
    goals: TABS.goals.map((tab) => tab.id),
    projects: TABS.projects.map((tab) => tab.id),
    partner: TABS.partner.map((tab) => tab.id)
  },
  hidden_tabs: []
};

function normalizeOrder(group: TabGroup, stored?: string[]): string[] {
  const ids = TABS[group].map((tab) => tab.id);
  const known = (stored ?? []).filter((id) => ids.includes(id));
  return [...new Set([...known, ...ids])];
}

export function readSettings(user: User | null): VitacoraSettings {
  const raw = (user?.user_metadata?.vitacora ?? {}) as Partial<VitacoraSettings>;
  return {
    display_name: raw.display_name ?? '',
    palette: PALETTES.some((palette) => palette.id === raw.palette)
      ? (raw.palette as string)
      : DEFAULT_SETTINGS.palette,
    sections: { ...DEFAULT_SETTINGS.sections, ...(raw.sections ?? {}) },
    tab_order: {
      goals: normalizeOrder('goals', raw.tab_order?.goals),
      projects: normalizeOrder('projects', raw.tab_order?.projects),
      partner: normalizeOrder('partner', raw.tab_order?.partner)
    },
    hidden_tabs: raw.hidden_tabs ?? []
  };
}

export function orderedTabs(group: TabGroup, settings: VitacoraSettings): TabDef[] {
  return settings.tab_order[group]
    .map((id) => TABS[group].find((tab) => tab.id === id))
    .filter((tab): tab is TabDef => !!tab && !settings.hidden_tabs.includes(tabKey(group, tab.id)));
}

export function displayNameFor(user: User | null): string {
  return readSettings(user).display_name || user?.email?.replace(/@.*/, '') || '';
}

export function sectionForPath(pathname: string): SectionId | null {
  const first = pathname.split('/').filter(Boolean)[0];
  return SECTIONS.find((section) => section.href === `/${first}`)?.id ?? null;
}

export function firstEnabledHref(settings: VitacoraSettings): string | null {
  return SECTIONS.find((section) => settings.sections[section.id])?.href ?? null;
}
