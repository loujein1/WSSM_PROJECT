import { Controller, Get } from '@nestjs/common';

@Controller('data')  // This will define the '/data' endpoint
export class AppController {
  @Get()
  getData(): any {
    return {
      data: [
        { id: 1, name: 'Item 1', value: 10 },
        { id: 2, name: 'Item 2', value: 20 },
        { id: 3, name: 'Item 3', value: 30 },
      ],
    };
  }
}
