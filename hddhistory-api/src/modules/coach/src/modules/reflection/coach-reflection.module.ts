import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { CoachReflectionService } from './coach-reflection.service';
import { CoachEvidenceRepository } from './repository/coach-evidence.repository';
import { CoachProblemStatementRepository } from './repository/coach-problem-statement.repository';
import { CoachSituationAnswerRepository } from './repository/coach-situation-answer.repository';
import {
  CoachEvidence,
  CoachEvidenceSchema,
} from './schema/coach-evidence.schema';
import {
  CoachProblemStatement,
  CoachProblemStatementSchema,
} from './schema/coach-problem-statement.schema';
import {
  CoachSituationAnswer,
  CoachSituationAnswerSchema,
} from './schema/coach-situation-answer.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CoachEvidence.name, schema: CoachEvidenceSchema },
      { name: CoachProblemStatement.name, schema: CoachProblemStatementSchema },
      { name: CoachSituationAnswer.name, schema: CoachSituationAnswerSchema },
    ]),
  ],
  providers: [
    CoachReflectionService,
    CoachEvidenceRepository,
    CoachProblemStatementRepository,
    CoachSituationAnswerRepository,
  ],
  exports: [
    CoachReflectionService,
    CoachEvidenceRepository,
    CoachProblemStatementRepository,
    CoachSituationAnswerRepository,
  ],
})
export class CoachReflectionModule {}
