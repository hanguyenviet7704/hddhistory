import { Provider } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { R2Service } from './r2.config';

export const R2ServiceProvider: Provider = {
  provide: R2Service,
  useFactory: (configService: ConfigService) => {
    return new R2Service(
      {
        accountId: configService.get<string>('CLOUDFLARE_R2_ACCOUNT_ID'),
        accessKeyId: configService.get<string>('CLOUDFLARE_R2_ACCESS_KEY_ID'),
        secretAccessKey: configService.get<string>(
          'CLOUDFLARE_R2_SECRET_ACCESS_KEY',
        ),
        bucketName: configService.get<string>('CLOUDFLARE_R2_BUCKET_NAME'),
        // publicUrl: configService.get<string>('CLOUDFLARE_R2_PUBLIC_URL'),
      },
      configService,
    );
  },
  inject: [ConfigService],
};
