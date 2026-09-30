import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class DeleteSubscriptionDto {
  @ApiProperty({
    description: 'Deletion confirmation password',
    example: 'admin-delete-password',
  })
  @IsString()
  @IsNotEmpty()
  confirmPassword: string;
}
