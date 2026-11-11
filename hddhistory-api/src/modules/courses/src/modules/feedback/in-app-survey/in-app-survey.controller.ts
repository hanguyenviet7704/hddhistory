import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Put,
  Query,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { Response } from 'express';

import { AuthGuard } from '@base/guard/auth.guard';

import { GetInAppSurveyResponsesDto } from './dto/get-in-app-survey-responses.dto';
import { UpsertInAppSurveyConfigDto } from './dto/in-app-survey-config.dto';
import {
  ExportInAppSurveyResponsesDto,
  GetInAppSurveyBranchResponsesDto,
  GetInAppSurveyUserResponsesDto,
  InAppSurveyDateRangeDto,
  StartInAppSurveySessionDto,
} from './dto/in-app-survey-statistics.dto';
import { SubmitInAppSurveyResponseDto } from './dto/submit-in-app-survey-response.dto';
import { InAppSurveyService } from './in-app-survey.service';

@ApiTags('COURSES-IN-APP-SURVEY')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-in-app-survey', version: '1' })
export class InAppSurveyController {
  constructor(private readonly inAppSurveyService: InAppSurveyService) {}

  @Get('config')
  getConfig() {
    return this.inAppSurveyService.getConfig();
  }

  @Put('config')
  upsertConfig(@Body() dto: UpsertInAppSurveyConfigDto) {
    return this.inAppSurveyService.upsertConfig(dto);
  }

  @Get('config/import/template')
  async getSurveyImportTemplate(@Res() res: Response) {
    const buffer = await this.inAppSurveyService.getSurveyImportTemplate();
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="in-app-survey-import-template.xlsx"',
    );
    res.send(buffer);
  }

  @Post('config/import')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async importSurvey(
    @UploadedFile() file: Express.Multer.File,
    @Res() res: Response,
  ) {
    const buffer = await this.inAppSurveyService.importSurvey(file);
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="in-app-survey-import-result.xlsx"',
    );
    res.send(buffer);
  }

  @Post('sessions/start')
  startSession(@Body() dto: StartInAppSurveySessionDto) {
    return this.inAppSurveyService.startSession(dto);
  }

  @Post('responses')
  submitResponse(@Body() dto: SubmitInAppSurveyResponseDto) {
    return this.inAppSurveyService.submitResponse(dto);
  }

  @Get('statistics/overview')
  getStatisticsOverview(@Query() dto: InAppSurveyDateRangeDto) {
    return this.inAppSurveyService.getStatisticsOverview(dto);
  }

  @Get('statistics/branches/:branchId/responses')
  getBranchResponses(
    @Param('branchId') branchId: string,
    @Query() dto: GetInAppSurveyBranchResponsesDto,
  ) {
    return this.inAppSurveyService.getBranchResponses(branchId, dto);
  }

  @Get('statistics/users/responses')
  getUserResponses(@Query() dto: GetInAppSurveyUserResponsesDto) {
    return this.inAppSurveyService.getUserResponses(dto);
  }

  @Get('statistics/export')
  async exportResponses(
    @Query() dto: ExportInAppSurveyResponsesDto,
    @Res() res: Response,
  ) {
    const buffer = await this.inAppSurveyService.exportResponsesWorkbook(dto);
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="in-app-survey-responses.xlsx"',
    );
    res.send(buffer);
  }

  @Get('responses/me')
  getMyResponses() {
    return this.inAppSurveyService.getMyResponses();
  }

  @Get('responses')
  getResponses(@Query() dto: GetInAppSurveyResponsesDto) {
    return this.inAppSurveyService.getResponses(dto);
  }

  @Get('responses/users/:userId')
  getResponsesByUserId(@Param('userId') userId: string) {
    return this.inAppSurveyService.getResponsesByUserId(userId);
  }
}
