import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { SegmentSnapshotRepository } from './repository/segment-snapshot.repository';
import { SegmentRepository } from './repository/segment.repository';
import {
  SegmentSnapshot,
  SegmentSnapshotSchema,
} from './schema/segment-snapshot.schema';
import { Segment, SegmentSchema } from './schema/segment.schema';
import { SegmentMemberFilterService } from './segment-member-filter.service';
import { SegmentSnapshotService } from './segment-snapshot.service';
import { SegmentController } from './segment.controller';
import { SegmentService } from './segment.service';
import { SubscriptionsModule } from '../payment/subscriptions/subscriptions.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Segment.name, schema: SegmentSchema },
      { name: SegmentSnapshot.name, schema: SegmentSnapshotSchema },
    ]),
    // AuthGuard's dependencies AND the UserRepository the counting runs on.
    forwardRef(() => AuthModule),
    // SubscriptionService, for the user_type buckets (premium is a MySQL fact).
    SubscriptionsModule,
  ],
  controllers: [SegmentController],
  providers: [
    SegmentService,
    SegmentMemberFilterService,
    SegmentSnapshotService,
    SegmentRepository,
    SegmentSnapshotRepository,
  ],
  // SegmentMemberFilterService is exported separately BECAUSE SegmentService is
  // request-scoped (it injects RequestService): a background job that imported
  // the latter would bubble that scope up and silently kill its own @Cron.
  exports: [SegmentService, SegmentMemberFilterService],
})
export class SegmentModule {}
