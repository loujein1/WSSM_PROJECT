import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { WaterUsage } from '../schemas/water-usage.schema';

@Injectable()
export class WaterUsageService {
  constructor(
    @InjectModel(WaterUsage.name) private readonly waterUsageModel: Model<WaterUsage>,
  ) {}

  async getAllUsage(): Promise<WaterUsage[]> {
    const data = await this.waterUsageModel.find().sort({ timestamp: -1 }).exec();
    console.log('✅ Fetched Water Usage Data:', data); // ✅ Debugging log
    return data;
  }

  async getStats() {
    const data = await this.waterUsageModel.find().exec();
    const totalUsage = data.reduce((sum, entry) => sum + entry.amountUsed, 0);
    const avgUsage = totalUsage / (data.length || 1);

    return { totalUsage, avgUsage };
  }
}
