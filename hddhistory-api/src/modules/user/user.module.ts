import { Module } from '@nestjs/common';

import { AuthModule } from './src/modules/auth/auth.module';
import { OnboardingsModule } from './src/modules/onboarding/onboarding.module';

@Module({
  imports: [AuthModule, OnboardingsModule],
})
export class UserModule {}
