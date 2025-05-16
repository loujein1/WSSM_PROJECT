// src/materials/materials.service.ts

import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Material } from 'src/schemas/Material.schema';
import { CreateMaterialDto } from './dtos/CreateMaterial.dto';
import { UpdateMaterialDto } from './dtos/UpdateMaterial.dto';


@Injectable()
export class MaterialsService {
  // Update Material by ID

  constructor(@InjectModel('Material') private materialModel: Model<Material>) {}

  // Create Material
  async create(createMaterialDto: CreateMaterialDto): Promise<Material> {
    const { name, description, userId } = createMaterialDto;

    // Create and save a new material with the associated user ID
    const material = new this.materialModel({
      name,
      description,
      userId, // Associate material with the logged-in user
    });

    return material.save();
  }

  // Get All Materials
  async findAll(): Promise<Material[]> {
    return await this.materialModel.find().exec();
  }

  // Find materials by user ID
  async findByUser(userId: string): Promise<Material[]> {
    return this.materialModel.find({ userId }).exec(); // Assuming materials are associated with a userId
  }

  // Get Material by ID
  async findOne(id: string): Promise<Material> {
    const material = await this.materialModel.findById(id).exec();
  
    if (!material) {
      throw new Error('Material not found');
    }
  
    return material; // Now you can be sure material is a valid `Material` object
  }
  

  // Update Material by ID
  async update(id: string, updateData: any): Promise<Material> {
    const updatedMaterial = await this.materialModel.findByIdAndUpdate(id, updateData, { new: true });

    if (!updatedMaterial) {
      throw new NotFoundException('Material not found');
    }
    
    return updatedMaterial;
  }
  

// Delete Material by ID
async remove(id: string): Promise<Material | null> {
    const result = await this.materialModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new Error('Material not found');
    }
    return result;
  }
  
  
}
