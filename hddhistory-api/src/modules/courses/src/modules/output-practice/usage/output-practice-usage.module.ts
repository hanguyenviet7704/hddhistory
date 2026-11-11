import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { OutputPracticeUsageRepository } from './repository/output-practice-usage.repository';
import {
  OutputPracticeUsage,
  OutputPracticeUsageSchema,
} from './schema/output-practice-usage.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      {
        name: OutputPracticeUsage.name,
        schema: OutputPracticeUsageSchema,
      },
    ]),
  ],
  providers: [OutputPracticeUsageRepository],
  exports: [OutputPracticeUsageRepository],
})
export class OutputPracticeUsageModule {}
