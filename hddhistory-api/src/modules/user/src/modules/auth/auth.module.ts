import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';

import { ConfigurationProvider } from '@base/config/configuration.provider';
import { FirebaseService } from '@base/config/firebase';
import { LoggerModule } from '@base/logging/logger.module';
import { JwtUtil } from '@utils/jwt';
import { UserProgressModule } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/user-progress.module';
import { Purchase } from 'src/modules/payment/purchases/entities/purchase.entity';
import { Subscription } from 'src/modules/payment/subscriptions/entities/subscription.entity';

import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { UserRepository } from './repository/user.repository';
import { User, UserSchema } from './schema/user.schema';
import { OnboardingsModule } from '../onboarding/onboarding.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
    TypeOrmModule.forFeature([Purchase, Subscription]),
    PassportModule.register({ session: false }),
    LoggerModule,
    forwardRef(() => OnboardingsModule),
    UserProgressModule,
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    UserRepository,
    JwtUtil,
    ConfigurationProvider,
    FirebaseService,
  ],
  // FirebaseService is exported (not just provided) so other modules can
  // inject the SAME instance instead of re-providing FirebaseService
  // themselves -- its constructor calls `admin.initializeApp()`, which
  // throws if the default app is initialised twice.
  exports: [
    AuthService,
    JwtUtil,
    ConfigurationProvider,
    UserRepository,
    FirebaseService,
  ],
})
export class AuthModule {}
