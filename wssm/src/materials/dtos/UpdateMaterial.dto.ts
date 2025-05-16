// src/materials/dto/update-material.dto.ts
import { IsString, IsOptional } from 'class-validator';

export class UpdateMaterialDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;
}
