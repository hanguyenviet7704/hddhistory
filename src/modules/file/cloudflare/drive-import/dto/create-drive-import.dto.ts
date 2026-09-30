import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsUrl } from 'class-validator';

export class CreateDriveImportDto {
  @ApiProperty({
    description: 'Public Google Drive folder URL that contains media folders',
    example: 'https://drive.google.com/drive/folders/1AbCdEfGhIjKlMnOp',
  })
  @IsString()
  @IsNotEmpty()
  @IsUrl()
  folderUrl: string;
}
