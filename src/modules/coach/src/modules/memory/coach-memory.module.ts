import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { CoachMemoryService } from './coach-memory.service';
import { CoachEpisodeRepository } from './repository/coach-episode.repository';
import { CoachMemoryCardRepository } from './repository/coach-memory-card.repository';
import { CoachGoalRepository } from './repository/coach-goal.repository';
import { CoachMemoryRepository } from './repository/coach-memory.repository';
import { CoachMessageRepository } from './repository/coach-message.repository';
import { CoachProgressRepository } from './repository/coach-progress.repository';
import { CoachEpisode, CoachEpisodeSchema } from './schema/coach-episode.schema';
import {
  CoachMemoryCard,
  CoachMemoryCardSchema,
} from './schema/coach-memory-card.schema';
import { CoachGoal, CoachGoalSchema } from './schema/coach-goal.schema';
import { CoachMemory, CoachMemorySchema } from './schema/coach-memory.schema';
import { CoachMessage, CoachMessageSchema } from './schema/coach-message.schema';
import { CoachProgress, CoachProgressSchema } from './schema/coach-progress.schema';
import { CoachAiModule } from '../ai/coach-ai.module';

/**
 * The memory layer: raw lines, condensed knowledge, goals, episodes, progress.
 * Read by the session service on every story turn, written after every
 * session. No controller — the admin reading list comes later.
 */
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CoachMessage.name, schema: CoachMessageSchema },
      { name: CoachMemory.name, schema: CoachMemorySchema },
      { name: CoachMemoryCard.name, schema: CoachMemoryCardSchema },
      { name: CoachGoal.name, schema: CoachGoalSchema },
      { name: CoachEpisode.name, schema: CoachEpisodeSchema },
      { name: CoachProgress.name, schema: CoachProgressSchema },
    ]),
    CoachAiModule,
  ],
  providers: [
    CoachMemoryService,
    CoachMessageRepository,
    CoachMemoryRepository,
    CoachMemoryCardRepository,
    CoachGoalRepository,
    CoachEpisodeRepository,
    CoachProgressRepository,
  ],
  exports: [CoachMemoryService],
})
export class CoachMemoryModule {}
