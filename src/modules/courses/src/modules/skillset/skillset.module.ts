import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { SkillsetRepository } from './repository/skillset.repository';
import { Skillset, SkillsetSchema } from './schema/skillset.schema';
import { SkillsetController } from './skillset.controller';
import { SkillsetService } from './skillset.service';
import { CourseModule } from '../course/course.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Skillset.name, schema: SkillsetSchema },
    ]),
    AuthModule,
    LoggerModule,
    forwardRef(() => CourseModule),
  ],
  controllers: [SkillsetController],
  providers: [SkillsetService, SkillsetRepository],
  exports: [SkillsetService, SkillsetRepository],
})
export class SkillsetModule {}
