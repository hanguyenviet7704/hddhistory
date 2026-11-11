import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import {
  SearchHistory,
  SearchHistorySchema,
} from './schema/search-history.schema';
import { SearchHistoryController } from './search-history.controller';
import { SearchHistoryRepository } from './search-history.repository';
import { SearchHistoryService } from './search-history.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SearchHistory.name, schema: SearchHistorySchema },
    ]),
    forwardRef(() => AuthModule),
  ],
  controllers: [SearchHistoryController],
  providers: [SearchHistoryService, SearchHistoryRepository],
})
export class SearchHistoryModule {}
