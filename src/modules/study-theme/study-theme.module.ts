import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { StudyThemePresetRepository } from './repository/study-theme-preset.repository';
import {
  StudyThemePreset,
  StudyThemePresetSchema,
} from './schema/study-theme-preset.schema';
import { StudyThemeController } from './study-theme.controller';
import { StudyThemeService } from './study-theme.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: StudyThemePreset.name, schema: StudyThemePresetSchema },
    ]),
    forwardRef(() => AuthModule),
    LoggerModule,
  ],
  controllers: [StudyThemeController],
  providers: [StudyThemeService, StudyThemePresetRepository],
  exports: [StudyThemeService, StudyThemePresetRepository],
})
export class StudyThemeModule {}
