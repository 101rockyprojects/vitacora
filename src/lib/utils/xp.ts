import { createRepository } from '$lib/services/repository';

export const XP_VALUES = {
  task_done: 10,
  book_finished: 50,
  book_page_update: 2,
  success_experience: 30,
  learning_added: 15,
  memory_added: 5,
  daily_login: 5,
  reward_earned: 20
};

export const AREAS = [
  { key: 'education', label: 'Educación', color: '#A8E6CF', icon: '📚' },
  { key: 'work', label: 'Trabajo', color: '#FFD93D', icon: '💼' },
  { key: 'selfcare', label: 'Bienestar', color: '#FF8C42', icon: '🌿' },
  { key: 'social', label: 'Social', color: '#8E9AAB', icon: '💫' }
];

export function xpForLevel(level: number): number {
  return level * 100;
}

export function levelFromXp(xp: number): { level: number; progress: number; nextLevelXp: number } {
  let level = 1;
  let remaining = xp;
  while (remaining >= xpForLevel(level)) {
    remaining -= xpForLevel(level);
    level++;
  }
  const nextLevelXp = xpForLevel(level);
  return { level, progress: remaining, nextLevelXp };
}

export async function awardXP(
  userId: string,
  area: string,
  sourceType: string,
  xpAmount: number,
  sourceId?: string
) {
  if (!userId) return false;
  const repo = createRepository(userId);
  const { error } = await repo.xp.insertLog({
    source_type: sourceType,
    source_id: sourceId,
    xp_gained: xpAmount,
    area,
    date: new Date().toISOString()
  });
  if (error) console.error('XP award error:', error);
  return !error;
}

export async function getAreaXP(userId: string): Promise<Record<string, number>> {
  if (!userId) return {};
  const repo = createRepository(userId);
  const { data, error } = await repo.xp.listSummary();
  if (error || !data) return {};
  const totals: Record<string, number> = {};
  for (const row of data) {
    totals[row.area] = (totals[row.area] || 0) + row.xp_gained;
  }
  return totals;
}

export const PREDEFINED_BADGES: Array<{
  name: string;
  description: string;
  icon: string;
  condition_type: string;
  condition_value: number;
}> = [
  { name: 'Primera Lectura', description: 'Termina tu primer libro', icon: '📖', condition_type: 'books_finished', condition_value: 1 },
  { name: 'Lector Dedicado', description: 'Termina 5 libros', icon: '📚', condition_type: 'books_finished', condition_value: 5 },
  { name: 'Primer Logro', description: 'Completa tu primera meta', icon: '🏆', condition_type: 'successes', condition_value: 1 },
  { name: 'Constancia', description: 'Completa 10 tareas', icon: '⚡', condition_type: 'tasks_done', condition_value: 10 },
  { name: 'Proyecto Master', description: 'Crea 3 proyectos', icon: '🚀', condition_type: 'projects', condition_value: 3 },
  { name: 'Nivel 5', description: 'Alcanza el nivel 5 global', icon: '🌟', condition_type: 'global_level', condition_value: 5 },
  { name: 'Memorias', description: 'Agrega 10 fotos al álbum', icon: '📸', condition_type: 'memories', condition_value: 10 },
  { name: 'Aprendiz', description: 'Registra 5 temas de aprendizaje', icon: '🧠', condition_type: 'learning', condition_value: 5 }
];
