/*
  # Create chats table for managing multiple conversations
  
  1. New Tables
    - `chats`
      - `id` (uuid, primary key)
      - `user_id` (references auth.users)
      - `title` (text)
      - `created_at` (timestamp)
  
  2. Changes
    - Add `chat_id` column to `chat_messages` table
    - Update foreign key relationships
  
  3. Security
    - Enable RLS on chats table
    - Add policies for authenticated users to:
      - Read their own chats
      - Create new chats
*/

-- Create chats table
CREATE TABLE IF NOT EXISTS chats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  title text NOT NULL DEFAULT 'New Chat',
  created_at timestamptz DEFAULT now()
);

-- Add chat_id to chat_messages
ALTER TABLE chat_messages
ADD COLUMN IF NOT EXISTS chat_id uuid REFERENCES chats(id);

-- Enable RLS on chats
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;

-- Policies for chats
CREATE POLICY "Users can read their own chats"
  ON chats
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create chats"
  ON chats
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Update chat_messages policies
DROP POLICY IF EXISTS "Users can read their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can create messages" ON chat_messages;

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