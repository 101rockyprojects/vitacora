import { supabase } from '$lib/supabase';
import type {
  Badge,
  Book,
  CalendarEvent,
  DateIdea,
  LearningItem,
  MemoryPhoto,
  Project,
  Reward,
  SkillsMd,
  SuccessExperience,
  Task,
  UsefulLink,
  UserBadge,
  XpLog
} from '$lib/types';
import type { SupabaseClient } from '@supabase/supabase-js';

function requireUserId(userId?: string): string {
  if (!userId) {
    throw new Error('Missing authenticated user id');
  }
  return userId;
}

export function createRepository(
  userId?: string,
  client: SupabaseClient<any, any, any> = supabase as SupabaseClient<any, any, any>
) {
  const uid = () => requireUserId(userId);

  return {
    auth: {
      signOut: () => client.auth.signOut(),
      signInWithPassword: (email: string, password: string) =>
        client.auth.signInWithPassword({ email, password }),
      signUp: (email: string, password: string) => client.auth.signUp({ email, password })
    },

    tasks: {
      list: () =>
        client.from('tasks').select('*').eq('user_id', uid()).order('created_at', { ascending: false }),
      listDoneIds: () =>
        client.from('tasks').select('id').eq('user_id', uid()).eq('status', 'done'),
      insert: (task: Omit<Task, 'id' | 'user_id'>) =>
        client.from('tasks').insert({ ...task, user_id: uid() }),
      update: (id: string, values: Partial<Task>) =>
        client.from('tasks').update(values).eq('id', id),
      remove: (id: string) => client.from('tasks').delete().eq('id', id)
    },

    projects: {
      list: () =>
        client.from('projects').select('*').eq('user_id', uid()).order('created_at', { ascending: false }),
      listIds: () => client.from('projects').select('id').eq('user_id', uid()),
      insert: (project: Omit<Project, 'id' | 'user_id'>) =>
        client.from('projects').insert({ ...project, user_id: uid() }),
      remove: (id: string) => client.from('projects').delete().eq('id', id)
    },

    links: {
      list: () =>
        client.from('useful_links').select('*').eq('user_id', uid()).order('created_at', { ascending: false }),
      insert: (link: Omit<UsefulLink, 'id' | 'user_id'>) =>
        client.from('useful_links').insert({ ...link, user_id: uid() }),
      remove: (id: string) => client.from('useful_links').delete().eq('id', id)
    },

    skillsMd: {
      get: () => client.from('skills_md').select('*').eq('user_id', uid()).maybeSingle(),
      insert: (payload: Omit<SkillsMd, 'id' | 'user_id'>) =>
        client.from('skills_md').insert({ ...payload, user_id: uid() }),
      update: (id: string, values: Partial<SkillsMd>) =>
        client.from('skills_md').update(values).eq('id', id)
    },

    books: {
      list: () =>
        client.from('books').select('*').eq('user_id', uid()).order('updated_at', { ascending: false }),
      listProgress: () =>
        client.from('books').select('current_page,total_pages').eq('user_id', uid()),
      insert: (book: Omit<Book, 'id' | 'user_id'>) =>
        client.from('books').insert({ ...book, user_id: uid() }).select().single(),
      update: (id: string, values: Partial<Book>) =>
        client.from('books').update(values).eq('id', id),
      remove: (id: string) => client.from('books').delete().eq('id', id)
    },

    learning: {
      list: () =>
        client.from('learning').select('*').eq('user_id', uid()).order('created_at', { ascending: false }),
      listIds: () => client.from('learning').select('id').eq('user_id', uid()),
      insert: (item: Omit<LearningItem, 'id' | 'user_id'>) =>
        client.from('learning').insert({ ...item, user_id: uid() }),
      remove: (id: string) => client.from('learning').delete().eq('id', id)
    },

    memories: {
      list: () =>
        client.from('memory_album').select('*').eq('user_id', uid()).order('date', { ascending: false }),
      listIds: () => client.from('memory_album').select('id').eq('user_id', uid()),
      insert: (item: Omit<MemoryPhoto, 'id' | 'user_id'>) =>
        client.from('memory_album').insert({ ...item, user_id: uid() }),
      remove: (id: string) => client.from('memory_album').delete().eq('id', id)
    },

    calendar: {
      list: () =>
        client.from('calendar_events').select('*').eq('user_id', uid()).order('event_date', { ascending: true }),
      insert: (item: Omit<CalendarEvent, 'id' | 'user_id'>) =>
        client.from('calendar_events').insert({ ...item, user_id: uid() }),
      remove: (id: string) => client.from('calendar_events').delete().eq('id', id)
    },

    successes: {
      list: () =>
        client.from('success_experiences').select('*').eq('user_id', uid()).order('created_at', { ascending: false }),
      listDoneIds: () =>
        client.from('success_experiences').select('id').eq('user_id', uid()).eq('done', true),
      insert: (item: Omit<SuccessExperience, 'id' | 'user_id'>) =>
        client.from('success_experiences').insert({ ...item, user_id: uid() }).select().single(),
      update: (id: string, values: Partial<SuccessExperience>) =>
        client.from('success_experiences').update(values).eq('id', id),
      remove: (id: string) => client.from('success_experiences').delete().eq('id', id)
    },

    rewards: {
      list: () =>
        client.from('rewards').select('*').eq('user_id', uid()).order('date_awarded', { ascending: false }),
      insert: (item: Omit<Reward, 'id' | 'user_id'>) =>
        client.from('rewards').insert({ ...item, user_id: uid() }),
      remove: (id: string) => client.from('rewards').delete().eq('id', id)
    },

    dateIdeas: {
      list: () =>
        client.from('date_ideas').select('*').eq('user_id', uid()).order('created_at', { ascending: true }),
      count: () =>
        client.from('date_ideas').select('id', { count: 'exact', head: true }).eq('user_id', uid()),
      insertMany: (ideas: Omit<DateIdea, 'id' | 'user_id'>[]) =>
        client.from('date_ideas').insert(ideas.map(idea => ({ ...idea, user_id: uid() }))),
      insert: (idea: Omit<DateIdea, 'id' | 'user_id'>) =>
        client.from('date_ideas').insert({ ...idea, user_id: uid() }),
      updateStatus: (id: string, status: DateIdea['status']) =>
        client.from('date_ideas').update({ status }).eq('id', id),
      remove: (id: string) => client.from('date_ideas').delete().eq('id', id)
    },

    badges: {
      list: () => client.from('badges').select('*'),
      insert: (badge: Omit<Badge, 'id'>) => client.from('badges').insert(badge)
    },

    userBadges: {
      list: () =>
        client.from('user_badges').select('*, badge:badges(*)').eq('user_id', uid()),
      listIds: () => client.from('user_badges').select('id').eq('user_id', uid()),
      insert: (payload: Omit<UserBadge, 'id' | 'user_id'>) =>
        client.from('user_badges').insert({ ...payload, user_id: uid() })
    },

    xp: {
      insertLog: (payload: Omit<XpLog, 'id' | 'user_id'>) =>
        client.from('xp_log').insert({ ...payload, user_id: uid() }),
      listSummary: () =>
        client.from('xp_log').select('area, xp_gained').eq('user_id', uid()),
      listLogs: () =>
        client.from('xp_log').select('*').eq('user_id', uid()).order('date', { ascending: false }).limit(20)
    },

    storage: {
      uploadMemory: (path: string, file: File) => client.storage.from('memories').upload(path, file),
      getMemoryPublicUrl: (path: string) => client.storage.from('memories').getPublicUrl(path)
    }
  };
}
