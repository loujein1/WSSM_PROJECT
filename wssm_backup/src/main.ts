import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

import * as dotenv from 'dotenv';
dotenv.config();


async function bootstrap() {
  const app = await NestFactory.create(AppModule);
 // await app.listen(process.env.PORT ?? 3000);
  await app.listen(3000, '0.0.0.0');  // This allows external connections
  console.log(`Application is running on: http://0.0.0.0:3000`);

  app.enableCors({
    origin: '*', // Change this to specific domains for security
    methods: 'GET,POST,PUT,DELETE',
  });
  
}

bootstrap();
