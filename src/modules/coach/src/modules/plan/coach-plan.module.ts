import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { CoachPlanService } from './coach-plan.service';
import { CoachPlanRepository } from './repository/coach-plan.repository';
import { CoachPlan, CoachPlanSchema } from './schema/coach-plan.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CoachPlan.name, schema: CoachPlanSchema },
    ]),
  ],
  providers: [CoachPlanService, CoachPlanRepository],
  exports: [CoachPlanService, CoachPlanRepository],
})
export class CoachPlanModule {}
