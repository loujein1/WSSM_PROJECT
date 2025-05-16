import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { WaterUsageService } from './water-usage.service';
import { WaterUsageController } from './water-usage.controller';
import { WaterUsage, WaterUsageSchema } from '../schemas/water-usage.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: WaterUsage.name, schema: WaterUsageSchema }]),
  ],
  controllers: [WaterUsageController],
  providers: [WaterUsageService],
})
export class WaterUsageModule {}
