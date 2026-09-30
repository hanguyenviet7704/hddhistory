import { forwardRef, Module } from '@nestjs/common';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { DeeplinkController } from './deeplink.controller';

/**
 * `forwardRef(() => AuthModule)` là BẮT BUỘC, không phải phong cách:
 * `@UseGuards(AuthGuard)` trong một module chưa import AuthModule làm app
 * crash-loop lúc boot, và cả `tsc --noEmit` lẫn `nest build` đều không thấy.
 * Cùng khuôn với `streak-config.module.ts`.
 */
@Module({
  imports: [forwardRef(() => AuthModule)],
  controllers: [DeeplinkController],
})
export class DeeplinkModule {}
