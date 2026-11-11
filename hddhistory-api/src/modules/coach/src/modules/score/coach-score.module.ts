import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { CoachScoreService } from './coach-score.service';
import { CoachSceneScoreRepository } from './repository/coach-scene-score.repository';
import {
  CoachSceneScore,
  CoachSceneScoreSchema,
} from './schema/coach-scene-score.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CoachSceneScore.name, schema: CoachSceneScoreSchema },
    ]),
  ],
  providers: [CoachScoreService, CoachSceneScoreRepository],
  exports: [CoachScoreService, CoachSceneScoreRepository],
})
export class CoachScoreModule {}
