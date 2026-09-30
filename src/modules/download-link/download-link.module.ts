import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { DownloadLinkRedirectController } from './download-link-redirect.controller';
import { DownloadLinkController } from './download-link.controller';
import { DownloadLinkService } from './download-link.service';
import { DownloadLinkClick } from './entities/download-link-click.entity';
import { DownloadLink } from './entities/download-link.entity';
import { DownloadLinkClickRepository } from './repositories/download-link-click.repository';
import { DownloadLinkRepository } from './repositories/download-link.repository';

@Module({
  imports: [
    TypeOrmModule.forFeature([DownloadLink, DownloadLinkClick]),
    AuthModule,
  ],
  controllers: [DownloadLinkController, DownloadLinkRedirectController],
  providers: [
    DownloadLinkService,
    DownloadLinkRepository,
    DownloadLinkClickRepository,
  ],
  exports: [DownloadLinkService],
})
export class DownloadLinkModule {}
