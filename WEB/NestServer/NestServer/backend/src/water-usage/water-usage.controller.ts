import { Controller, Get } from '@nestjs/common';
import { WaterUsageService } from './water-usage.service';

@Controller('water-usage')
export class WaterUsageController {
  constructor(private readonly waterUsageService: WaterUsageService) {}

  @Get()
  async getAllUsage() {
    return this.waterUsageService.getAllUsage();
  }

  @Get('stats')
  async getWaterUsageStats() {
    return this.waterUsageService.getStats();
  }
}
