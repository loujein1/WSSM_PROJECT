import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ collection: 'water-readings' }) // ✅ Force collection name
export class WaterUsage extends Document {
  @Prop({ required: true })
  sensorId: string;

  @Prop({ required: true })
  amountUsed: number;

  @Prop({ required: true })
  timestamp: Date;

  @Prop({ required: true })
  location: string;

  @Prop({ required: true, enum: ['normal', 'warning', 'critical'] })
  status: string;
}

export const WaterUsageSchema = SchemaFactory.createForClass(WaterUsage);
