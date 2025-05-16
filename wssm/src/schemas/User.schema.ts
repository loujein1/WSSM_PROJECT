import { Schema, Prop, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

/* import mongoose from 'mongoose';
import { UserSettings } from './UserSettings.schema';
import { Post } from './Post.schema'; */

@Schema({versionKey: false})
export class User extends Document {
  @Prop({ unique: true, required: true })
  username: string;
  @Prop({ unique: true, required: true})
  email: string;
  @Prop({ unique: true, required: true})
  password: string;


/*  @Prop({ required: false })
  displayName?: string;

  @Prop({ required: false })
  avatarUrl?: string;

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'UserSettings' })
  settings?: UserSettings;

  @Prop({ type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Post' }] })
  posts: Post[]; */
}

export const UserSchema = SchemaFactory.createForClass(User);