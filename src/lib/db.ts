import { MongoClient, ObjectId } from 'mongodb';

const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/chat_app';
const client = new MongoClient(mongoUri);

export interface User {
  id: string;
  email: string;
}

export interface Chat {
  _id: ObjectId;
  user_id: string;
  title: string;
  created_at: Date;
}

export interface Message {
  _id: ObjectId;
  chat_id: string;
  user_id: string;
  content: string;
  sender: string;
  created_at: Date;
}

export interface Profile {
  _id: ObjectId;
  user_id: string;
  username: string | null;
  avatar_url: string | null;
  updated_at: Date;
}

export default client;