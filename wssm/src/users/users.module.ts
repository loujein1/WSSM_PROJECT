import { Module } from '@nestjs/common';
import { CacheModule } from '@nestjs/cache-manager';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { JwtModule } from '@nestjs/jwt'; // ✅ Import JWT Module
import { User, UserSchema } from 'src/schemas/User.schema';


@Module({
  imports: [
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
    JwtModule.register({
      secret: 'your_secret_key', // ✅ Replace with a secure secret key
      signOptions: { expiresIn: '1h' }, // ✅ Token expires in 1 hour
    }),
    
  ],
  controllers: [UsersController],
  providers: [UsersService],
})
export class UsersModule {}
