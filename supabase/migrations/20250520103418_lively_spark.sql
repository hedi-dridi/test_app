/*
  # Create chat application schema
  
  1. New Tables
    - `users` (handled by Supabase Auth)
    - `chat_messages`
      - `id` (uuid, primary key)
      - `user_id` (references auth.users)
      - `content` (text)
      - `sender` (text)
      - `created_at` (timestamp)
  
  2. Security
    - Enable RLS on chat_messages table
    - Add policies for authenticated users to:
      - Read their own messages
      - Create new messages
*/

CREATE TABLE IF NOT EXISTS chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  content text NOT NULL,
  sender text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own messages"
  ON chat_messages
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create messages"
  ON chat_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);