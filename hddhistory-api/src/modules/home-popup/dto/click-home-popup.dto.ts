import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength } from 'class-validator';

export class ClickHomePopupDto {
  @ApiProperty({
    example: '3f2a1c9d8e7b6a54',
    description:
      'The campaign key the app was shown (from GET /home-popup). Sent by the ' +
      'client rather than recomputed here so the tap records the creative the ' +
      'user actually saw, not whatever the admin published in the seconds since. ' +
      'Rejected unless it is 16 lowercase hex characters',
  })
  @IsString()
  @MaxLength(64)
  campaignKey: string;
}
