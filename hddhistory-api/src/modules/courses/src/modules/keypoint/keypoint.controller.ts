import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  Put,
  Delete,
  Res,
  UseGuards,
  UploadedFile,
  Query,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { Response } from 'express';

import { AuthGuard } from '@base/guard/auth.guard';

import { CreateKeypointDto } from './dto/create-keypoint.dto';
import { GetListKeypointDto } from './dto/get-list-keypoint.dto';
import { UpdateKeypointDto } from './dto/update-keypoint.dto';
import { KeypointService } from './keypoint.service';

@ApiTags('COURSES-KEYPOINTS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-keypoints', version: '1' })
export class KeypointController {
  constructor(private readonly svc: KeypointService) {}

  @Post('')
  register(@Body() dto: CreateKeypointDto) {
    return this.svc.create(dto);
  }

  @Post('import')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async importKeypoints(
    @UploadedFile() file: Express.Multer.File,
    @Res() res: Response,
  ) {
    const buffer = await this.svc.importKeypoints(file);
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="keypoint-import-result.xlsx"',
    );
    res.send(buffer);
  }

  @Get('export')
  async exportKeypoints(@Res() res: Response) {
    const buffer = await this.svc.exportKeypoints();
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="keypoint-export.xlsx"',
    );
    res.send(buffer);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateKeypointDto) {
    return this.svc.update(id, dto);
  }

  @Get()
  findAll(@Query() dto: GetListKeypointDto) {
    return this.svc.findAll(dto);
  }

  /** `?version=v1.0.0` hoặc `?version=current` — chỉ panel dùng được. */
  @Get(':id')
  findOne(@Param('id') id: string, @Query('version') version?: string) {
    return this.svc.findOne(id, version);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
