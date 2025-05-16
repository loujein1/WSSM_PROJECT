import { Test, TestingModule } from '@nestjs/testing';
import { WaterUsageController } from './water-usage.controller';

describe('WaterUsageController', () => {
  let controller: WaterUsageController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [WaterUsageController],
    }).compile();

    controller = module.get<WaterUsageController>(WaterUsageController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
