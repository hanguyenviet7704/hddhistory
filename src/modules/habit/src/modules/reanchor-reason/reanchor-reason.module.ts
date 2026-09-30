import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { ReanchorReasonController } from './reanchor-reason.controller';
import { ReanchorReasonService } from './reanchor-reason.service';
import { ReanchorReasonRepository } from './repository/reanchor-reason.repository';
import {
  ReanchorReason,
  ReanchorReasonSchema,
} from './schema/reanchor-reason.schema';
import { HabitContentModule } from '../../shared/habit-content.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ReanchorReason.name, schema: ReanchorReasonSchema },
    ]),
    AuthModule,
    HabitContentModule,
  ],
  controllers: [ReanchorReasonController],
  providers: [ReanchorReasonService, ReanchorReasonRepository],
  exports: [ReanchorReasonService, ReanchorReasonRepository],
})
export class ReanchorReasonModule {}
