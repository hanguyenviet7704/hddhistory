import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { PromoStatRepository } from './repository/promo-stat.repository';
import { PromoStat, PromoStatSchema } from './schema/promo-stat.schema';

/**
 * Impression/click counters shared by the Home banner and the Home popup.
 *
 * Its own module rather than a repository inside either feature: BOTH need it,
 * and a repository can only be provided once — whichever module owned it, the
 * other would have to import that whole feature just for a counter. No
 * controller and no service on purpose; the feature services own the rules of
 * WHEN to count, this module only knows how.
 */
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PromoStat.name, schema: PromoStatSchema },
    ]),
  ],
  providers: [PromoStatRepository],
  exports: [PromoStatRepository],
})
export class PromoStatsModule {}
