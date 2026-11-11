import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { CoachBoostService } from './coach-boost.service';
import { CoachBoostHistoryRepository } from './repository/coach-boost-history.repository';
import {
  CoachBoostHistory,
  CoachBoostHistorySchema,
} from './schema/coach-boost-history.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CoachBoostHistory.name, schema: CoachBoostHistorySchema },
    ]),
  ],
  providers: [CoachBoostService, CoachBoostHistoryRepository],
  exports: [CoachBoostService, CoachBoostHistoryRepository],
})
export class CoachBoostModule {}
