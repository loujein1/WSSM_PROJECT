// src/materials/materials.controller.ts

import { Controller, Post, Get, Param, Delete, Patch, Body, HttpException, HttpStatus } from '@nestjs/common';
import { MaterialsService } from './materials.service';
import { CreateMaterialDto } from './dtos/CreateMaterial.dto';
import { Material } from 'src/schemas/Material.schema';
import { UpdateMaterialDto } from './dtos/UpdateMaterial.dto';


@Controller('materials')
export class MaterialsController {
  constructor(private readonly materialsService: MaterialsService) {}

  // Create Material
  @Post()
  async create(@Body() createMaterialDto: CreateMaterialDto): Promise<Material> {
    return await this.materialsService.create(createMaterialDto);
  }

  // Get All Materials
  @Get()
  async findAll() {
    return await this.materialsService.findAll(); // Fetch all materials from the database
  }

   // Get materials for a specific user
   @Get('user/:userId')
   async getMaterialsForUser(@Param('userId') userId: string) {
     return this.materialsService.findByUser(userId); // Pass the userId to the service
   }

  // Get Material by ID
  @Get(':id')
  async findOne(@Param('id') id: string): Promise<Material> {
    return await this.materialsService.findOne(id);
  }

  @Patch(':id')
  async updateMaterial(@Param('id') id: string, @Body() updateData: any) {
    return this.materialsService.update(id, updateData);
  }

  @Delete(':id') // ✅ Delete Material
  async deleteMaterial(@Param('id') id: string) {
    return this.materialsService.remove(id);
  }

}
