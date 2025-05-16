import { Controller, Get } from '@nestjs/common';


@Controller('test') // ✅ This sets the base route
export class AppController {
  @Get()
  getHello() {
    return { message: 'Hello from NestJS API!' }; // ✅ Must return an object
  }
}

