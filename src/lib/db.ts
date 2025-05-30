// Types for frontend data structures
export interface User {
  id: string;
  email: string;
}

export interface Chat {
  id: string;
  user_id: string;
  title: string;
  created_at: string;
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
  user_id: string;
  username: string | null;
  avatar_url: string | null;
  updated_at: string;
}

export default interface