import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { HabitConfigController } from './habit-config.controller';
import { HabitConfigService } from './habit-config.service';
import { HabitConfigRepository } from './repository/habit-config.repository';
import { HabitConfig, HabitConfigSchema } from './schema/habit-config.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: HabitConfig.name, schema: HabitConfigSchema },
    ]),
    forwardRef(() => AuthModule),
  ],
  controllers: [HabitConfigController],
  providers: [HabitConfigService, HabitConfigRepository],
  exports: [HabitConfigService, HabitConfigRepository],
})
export class HabitConfigModule {}
