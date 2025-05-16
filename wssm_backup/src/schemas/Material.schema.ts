// src/materials/material.schema.ts
import { Schema, Document } from 'mongoose';

export const MaterialSchema = new Schema({
  name: { type: String, required: true },
  description: { type: String, required: true },
  userId: { type: String, required: true }, // Store the user ID here
  createdAt: { type: Date, default: Date.now },
}, { versionKey: false });

export interface Material extends Document {
  id: string;
  name: string;
  description: string;
  userId: string; // Ensure the user ID is included
  createdAt: Date;
}
