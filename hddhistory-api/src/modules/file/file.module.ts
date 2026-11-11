import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { CloudflareController } from './cloudflare/cloudflare.controller';
import { CloudflareService } from './cloudflare/cloudflare.service';
import { R2Service } from './cloudflare/config/r2.config';
import { R2ServiceProvider } from './cloudflare/config/r2.provider';
import { DriveImportController } from './cloudflare/drive-import/drive-import.controller';
import { DriveImportService } from './cloudflare/drive-import/drive-import.service';
import { DriveImportJobRepository } from './cloudflare/drive-import/repository/drive-import-job.repository';
import {
  DriveImportJob,
  DriveImportJobSchema,
} from './cloudflare/drive-import/schema/drive-import-job.schema';
import { ImageCompressionService } from './cloudflare/image-compression.service';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    LoggerModule,
    MongooseModule.forFeature([
      { name: DriveImportJob.name, schema: DriveImportJobSchema },
    ]),
  ],
  controllers: [CloudflareController, DriveImportController],
  providers: [
    CloudflareService,
    R2ServiceProvider,
    DriveImportService,
    DriveImportJobRepository,
    ImageCompressionService,
  ],
  exports: [CloudflareService, R2Service],
})
export class FileModule {}
