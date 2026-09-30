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
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { RoleplayColorTemplateDto } from './dto/roleplays/color-template.dto';
import { GetListRoleplayColorTemplateDto } from './dto/roleplays/get-color-template.dto';
import { RoleplayColorTemplateService } from './roleplay-color-template.service';

@ApiTags('COURSES-ROLEPLAY-COLORS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-roleplay-colors', version: '1' })
export class RoleplayColorTemplateController {
  constructor(
    private readonly svc: RoleplayColorTemplateService,
    private readonly configService: ConfigService,
  ) {}

  @Post('')
  createRoleplayColor(@Body() dto: RoleplayColorTemplateDto) {
    return this.svc.create(dto);
  }

  @Put('/:id')
  updateRoleplayColor(
    @Param('id') id: string,
    @Body() dto: RoleplayColorTemplateDto,
  ) {
    return this.svc.update(id, dto);
  }

  @Get('')
  findAllRoleplayColor(@Query() dto: GetListRoleplayColorTemplateDto) {
    return this.svc.findAll(dto);
  }

  @Get('/:id')
  findOneRoleplayColor(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @Delete('/:id')
  removeRoleplayColor(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
