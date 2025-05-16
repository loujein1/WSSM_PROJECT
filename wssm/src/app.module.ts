import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { UsersModule } from './users/users.module';
import { PostsModule } from './posts/posts.module';
import { MaterialsModule } from './materials/materials.module';
import { ConfigModule } from '@nestjs/config';
import { WaterUsageModule } from './water-usage/water-usage.module';



@Module({
  imports: [
    MongooseModule.forRoot('mongodb://localhost:27017/wssm'),
    UsersModule,
    PostsModule,
    MaterialsModule,
    WaterUsageModule,
    ConfigModule.forRoot(),  // This will automatically load variables from .env

  ],
  controllers: [],
  providers: [],
})
export class AppModule {}