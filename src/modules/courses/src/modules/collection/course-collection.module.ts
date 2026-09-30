import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { CourseCollectionController } from './course-collection.controller';
import { CourseCollectionService } from './course-collection.service';
import { CourseCollectionRepository } from './repository/course-collection.repository';
import {
  CourseCollection,
  CourseCollectionSchema,
} from './schema/course-collection.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CourseCollection.name, schema: CourseCollectionSchema },
    ]),
    // AuthModule because the controller is behind AuthGuard: a guard's
    // dependencies resolve in the module that DECLARES the controller, and
    // neither tsc nor nest build can see that one is missing.
    AuthModule,
    LoggerModule,
  ],
  controllers: [CourseCollectionController],
  providers: [CourseCollectionService, CourseCollectionRepository],
  exports: [CourseCollectionService, CourseCollectionRepository],
})
export class CourseCollectionModule {}
