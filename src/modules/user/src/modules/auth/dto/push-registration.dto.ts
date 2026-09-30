import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';

/**
 * What the app reports so the server can send it a scheduled notification.
 *
 * No `deviceId`: the access token already carries the one this request is
 * authenticated for, and trusting a body value would let a client write push
 * settings onto somebody else's device entry.
 */
export class PushRegistrationDto {
  @ApiProperty({
    example: 'f3eWxXFxT3i4z2_9pn9cKX:APA91bF...',
    description: 'Firebase registration token for this device',
  })
  @IsString()
  @IsNotEmpty()
  pushToken: string;

  @ApiPropertyOptional({
    example: true,
    description:
      "The app's own notification switch. False means the user opted out in-app, so the server must not send.",
  })
  @IsOptional()
  @IsBoolean()
  pushEnabled?: boolean;

  @ApiPropertyOptional({ example: 'ios', enum: ['ios', 'android'] })
  @IsOptional()
  @IsIn(['ios', 'android'])
  platform?: string;

  @ApiPropertyOptional({
    example: 'Asia/Ho_Chi_Minh',
    description: 'IANA time zone, used to resolve the local send hour',
  })
  @IsOptional()
  @IsString()
  timezone?: string;

  @ApiPropertyOptional({
    example: 'vi',
    description: 'App locale, picks the notification copy',
  })
  @IsOptional()
  @IsString()
  language?: string;
}
