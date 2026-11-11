import { Module } from '@nestjs/common';

import { ConfigurationProvider } from '@base/config/configuration.provider';

import { OutputPracticeAiService } from './output-practice-ai.service';

@Module({
  providers: [OutputPracticeAiService, ConfigurationProvider],
  exports: [OutputPracticeAiService],
})
export class OutputPracticeAiModule {}
