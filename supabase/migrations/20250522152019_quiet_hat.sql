/*
  # Add user profile fields and update chat numbering
  
  1. New Tables
    - `profiles`
      - `id` (uuid, primary key)
      - `username` (text)
      - `avatar_url` (text)
      - `updated_at` (timestamp)
  
  2. Changes
    - Add chat_number column to chats table
    - Add sequence for auto-incrementing chat numbers
  
  3. Security
    - Enable RLS on profiles table
    - Add policies for authenticated users
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  username text UNIQUE,
  avatar_url text,
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Create sequence for chat numbers
CREATE SEQUENCE IF NOT EXISTS chat_number_seq;

-- Add chat_number to chats table
ALTER TABLE chats
ADD COLUMN IF NOT EXISTS chat_number bigint DEFAULT nextval('chat_number_seq');

-- Create trigger to update chat titles
CREATE OR REPLACE FUNCTION update_chat_title()
RETURNS TRIGGER AS $$
BEGIN
  NEW.title := 'Chat ' || NEW.chat_number::text;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_chat_title
  BEFORE INSERT ON chats
  FOR EACH ROW
  EXECUTE FUNCTION update_chat_title();