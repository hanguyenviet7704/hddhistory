import {
  Injectable,
  NotFoundException,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';
import { Repository } from 'typeorm';

import { Configuration } from '@base/config/configuration';
import { FirebaseService } from '@base/config/firebase';
import { LoggerService } from '@base/logging/logger.service';
import { RequestService } from '@base/service/request.service';
import { comparePassword, hashPassword } from '@utils/hash.utils';
import { JwtUtil } from '@utils/jwt';
import { UserProgressRepository } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/repository/user-progress.repository';
import { Purchase } from 'src/modules/payment/purchases/entities/purchase.entity';
import { Subscription } from 'src/modules/payment/subscriptions/entities/subscription.entity';

import { CreateUserDto } from './dto/create-user.dto';
import { DeviceDto } from './dto/device.dto';
import { GetListUserDto } from './dto/get-user.dto';
import { AnonymousDto, LoginDto, LoginWithProviderDto } from './dto/login.dto';
import { LogoutDto } from './dto/logout.dto';
import { PushRegistrationDto } from './dto/push-registration.dto';
import { RefreshTokenDto } from './dto/refreshtoken.dto';
import { ResetOnboardingDto } from './dto/reset-onboarding.dto';
import { TopicDto } from './dto/topic.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { IDevice } from './interface/device.interface';
import { IOnboarding } from './interface/onboarding.interface';
import { IUser } from './interface/user.interface';
import { UserRepository } from './repository/user.repository';
import { User } from './schema/user.schema';
import { OnboardingRepository } from '../onboarding/repository/onboarding.repository';

import type { UpdateQuery } from 'mongoose';

// Access-token lifetime is fixed in code (NOT read from the JWT_EXPIRATION env)
// so every environment — including already-deployed dev/prod whose server env
// may still say 1h — gets the same 7-day window. Change here to change it.
const ACCESS_TOKEN_EXPIRES_IN = '7d';

@Injectable()
export class AuthService {
  constructor(
    private readonly configuration: Configuration,
    private readonly userRepository: UserRepository,
    private readonly jwt: JwtUtil,
    private readonly logger: LoggerService,
    private readonly i18n: I18nService,
    private readonly requestService: RequestService,
    private readonly onboardingRepository: OnboardingRepository,
    private readonly firebaseService: FirebaseService,
    private readonly userProgressRepository: UserProgressRepository,
    @InjectRepository(Purchase)
    private readonly purchaseRepository: Repository<Purchase>,
    @InjectRepository(Subscription)
    private readonly subscriptionRepository: Repository<Subscription>,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  private async syncPaymentUserInfo(
    userId: string,
    payload: { name?: string; email?: string },
  ) {
    if (!payload.name && !payload.email) return;
    const purchaseUpdate: Partial<Purchase> = {};
    if (payload.name) purchaseUpdate.userName = payload.name;
    if (payload.email) purchaseUpdate.userEmail = payload.email;

    const subscriptionUpdate: Partial<Subscription> = {};
    if (payload.name) subscriptionUpdate.userName = payload.name;
    if (payload.email) subscriptionUpdate.userEmail = payload.email;

    await this.purchaseRepository.update({ userId }, purchaseUpdate as any);
    await this.subscriptionRepository.update(
      { userId },
      subscriptionUpdate as any,
    );
  }

  async checkDevice(user: User, device: DeviceDto, refreshToken: string) {
    const configuredMax = Number(this.configuration.maxDevice);
    const maxDevice =
      Number.isFinite(configuredMax) && configuredMax > 0 ? configuredMax : 2;

    let devices: IDevice[] = [...(user.devices ?? [])];

    const deviceExits = devices.find(e => e.deviceId === device.deviceId);

    if (deviceExits) {
      deviceExits.loginAt = new Date();
      deviceExits.refreshToken = refreshToken;
    } else {
      devices.push({ ...device, loginAt: new Date(), refreshToken });
    }

    if (devices && devices.length > maxDevice) {
      // Xoá thiết bị cũ nhất
      const oldest = devices.sort(
        (a, b) => a.loginAt.getTime() - b.loginAt.getTime(),
      )[0];

      devices = devices.filter(e => e.deviceId !== oldest.deviceId);
    }

    return devices;
  }

  private async handleLoginResponse(user: User, device: DeviceDto) {
    // generate token
    const token = await this.signToken({
      id: String(user._id),
      deviceId: device.deviceId,
      email: user.email,
      name: user.name,
      anonymous: user.anonymous,
      // `AuthGuard` gán thẳng payload này vào `req.user`, nên đây là TẤT CẢ
      // những gì phần còn lại của API biết về người gọi. Thiếu `role` thì
      // không tầng nào phía sau phân biệt được admin với người dùng app —
      // nhật ký thao tác admin đã im lặng không ghi gì vì đúng chỗ này.
      role: user.role,
    });

    // check and update device
    const devices = await this.checkDevice(user, device, token.refreshToken);
    await this.userRepository.updateOne({ _id: user._id }, { devices });

    // base data
    const response = {
      token,
      user: {
        _id: user._id,
        email: user.email,
        name: user.name,
        onboarding: user.onboarding,
        // The client uses this to skip onboarding for a returning, already-
        // onboarded account after a reinstall wiped its local flag. Without it
        // the client can't tell the server considers this user onboarded.
        isOnboarded: user.isOnboarded,
        // Carried into the JWT above since forever, but never into the body —
        // so the app parsed it as its `false` default on EVERY session, guest
        // included. Two client behaviours read it and both silently inverted:
        // the "a guest session already exists" guards never fired, and the
        // guest id a provider login is meant to hand back for an in-place
        // upgrade was always null, dropping the login onto its deviceId
        // fallback.
        anonymous: user.anonymous,
      },
    };

    return response;
  }

  async register(dto: CreateUserDto) {
    try {
      // ckeck email exists
      const exists = await this.userRepository.findOne({ email: dto.email });
      if (exists)
        throw new ConflictException(
          this.i18n.t('error.USER.EMAIL_EXISTS', {
            lang: this.lang,
          }),
        );

      // hash password
      const defaultPassword = '123456';
      const password = await hashPassword(defaultPassword);

      const user = (await this.userRepository.create({
        ...dto,
        password: password,
        anonymous: false,
        // A register payload carrying onboarding answers = onboarding completed.
        ...(dto.onboarding ? { isOnboarded: true } : {}),
      })) as IUser;

      return { _id: user._id, email: user.email, name: user.name };
    } catch (error) {
      this.logger.error({
        message: error as string,
        context: 'AuthService',
        trace: dto,
      });
      throw error;
    }
  }

  async anonymous(dto: AnonymousDto) {
    const { device, name, language, age, gender, onboarding } = dto;

    const updates: Partial<User> = {};
    if (name) updates.name = name;
    if (language) updates.language = language;
    if (age) updates.age = age;
    if (gender) updates.gender = gender;
    if (onboarding) {
      updates.onboarding = onboarding as unknown as IOnboarding;
      updates.isOnboarded = true;
    }

    const payload: Partial<User> = {
      email: `guest_${Date.now()}@hddhistory.com`,
      password: '',
      devices: [
        {
          deviceId: device.deviceId,
          deviceName: device.deviceName,
          loginAt: new Date(),
          refreshToken: '',
        },
      ],
      anonymous: true,
    };
    if (!name) {
      payload.name = 'Guest';
    }

    const filter = {
      anonymous: true,
      'devices.deviceId': device.deviceId,
    };
    const updateData: UpdateQuery<User> = {
      $setOnInsert: payload,
    };
    if (Object.keys(updates).length) {
      updateData.$set = updates;
    }

    let user: User | null;
    try {
      user = (await this.userRepository.findOneAndUpdate(filter, updateData, {
        upsert: true,
        setDefaultsOnInsert: true,
      })) as User;
    } catch (error) {
      if ((error as any).code === 11000) {
        if (Object.keys(updates).length) {
          user = (await this.userRepository.findOneAndUpdate(filter, {
            $set: updates,
          })) as User;
        } else {
          user = (await this.userRepository.findOne(filter)) as User;
        }
      } else {
        throw error;
      }
    }

    return this.handleLoginResponse(user as User, device);
  }

  async login(dto: LoginDto) {
    const { device, email, password } = dto;
    const user = await this.userRepository.findOne({ email: email });
    if (!user)
      throw new NotFoundException(
        this.i18n.t('error.USER.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const comparePW = await comparePassword(password, user.password);

    if (!comparePW)
      throw new UnauthorizedException(
        this.i18n.t('error.AUTH.INVALID_CREDENTIALS', {
          lang: this.lang,
        }),
      );

    return this.handleLoginResponse(user, device);
  }

  async loginWithProvider(decodedToken: any, dto: LoginWithProviderDto) {
    const { provider, device, anonymousUserId } = dto;

    const { uid, email, sub, user_id, displayName, name, picture, photoURL } =
      decodedToken;

    const providerIdentifier = uid ?? sub ?? user_id;
    const providerId = providerIdentifier
      ? providerIdentifier.toString()
      : undefined;

    if (!providerId && !email) {
      throw new UnauthorizedException(
        this.i18n.t('error.AUTH.INVALID_CREDENTIALS', {
          lang: this.lang,
        }),
      );
    }

    const data = {
      name: name || displayName,
      avatar: picture || photoURL,
      email,
      provider,
      providerId,
      providerData: decodedToken,
      anonymous: false,
    };
    const cleanedData = Object.fromEntries(
      Object.entries(data).filter(([, value]) => value !== undefined),
    );

    const projection = { password: 0, providerData: 0, refreshToken: 0 };

    let user: User | null = providerId
      ? await this.userRepository.findOne(
          {
            provider,
            providerId,
          },
          projection,
        )
      : null;

    if (!user && email) {
      // check xem đã có provider khác với email này chưa?
      user = await this.userRepository.findOne({ email }, projection);
      if (user) {
        let updateData: Partial<User>;
        if (user.name) {
          updateData = { ...cleanedData, anonymous: false, name: user.name };
        } else {
          updateData = { ...cleanedData, anonymous: false };
        }
        await this.userRepository.updateOne({ _id: user._id }, updateData);

        await this.syncPaymentUserInfo(String(user._id), {
          name: updateData.name,
          email: updateData.email,
        });
      }
    }

    if (!user) {
      // Upgrade the guest signed in on this device IN PLACE (same _id, so all
      // userId-keyed data — progress, habits, streaks — stays attached).
      // Prefer the explicit anonymousUserId the client passes (survives
      // reinstall / new device); fall back to a deviceId match for older
      // clients that don't send it. The explicit id is what removes the
      // silent progress-loss when the device fingerprint changed.
      if (anonymousUserId) {
        try {
          user = await this.userRepository.findOne(
            { _id: anonymousUserId, anonymous: true },
            projection,
          );
        } catch {
          // Malformed id (bad ObjectId) → ignore and fall back to device match.
          user = null;
        }
      }

      if (!user) {
        user = await this.userRepository.findOne(
          {
            devices: { $elemMatch: { deviceId: device.deviceId } },
            anonymous: true,
          },
          projection,
        );
      }

      if (user) {
        let updateData: Partial<User>;
        const providerName = cleanedData.name;
        const isGuestName =
          typeof user.name === 'string' && user.name.trim() === 'Guest';
        const shouldAdoptProviderName =
          user.anonymous && (!user.name || isGuestName);
        if (shouldAdoptProviderName && providerName) {
          updateData = { ...cleanedData, name: providerName };
        } else if (user.name) {
          updateData = { ...cleanedData, name: user.name };
        } else {
          updateData = { ...cleanedData };
        }
        await this.userRepository.updateOne({ _id: user._id }, updateData);

        await this.syncPaymentUserInfo(String(user._id), {
          name: updateData.name,
          email: updateData.email,
        });
      }

      if (!user) {
        user = (await this.userRepository.create({
          ...cleanedData,
          devices: [],
        })) as User;
      }
    }
    user = await this.userRepository.findOne({ _id: user._id }, projection);
    return this.handleLoginResponse(user, device);
  }

  async logout(dto: LogoutDto) {
    const { device } = dto;

    const user = await this.userRepository.findOne({ email: this.user.email });
    if (!user)
      throw new NotFoundException(
        this.i18n.t('error.USER.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const devices = user.devices?.filter(e => e.deviceId !== device.deviceId);

    return await this.userRepository.updateOne(
      { email: this.user.email },
      { devices },
    );
  }

  async refreshToken(id: string, dto: RefreshTokenDto) {
    const { refreshToken, device } = dto;
    const user = await this.userRepository.findOne({ _id: id });

    if (!user) {
      throw new NotFoundException(
        this.i18n.t('error.USER.NOT_FOUND', {
          lang: this.lang,
        }),
      );
    }

    const deviceExits = (user.devices || []).find(
      e => e.deviceId === device.deviceId,
    ) as IDevice;

    if (!deviceExits) {
      throw new UnauthorizedException(
        this.i18n.t('error.AUTH.WRONG_DEVICE', {
          lang: this.lang,
        }),
      );
    }

    if (deviceExits.refreshToken !== refreshToken) {
      throw new UnauthorizedException(
        this.i18n.t('error.AUTH.INVALID_REFRESH', {
          lang: this.lang,
        }),
      );
    }

    try {
      // verify refresh token
      const decode = await this.jwt.verify(refreshToken);
      if (!decode) {
        throw new UnauthorizedException(
          this.i18n.t('error.AUTH.INVALID_TOKEN_FORMAT', {
            lang: this.lang,
          }),
        );
      }

      if (decode.id?.toString?.() !== user._id.toString()) {
        throw new UnauthorizedException(
          this.i18n.t('error.AUTH.INVALID_TOKEN_FORMAT', {
            lang: this.lang,
          }),
        );
      }

      const accessToken = await this.jwt.sign(
        {
          id: String(user._id),
          deviceId: device.deviceId,
          email: user.email,
          name: user.name,
          // Phải KHỚP payload lúc đăng nhập. Thiếu ở đây thì mọi thứ chạy
          // đúng được bảy ngày rồi lặng lẽ hỏng ở lần làm mới token đầu tiên.
          role: user.role,
        },
        ACCESS_TOKEN_EXPIRES_IN,
      );
      return { token: { accessToken } };
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
    } catch (e) {
      throw new UnauthorizedException(
        this.i18n.t('error.AUTH.EXPIRED_REFRESH_TOKEN', {
          lang: this.lang,
        }),
      );
    }
  }

  async findAll(getListUserDto: GetListUserDto) {
    const result = await this.userRepository.findOption(getListUserDto);

    return result;
  }

  async checkOnboardingByDevice(deviceId: string) {
    // Recognize a user as onboarded if the flag is set OR they have already
    // saved onboarding answers. The flag alone proved unreliable (only written
    // by a separate fire-and-forget client PATCH that usually never landed), so
    // ~90% of users who *did* complete onboarding were re-shown it on every
    // reinstall. Answers present ⇒ onboarding was completed.
    const isOnboarded = (candidate: User) =>
      candidate.isOnboarded ||
      (!!candidate.onboarding && Object.keys(candidate.onboarding).length > 0);

    // The question this endpoint answers is "does this DEVICE belong to an
    // onboarded account", so every account holding the id has to be considered.
    // It used to read a single document and judge only that one, which broke as
    // soon as a device carried more than one — the usual case once a guest has
    // been upgraded by a provider login and a later sign-out minted a new guest
    // on the same device. A fresh guest has no answers, so whenever it happened
    // to be the one read, this returned null and the app re-ran onboarding for
    // somebody whose real account had completed it long ago.
    const candidates = await this.userRepository.findAllByDeviceId(deviceId);
    const onboarded = candidates.filter(isOnboarded);
    if (onboarded.length === 0) return null;

    // A real account outranks a leftover guest even when the guest signed in
    // more recently: the guest is the by-product of a sign-out, the real account
    // is the one whose progress the reader expects to come back to.
    const user =
      onboarded.find(candidate => candidate.anonymous === false) ?? onboarded[0];

    // let onboarding: IOnboarding | null = null;
    // if (user.onboarding) {
    //   const onboardings = await this.getOnboardings(user.onboarding);
    //   onboarding = onboardings as IOnboarding;
    // }

    return user;
  }

  async getOnboardings(onboarding: IOnboarding) {
    // Fetch the singleton onboarding-config document ONCE and slice all five
    // fields from it in memory. Each field was previously resolved by its own
    // findByFieldAndIds() call, i.e. 5 sequential full-document round-trips of
    // the same multi-KB, multi-language config doc on every /users/me request.
    const fields = await this.onboardingRepository.findFieldsByIds({
      skillsetWantToMaster: onboarding.skillsetWantToMaster,
      learningStruggles: onboarding.learningStruggles,
      comfortableLearningTime: [onboarding.comfortableLearningTime],
      dailyLearningGoal: [onboarding.dailyLearningGoal],
      learningGoal: [onboarding.learningGoal],
    });

    return {
      isNativeEnglishSpeaker: onboarding.isNativeEnglishSpeaker,
      skillsetWantToMaster: fields.skillsetWantToMaster,
      learningStruggles: fields.learningStruggles,
      comfortableLearningTime: fields.comfortableLearningTime?.[0] || null,
      dailyLearningGoal: fields.dailyLearningGoal?.[0] || null,
      learningGoal: fields.learningGoal?.[0] || null,
    };
  }

  async findOne(id: string) {
    const user = await this.userRepository.findOne(
      { _id: id },
      { password: 0, providerData: 0, refreshToken: 0 },
    );

    if (!user)
      throw new NotFoundException(
        this.i18n.t('error.USER.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    // get onboardings
    if (user.onboarding) {
      const onboardings = await this.getOnboardings(user.onboarding);
      user.onboarding = onboardings as IOnboarding;
    }

    return user;
  }

  async getProfile() {
    const userInfo = await this.userRepository.findOne(
      { _id: this.user.id },
      { password: 0, providerData: 0, refreshToken: 0 },
    );
    if (!userInfo)
      throw new NotFoundException(
        this.i18n.t('error.USER.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    // get onboardings
    if (userInfo.onboarding) {
      const onboardings = await this.getOnboardings(userInfo.onboarding);
      userInfo.onboarding = onboardings as IOnboarding;
    }

    return userInfo;
  }

  async update(id: string, dto: UpdateUserDto) {
    const patch: UpdateUserDto = { ...dto };
    // Submitting onboarding answers means the user completed onboarding — set
    // the flag here (server-side, atomic with the answers) instead of relying
    // on a separate fire-and-forget client PATCH that frequently never lands
    // (that gap left ~90% of onboarded users being re-onboarded on reinstall).
    if (patch.onboarding) patch.isOnboarded = true;
    const result = await this.userRepository.updateOne(
      { _id: id },
      { ...patch },
      this.user,
    );

    if (dto.name) {
      await this.syncPaymentUserInfo(id, {
        name: dto.name,
        email: dto.email,
      });
    }

    return result;
  }

  async remove(id: string) {
    const deleteUser = await this.userRepository.deleteOne({ _id: id });

    // xoá kết quả tiến độ học tập
    await this.userProgressRepository.removeManyByUserId(id);

    return deleteUser;
  }

  async resetOnboarding(dto: ResetOnboardingDto) {
    const { userId, email } = dto;
    if (!userId && !email) {
      throw new BadRequestException('Either userId or email is required');
    }

    const user = await this.userRepository.findOne(
      userId ? { _id: userId } : { email },
    );
    if (!user)
      throw new NotFoundException(
        this.i18n.t('error.USER.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    // A user is treated as onboarded if isOnboarded is true OR their
    // onboarding object has any keys (see checkOnboardingByDevice above), so
    // both must be cleared for the client to show onboarding again.
    await this.userRepository.resetOnboarding(String(user._id));

    return {
      id: user._id,
      email: user.email,
      name: user.name,
      isOnboarded: false,
    };
  }

  async devLogin(email: string, deviceId = 'dev-swagger-001') {
    const user = await this.userRepository.findOne({ email });
    if (!user)
      throw new NotFoundException(
        this.i18n.t('error.USER.NOT_FOUND', { lang: this.lang }),
      );
    return this.handleLoginResponse(user, {
      deviceId,
      deviceName: 'Dev/Swagger',
    });
  }

  async signToken(payload: any) {
    const accessToken = await this.jwt.sign(
      payload,
      ACCESS_TOKEN_EXPIRES_IN,
    );

    const refreshToken = await this.jwt.sign(
      { id: payload.id },
      this.configuration.getJwtRefreshExpiration || '7d',
    );

    return { accessToken, refreshToken };
  }

  async subscribeTopic(dto: TopicDto) {
    await this.firebaseService.subscribeTopicByToken(dto.token, dto.topic);
    return { topic: dto.topic };
  }

  async unsubscribeTopic(dto: TopicDto) {
    await this.firebaseService.unsubscribeTopicByToken(dto.token, dto.topic);
    return { topic: dto.topic };
  }

  /**
   * Records the push token, in-app notification switch, time zone and locale for
   * the device this request is authenticated as — everything the scheduled
   * notifications need to reach one specific user at a local hour.
   *
   * The device is taken from the access token, never from the body: a client
   * could otherwise write its token onto another entry in the array.
   */
  async registerPushDevice(
    dto: PushRegistrationDto,
    user?: IUser & { id?: string; deviceId?: string },
  ) {
    const userId = user?.id ?? (user?._id ? String(user._id) : '');
    const deviceId = user?.deviceId ?? '';
    if (!userId || !deviceId) {
      throw new BadRequestException('Missing authenticated device');
    }

    // The device row is created at login and evicted when the max-device limit
    // is hit, so a token can arrive for an entry that no longer exists. Say so
    // instead of silently doing nothing — the app should re-login, and a silent
    // 200 would look like push was armed when it never was.
    const exists = await this.userRepository.checkExitsDevice(userId, deviceId);
    if (!exists) {
      throw new NotFoundException('Device not found for this user');
    }

    await this.userRepository.detachPushTokenFromOtherUsers(
      dto.pushToken,
      userId,
    );

    await this.userRepository.setDevicePush(userId, deviceId, {
      pushToken: dto.pushToken,
      // Absent means the app didn't say; treat as opted in, matching the OS
      // default after permission is granted.
      pushEnabled: dto.pushEnabled ?? true,
      pushPlatform: dto.platform,
    });

    const profileUpdate: Partial<User> = {};
    if (dto.timezone) profileUpdate.timezone = dto.timezone;
    if (dto.language) profileUpdate.language = dto.language;
    if (Object.keys(profileUpdate).length > 0) {
      await this.userRepository.updateOne({ _id: userId }, profileUpdate);
    }

    return { registered: true };
  }
}
