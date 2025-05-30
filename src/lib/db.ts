import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export interface User {
  id: string;
  email: string;
}

export interface Chat {
  id: string;
  user_id: string;
  title: string;
  created_at: string;
  chat_number: number;
}

export interface Message {
  id: string;
  chat_id: string;
  user_id: string;
  content: string;
  sender: string;
  created_at: string;
}

export interface Profile {
  id: string;
  username: string | null;
  avatar_url: string | null;
  updated_at: string;
}

export default supabase;