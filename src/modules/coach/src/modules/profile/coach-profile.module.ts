import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { CoachProfileController } from './coach-profile.controller';
import { CoachProfileService } from './coach-profile.service';
import { CoachProfileRepository } from './repository/coach-profile.repository';
import {
  CoachProfile,
  CoachProfileSchema,
} from './schema/coach-profile.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CoachProfile.name, schema: CoachProfileSchema },
    ]),
    // The controller is guarded; a guard resolves its deps in the module that
    // declares the route, and without this the container crash-loops at boot
    // with nothing tsc or nest build can see.
    forwardRef(() => AuthModule),
  ],
  controllers: [CoachProfileController],
  providers: [CoachProfileService, CoachProfileRepository],
  exports: [CoachProfileService, CoachProfileRepository],
})
export class CoachProfileModule {}
