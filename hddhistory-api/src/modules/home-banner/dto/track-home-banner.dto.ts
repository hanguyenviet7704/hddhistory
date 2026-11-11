import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength } from 'class-validator';

export class TrackHomeBannerDto {
  @ApiProperty({
    example: '3f2a1c9d8e7b6a54',
    description:
      'The campaign key of the slide the app was shown (from GET /home-banner). ' +
      'Sent by the client rather than recomputed here so the event records the ' +
      'creative the viewer actually saw, not whatever the admin published in ' +
      'the seconds since. Rejected unless it is 16 lowercase hex characters',
  })
  @IsString()
  @MaxLength(64)
  campaignKey: string;
}
