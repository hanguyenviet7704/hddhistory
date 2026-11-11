import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { CoachRatingController } from './coach-rating.controller';
import { CoachRatingService } from './coach-rating.service';
import { CoachRatingRepository } from './repository/coach-rating.repository';
import { CoachRating, CoachRatingSchema } from './schema/coach-rating.schema';
import { CoachProfileModule } from '../profile/coach-profile.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CoachRating.name, schema: CoachRatingSchema },
    ]),
    CoachProfileModule,
    // Guarded controller — the guard resolves its deps in this module's context.
    forwardRef(() => AuthModule),
  ],
  controllers: [CoachRatingController],
  providers: [CoachRatingService, CoachRatingRepository],
  exports: [CoachRatingService, CoachRatingRepository],
})
export class CoachRatingModule {}
