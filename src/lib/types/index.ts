export interface Book {
  id?: string;
  user_id?: string;
  title: string;
  current_page: number;
  total_pages: number;
  notes?: string;
  cover_url?: string;
  created_at?: string;
  updated_at?: string;
}

export interface LearningItem {
  id?: string;
  user_id?: string;
  topic: string;
  resource_link?: string;
  notes?: string;
  image_url?: string;
  created_at?: string;
}

export interface MemoryPhoto {
  id?: string;
  user_id?: string;
  date: string;
  photo_url?: string;
  description: string;
  created_at?: string;
}

export interface CalendarEvent {
  id?: string;
  user_id?: string;
  event_name: string;
  event_date: string;
  type: 'special_day' | 'event';
  created_at?: string;
}

export interface SuccessExperience {
  id?: string;
  user_id?: string;
  goal_description: string;
  completed_date?: string;
  done: boolean;
  reflection?: string;
  created_at?: string;
}

export interface Reward {
  id?: string;
  user_id?: string;
  achievement_name: string;
  reward_given: string;
  date_awarded: string;
  created_at?: string;
}

export interface Task {
  id?: string;
  user_id?: string;
  title: string;
  description?: string;
  status: 'to_do' | 'doing' | 'done' | 'to_review';
  due_date?: string;
  tags?: string[];
  created_at?: string;
  updated_at?: string;
}

export interface Project {
  id?: string;
  user_id?: string;
  name: string;
  description?: string;
  inspiration_link?: string;
  github_link?: string;
  deploy_link?: string;
  created_at?: string;
}

export interface UsefulLink {
  id?: string;
  user_id?: string;
  title: string;
  url: string;
  created_at?: string;
}

export interface SkillsMd {
  id?: string;
  user_id?: string;
  content: string;
  updated_at?: string;
}

export interface DateIdea {
  id?: string;
  user_id?: string;
  idea_text: string;
  status: 'pending' | 'done';
  link?: string;
  created_at?: string;
}

export interface XpLog {
  id?: string;
  user_id?: string;
  source_type: string;
  source_id?: string;
  xp_gained: number;
  area: string;
  date?: string;
}

export interface Badge {
  id?: string;
  name: string;
  description: string;
  icon: string;
  condition_type: string;
  condition_value: number;
}

export interface UserBadge {
  id?: string;
  user_id?: string;
  badge_id: string;
  awarded_at?: string;
  badge?: Badge;
}

export interface AreaXP {
  area: string;
  xp: number;
  level: number;
  label: string;
  color: string;
}
