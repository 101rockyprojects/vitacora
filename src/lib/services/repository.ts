import { supabase } from '$lib/supabase';
import type {
  Badge,
  Book,
  CalendarEvent,
  CalendarTodo,
  DateIdea,
  Expense,
  LearningItem,
  MemoryPhoto,
  MovieRating,
  MovieWatchlist,
  MovieWithRatings,
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
      signUp: (email: string, password: string, options?: { emailRedirectTo?: string }) => 
        client.auth.signUp({ email, password, options: options ? { emailRedirectTo: options.emailRedirectTo } : undefined })
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
      update: (id: string, values: Partial<Project>) =>
        client.from('projects').update(values).eq('id', id),
      remove: (id: string) => client.from('projects').delete().eq('id', id)
    },

    links: {
      list: () =>
        client.from('useful_links').select('*').eq('user_id', uid()).order('created_at', { ascending: false }),
      insert: (link: Omit<UsefulLink, 'id' | 'user_id'>) =>
        client.from('useful_links').insert({ ...link, user_id: uid() }),
      update: (id: string, values: Partial<UsefulLink>) =>
        client.from('useful_links').update(values).eq('id', id),
      getVisionBoard: () =>
        client
          .from('useful_links')
          .select('*')
          .eq('user_id', uid())
          .in('link_type', ['vision_board_image', 'vision_board_canva'])
          .order('created_at', { ascending: false })
          .limit(1),
      saveVisionBoard: async (url: string, linkType: 'vision_board_image' | 'vision_board_canva') => {
        await client
          .from('useful_links')
          .delete()
          .eq('user_id', uid())
          .in('link_type', ['vision_board_image', 'vision_board_canva']);
        return client.from('useful_links').insert({
          user_id: uid(),
          title: 'Vision Board Link',
          url,
          link_type: linkType
        });
      },
      remove: (id: string) => client.from('useful_links').delete().eq('id', id)
    },

    skillsMd: {
      list: () =>
        client.from('skills_md').select('*').eq('user_id', uid()).order('updated_at', { ascending: false }),
      insert: (payload: Omit<SkillsMd, 'id' | 'user_id'>) =>
        client.from('skills_md').insert({ ...payload, user_id: uid() }).select().single(),
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
      update: (id: string, values: Partial<LearningItem>) =>
        client.from('learning').update(values).eq('id', id),
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

    calendarTodos: {
      list: () =>
        client.from('calendar_todos').select('*').eq('user_id', uid()).order('todo_date', { ascending: true }),
      insert: (item: Omit<CalendarTodo, 'id' | 'user_id'>) =>
        client.from('calendar_todos').insert({ ...item, user_id: uid() }),
      update: (id: string, values: Partial<CalendarTodo>) =>
        client.from('calendar_todos').update(values).eq('id', id),
      remove: (id: string) => client.from('calendar_todos').delete().eq('id', id)
    },

    expenses: {
      list: () =>
        client.from('expenses').select('*').eq('user_id', uid()).order('expense_date', { ascending: false }),
      insert: (item: Omit<Expense, 'id' | 'user_id'>) =>
        client.from('expenses').insert({ ...item, user_id: uid() }),
      update: (id: string, values: Partial<Expense>) =>
        client.from('expenses').update(values).eq('id', id),
      remove: (id: string) => client.from('expenses').delete().eq('id', id)
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
      update: (id: string, values: Partial<Reward>) =>
        client.from('rewards').update(values).eq('id', id),
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

    movieWatchlist: {
      list: async () => {
        const { data: { user: currentUser } } = await supabase.auth.getUser();
        const partnerId = currentUser?.user_metadata?.partner_id;

        if (partnerId) {
          const { data, error } = await client
            .from('movie_watchlist')
            .select('*')
            .in('added_by', [uid(), partnerId])
            .order('created_at', { ascending: false });
          return { data, error };
        }

        return client.from('movie_watchlist').select('*').eq('added_by', uid()).order('created_at', { ascending: false });
      },
      insertMany: (titles: string[]) =>
        client.from('movie_watchlist').insert(titles.map(t => ({ title: t.trim(), added_by: uid() }))).select(),
      insert: (movie: Omit<MovieWatchlist, 'id' | 'added_by'>) =>
        client.from('movie_watchlist').insert({ ...movie, added_by: uid() }).select().single(),
      updateTitle: (id: string, title: string) =>
        client.from('movie_watchlist').update({ title }).eq('id', id),
      updatePoster: (id: string, posterUrl: string) =>
        client.from('movie_watchlist').update({ poster_url: posterUrl }).eq('id', id),
      updateResources: (id: string, resources: string) =>
        client.from('movie_watchlist').update({ resources }).eq('id', id),
      remove: (id: string) => client.from('movie_watchlist').delete().eq('id', id)
    },

    movieRatings: {
      upsert: (movieId: string, rating: number) =>
        client.from('movie_ratings').upsert({
          movie_id: movieId,
          user_id: uid(),
          rating,
          updated_at: new Date().toISOString()
        }, { onConflict: 'movie_id,user_id' }).select().single(),
      listByMovie: (movieId: string) =>
        client.from('movie_ratings').select('*').eq('movie_id', movieId),
      listFused: async () => {
        const { data, error } = await client
          .from('movie_watchlist_with_ratings')
          .select('*')
          .order('avg_rating', { ascending: true })

        const formatted = data?.map(item => ({
          ...item,
          avg_rating: Number(item.avg_rating).toFixed(1)
        }))
        return { data: formatted, error };
      },
      listWithMovies: async () => {
        const { data: { user: currentUser } } = await supabase.auth.getUser();
        const partnerId = currentUser?.user_metadata?.partner_id;

        if (partnerId) {
          const { data, error } = await client
            .from('movie_watchlist')
            .select('*, user_rating:movie_ratings!inner(rating)')
            .in('movie_ratings.user_id', [uid(), partnerId])
            .order('created_at', { ascending: false });
          return { data, error };
        }

        return client.from('movie_watchlist')
          .select('*, user_rating:movie_ratings!inner(rating)')
          .eq('movie_ratings.user_id', uid())
          .order('created_at', { ascending: false });
      },
      listRated: async () => {
        const { data: movies } = await client
          .from('movie_watchlist')
          .select('*')
          .order('created_at', { ascending: false });

        if (!movies || movies.length === 0) return { data: [] as MovieWithRatings[] };

        const { data: allUsers } = await (supabase as any).auth.admin.listUsers();
        const { data: { user: currentUser } } = await supabase.auth.getUser();
        const partnerId = currentUser?.user_metadata?.partner_id;
        const partner = partnerId ? allUsers?.users.find((u: any) => u.id === partnerId) : null;

        const { data: allRatings } = await client
          .from('movie_ratings')
          .select('*')
          .in('movie_id', movies.map((m: MovieWatchlist) => m.id!));

        const result: MovieWithRatings[] = movies.map(m => {
          const ratings = (allRatings || []).filter((r: MovieRating) => r.movie_id === m.id);
          const userRating = ratings.find((r: MovieRating) => r.user_id === uid());
          const partnerRating = partner ? ratings.find((r: MovieRating) => r.user_id === partner.id) : undefined;
          const allRatingsNums = ratings.map((r: MovieRating) => r.rating).filter(Boolean);
          const avg = allRatingsNums.length ? allRatingsNums.reduce((a: number, b: number) => a + b, 0) / allRatingsNums.length : 0;
          return {
            ...m,
            user_rating: userRating?.rating,
            partner_rating: partnerRating?.rating,
            avg_rating: avg.toLocaleString(undefined, { minimumFractionDigits: 1, maximumFractionDigits: 1 }),
            total_ratings: allRatingsNums.length
          } as MovieWithRatings;
        });

        return { data: result.sort((a, b) => (b.avg_rating || 0) - (a.avg_rating || 0)) };
      }
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
      getMemorySignedUrl: async (path: string) => {
        const { data, error } = await client.storage
          .from('memories')
          .createSignedUrl(path, 157784760); // 5 years in seconds
        if (error || !data) {
          console.error('Signed URL error:', error);
          return null;
        }
        return data.signedUrl;
      },
      deleteMemory: (path: string) => client.storage.from('memories').remove([path])
    },

    partner: {
      generateCode: () => {
        const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        let code = '';
        for (let i = 0; i < 6; i++) {
          code += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return code;
      },

      getProfile: async () => {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return null;
        return {
          id: user.id,
          email: user.email,
          partner_code: user.user_metadata?.partner_code || null,
          partner_id: user.user_metadata?.partner_id || null
        };
      },

      setPartnerCode: async (code: string) => {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) throw new Error('Not authenticated');

        const { data: allUsers } = await supabase.auth.admin.listUsers();
        const existing = allUsers?.users.find(u => 
          u.user_metadata?.partner_code === code.toUpperCase() && u.id !== user.id
        );
        
        if (existing) {
          throw new Error('Code already in use');
        }

        const { error } = await supabase.auth.updateUser({
          data: { partner_code: code.toUpperCase() }
        });
        
        if (error) throw error;
      },

      searchByCode: async (code: string) => {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return null;

        const { data: allUsers } = await supabase.auth.admin.listUsers();
        const found = allUsers?.users.find(u => 
          u.user_metadata?.partner_code === code.toUpperCase() && u.id !== user.id
        );
        
        if (!found) return null;
        return {
          id: found.id,
          email: found.email || '',
          partner_code: found.user_metadata?.partner_code || null,
          partner_id: found.user_metadata?.partner_id || null
        };
      },

      connect: async (partnerId: string) => {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) throw new Error('Not authenticated');

        const { data: allUsers } = await supabase.auth.admin.listUsers();
        const partner = allUsers?.users.find(u => u.id === partnerId);
        
        if (!partner) throw new Error('User not found');

        const partnerData = partner.user_metadata || {};
        const connectionDate = new Date().toISOString();

        try {
          const response = await fetch(`${import.meta.env.PUBLIC_SUPABASE_URL}/auth/v1/admin/users/${partnerId}`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${import.meta.env.PUBLIC_SUPABASE_ANON_KEY}`,
              'apikey': import.meta.env.PUBLIC_SUPABASE_ANON_KEY
            },
            body: JSON.stringify({
              user_metadata: { ...partnerData, partner_id: user.id, partner_since: connectionDate }
            })
          });

          if (!response.ok) {
            console.error('Partner update failed:', await response.text());
          }
        } catch (e) {
          console.error('Partner update error:', e);
        }

        const { error: userError } = await supabase.auth.updateUser({
          data: { partner_id: partnerId, partner_since: connectionDate }
        });

        if (userError) throw userError;
      },

      disconnect: async () => {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) throw new Error('Not authenticated');

        const partnerId = user.user_metadata?.partner_id;
        if (partnerId) {
          try {
            const { data: allUsers } = await supabase.auth.admin.listUsers();
            const partner = allUsers?.users.find(u => u.id === partnerId);
            if (partner) {
              const partnerData = partner.user_metadata || {};
              await fetch(`${import.meta.env.PUBLIC_SUPABASE_URL}/auth/v1/admin/users/${partnerId}`, {
                method: 'PUT',
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': `Bearer ${import.meta.env.PUBLIC_SUPABASE_ANON_KEY}`,
                  'apikey': import.meta.env.PUBLIC_SUPABASE_ANON_KEY
                },
                body: JSON.stringify({
                  user_metadata: { ...partnerData, partner_id: null }
                })
              });
            }
          } catch (e) {
            console.error('Disconnect error:', e);
          }
        }

        const { error } = await supabase.auth.updateUser({
          data: { partner_id: null }
        });

        if (error) throw error;
      },

      getPartnerIdeas: async () => {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return { data: [] };

        const partnerId = user.user_metadata?.partner_id;
        if (!partnerId) return { data: [] };

        return client
          .from('date_ideas')
          .select('*')
          .eq('user_id', partnerId)
          .order('created_at', { ascending: true });
      },

      getPartnerProfile: async () => {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return null;

        const partnerId = user.user_metadata?.partner_id;
        if (!partnerId) return null;

        const { data: allUsers } = await supabase.auth.admin.listUsers();
        const partner = allUsers?.users.find(u => u.id === partnerId);
        if (!partner) return null;

        return {
          id: partner.id,
          email: partner.email || '',
          partner_since: partner.user_metadata?.partner_since as string | undefined
        };
      }
    }
  };
}
