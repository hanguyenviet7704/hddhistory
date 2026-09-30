import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  Put,
  Delete,
  UseGuards,
  Query,
  Req,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';

import { Public } from '@base/decorator/public';
import { AuthGuard } from '@base/guard/auth.guard';
import { FirebaseAuthGuard } from '@base/guard/firebase-auth.guard';

import { AuthService } from './auth.service';
import { CreateUserDto } from './dto/create-user.dto';
import { GetListUserDto } from './dto/get-user.dto';
import {
  AnonymousDto,
  DevLoginDto,
  LoginDto,
  LoginWithProviderDto,
} from './dto/login.dto';
import { LogoutDto } from './dto/logout.dto';
import { PushRegistrationDto } from './dto/push-registration.dto';
import { RefreshTokenDto } from './dto/refreshtoken.dto';
import { ResetOnboardingDto } from './dto/reset-onboarding.dto';
import { TopicDto } from './dto/topic.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@ApiTags('USERS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'users', version: '1' })
export class AuthController {
  constructor(
    private readonly svc: AuthService,
    private readonly configService: ConfigService,
  ) {}

  @Public()
  @Post('register')
  register(@Body() dto: CreateUserDto) {
    return this.svc.register(dto);
  }

  @Public()
  @Post('anonymous')
  anonymous(@Body() dto: AnonymousDto) {
    return this.svc.anonymous(dto);
  }

  @Public()
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.svc.login(dto);
  }

  @Public()
  @Post('dev-login')
  devLogin(@Body() dto: DevLoginDto) {
    if (this.configService.get('NODE_ENV') === 'production') {
      throw new NotFoundException();
    }
    return this.svc.devLogin(dto.email, dto.deviceId);
  }

  @Post('logout')
  logout(@Body() dto: LogoutDto) {
    return this.svc.logout(dto);
  }

  @Public()
  @UseGuards(FirebaseAuthGuard)
  @Post('login/provider')
  async loginWithProvider(
    @Req() req: Request,
    @Body() body: LoginWithProviderDto,
  ) {
    const result = await this.svc.loginWithProvider(req.user, body);

    return {
      token: result.token,
      user: result.user,
    };
  }

  @Public()
  @Post(':id/refresh-token')
  async refresh(@Param('id') id: string, @Body() dto: RefreshTokenDto) {
    return this.svc.refreshToken(id, dto);
  }

  @Get('me')
  async getProfile() {
    const result = await this.svc.getProfile();

    return result;
  }

  @Get()
  findAll(@Query() dto: GetListUserDto) {
    return this.svc.findAll(dto);
  }

  @Public()
  @Get('check-onboarding/:deviceId')
  getAccountByDevice(@Param('deviceId') deviceId: string) {
    return this.svc.checkOnboardingByDevice(deviceId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateUserDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }

  @Post('reset-onboarding')
  resetOnboarding(@Body() dto: ResetOnboardingDto) {
    return this.svc.resetOnboarding(dto);
  }

  /**
   * Called by the app after notification permission is granted and on every FCM
   * token refresh. Authenticated on purpose (unlike `subscribe-topic`): the
   * token is stored against the caller's own device entry.
   */
  @Post('push-registration')
  registerPushDevice(@Body() dto: PushRegistrationDto, @Req() req: Request) {
    return this.svc.registerPushDevice(dto, req.user as any);
  }

  @Public()
  @Post('subscribe-topic')
  subscribeTopic(@Body() dto: TopicDto) {
    return this.svc.subscribeTopic(dto);
  }

  @Public()
  @Post('unsubscribe-topic')
  unsubscribeTopic(@Body() dto: TopicDto) {
    return this.svc.unsubscribeTopic(dto);
  }
}
