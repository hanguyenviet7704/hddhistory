import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { CoachDayLogService } from './coach-day-log.service';
import { UserDayLogRepository } from './repository/user-day-log.repository';
import { UserDayLog, UserDayLogSchema } from './schema/user-day-log.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: UserDayLog.name, schema: UserDayLogSchema },
    ]),
  ],
  providers: [CoachDayLogService, UserDayLogRepository],
  exports: [CoachDayLogService, UserDayLogRepository],
})
export class CoachDayLogModule {}
