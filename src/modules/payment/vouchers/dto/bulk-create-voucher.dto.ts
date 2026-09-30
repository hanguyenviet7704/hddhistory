import { ApiProperty, OmitType } from '@nestjs/swagger';
import { ArrayMinSize, IsArray, IsString } from 'class-validator';

import { CreateVoucherDto } from './create-voucher.dto';

export class BulkCreateVoucherDto extends OmitType(CreateVoucherDto, [
  'code',
]) {
  @ApiProperty({
    type: [String],
    required: true,
    example: ['SUMMER50-001', 'SUMMER50-002', 'SUMMER50-003'],
    description:
      'List of codes pasted from the affiliate platform. Each will be ' +
      'stored trimmed + uppercased; codes that already exist are skipped.',
  })
  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  codes: string[];
}
