// dto/create-material.dto.ts

import { IsString } from 'class-validator';

export class CreateMaterialDto {
  @IsString()
  name: string;

  @IsString()
  description: string;

  @IsString()
  userId: string; // User ID to associate the material
}
