import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsString } from 'class-validator';

import { VoiceoverProvider } from '../enum/voiceover-provider.enum';

export class UpdateVoiceoverSettingsDto {
  @ApiProperty({
    example: 'hn_female_ngochuyen_full_48k-fhg',
    description:
      'Vbee voiceCode used for Vietnamese on courses switched to Vbee. ' +
      'Validated against the account catalogue before it is stored.',
  })
  @IsString()
  @IsNotEmpty()
  vbeeVoiceCode: string;
}

export class SetCourseVoiceoverProviderDto {
  @ApiProperty({
    enum: VoiceoverProvider,
    example: VoiceoverProvider.VBEE,
    description:
      'Speech engine for this course’s Vietnamese. `vbee` is billed per ' +
      'character and is refused when the environment has no Vbee credentials.',
  })
  @IsEnum(VoiceoverProvider)
  provider: VoiceoverProvider;
}
