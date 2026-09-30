import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { QuoteController } from './quote.controller';
import { QuoteService } from './quote.service';
import { QuoteRepository } from './repository/quote.repository';
import { Quote, QuoteSchema } from './schema/quote.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Quote.name, schema: QuoteSchema }]),
    forwardRef(() => AuthModule),
    LoggerModule,
  ],
  controllers: [QuoteController],
  providers: [QuoteService, QuoteRepository],
  exports: [QuoteService, QuoteRepository],
})
export class QuoteModule {}
