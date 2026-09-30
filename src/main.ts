import 'dotenv/config';
import { join } from 'path';

import { VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { json, urlencoded } from 'express';

import { setupSwagger } from '@base/config/swagger';
import { AllExceptionsFilter } from '@base/filters/all-exceptions.filter';
import { ResponseInterceptor } from '@base/interceptors/response.interceptor';
import { LoggerService } from '@base/logging/logger.service';
import { BaseValidationPipe } from '@base/validate/pipe';

import { AppModule } from './app.module';

async function bootstrap() {
  // Disable Nest's default body parser so we can raise the JSON size limit:
  // bulk import endpoints (habits/reanchor-reasons) post large multilingual
  // payloads that blow past the 100kb default (which surfaces as a confusing
  // PayloadTooLargeError). 25mb stays well under the Cloudflare request cap.
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    bodyParser: false,
  });
  app.useStaticAssets(join(process.cwd(), 'public'), {
    prefix: '/static/',
  });
  app.use(json({ limit: '25mb' }));
  app.use(urlencoded({ extended: true, limit: '25mb' }));

  // Global pipe
  app.useGlobalPipes(new BaseValidationPipe());

  // Global exception filter
  const loggerService = app.get(LoggerService);
  app.useGlobalFilters(new AllExceptionsFilter(loggerService));

  // Global response
  app.useGlobalInterceptors(new ResponseInterceptor());

  app.setGlobalPrefix('api');

  // api versioning
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // Swagger
  setupSwagger(app);

  app.enableCors({
    origin: [
      'http://localhost:3000',
      'http://localhost:3001',
      'http://localhost:3002',
      'https://admin.meup.training',
      'https://admin-dev.meup.training',
    ],
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  const configService = app.get(ConfigService);

  const PORT = configService.get('PORT') || 4000;

  await app.listen(PORT);
  console.log(`Application is running on: ${PORT}`);
}
bootstrap();
