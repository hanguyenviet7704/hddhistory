import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { CoachMetricController } from './coach-metric.controller';
import { CoachMetricService } from './coach-metric.service';
import { CoachMetricRepository } from './repository/coach-metric.repository';
import { CoachMetric, CoachMetricSchema } from './schema/coach-metric.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CoachMetric.name, schema: CoachMetricSchema },
    ]),
    // Guarded controller — the guard resolves its deps in this module's
    // context, so leaving this out is a boot crash no type-check can see.
    forwardRef(() => AuthModule),
  ],
  controllers: [CoachMetricController],
  providers: [CoachMetricService, CoachMetricRepository],
  exports: [CoachMetricService, CoachMetricRepository],
})
export class CoachMetricModule {}
