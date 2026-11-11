import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { CoachConfigController } from './coach-config.controller';
import { CoachConfigService } from './coach-config.service';
import { CoachConfigRepository } from './repository/coach-config.repository';
import { CoachConfig, CoachConfigSchema } from './schema/coach-config.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CoachConfig.name, schema: CoachConfigSchema },
    ]),
    // The controller is guarded, and a guard's dependencies resolve in the
    // module that declares the route — without this import the whole app fails
    // to boot rather than failing at request time.
    forwardRef(() => AuthModule),
  ],
  controllers: [CoachConfigController],
  providers: [CoachConfigService, CoachConfigRepository],
  exports: [CoachConfigService, CoachConfigRepository],
})
export class CoachConfigModule {}
