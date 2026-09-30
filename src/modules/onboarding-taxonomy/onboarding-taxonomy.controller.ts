import {
  Body,
  Controller,
  Get,
  Post,
  Put,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { Response } from 'express';

import { Public } from '@base/decorator/public';
import { AuthGuard } from '@base/guard/auth.guard';

import { SaveOnboardingTaxonomyDto } from './dto/save-onboarding-taxonomy.dto';
import { OnboardingTaxonomyImportService } from './onboarding-taxonomy-import.service';
import { OnboardingTaxonomyService } from './onboarding-taxonomy.service';

/**
 * The onboarding branch/package/label taxonomy — `PUT` and `POST /import`
 * wipe and rewrite all three collections (`replaceAll` = delete-all-then-
 * insert) plus, via import, every tagged course's onboarding labels/desire.
 *
 * ## Why this is AuthGuard-only, not @Roles(ADMIN)
 *
 * The same reason every other admin controller here is — see
 * `user-habit-admin.controller.ts` for the long version. Nothing populates
 * `user.role` (the real admin account is `role: USER`), and `PUT /users/:id`
 * lets any caller set their own role behind `AuthGuard` alone, so the decorator
 * would 403 the admin panel and secure nothing. It is a real trust gap — this
 * one can wipe three collections plus every course's onboarding tags — but it
 * is the SAME gap the whole admin surface has, and closing it means fixing
 * `PUT /users/:id` and the role data first, then reinstating the guard
 * everywhere at once.
 */
@ApiTags('ONBOARDING-TAXONOMY')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'onboarding-taxonomy', version: '1' })
export class OnboardingTaxonomyController {
  constructor(
    private readonly svc: OnboardingTaxonomyService,
    private readonly importService: OnboardingTaxonomyImportService,
  ) {}

  /** App đọc ở S4 trước khi chắc có token ẩn danh → public như /onboarding-config. */
  @Public()
  @Get('')
  getPublic() {
    return this.svc.getPublic();
  }

  @Get('admin')
  getAdmin() {
    return this.svc.getAdmin();
  }

  @Put('')
  replace(@Body() dto: SaveOnboardingTaxonomyDto) {
    return this.svc.replace(dto);
  }

  @Get('template')
  async template(@Res() res: Response) {
    this.sendExcel(
      res,
      await this.importService.template(),
      'onboarding-taxonomy-template.xlsx',
    );
  }

  @Get('export')
  async export(@Res() res: Response) {
    this.sendExcel(
      res,
      await this.importService.export(),
      'onboarding-taxonomy-export.xlsx',
    );
  }

  @Post('import')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async import(
    @UploadedFile() file: Express.Multer.File,
    @Res() res: Response,
  ) {
    const { buffer, warnings } = await this.importService.import(file);
    res.setHeader('X-Import-Warnings', String(warnings));
    res.setHeader(
      'Access-Control-Expose-Headers',
      'X-Import-Warnings, Content-Disposition',
    );
    this.sendExcel(res, buffer, 'onboarding-taxonomy-import-result.xlsx');
  }

  private sendExcel(res: Response, buffer: Buffer, filename: string) {
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.send(buffer);
  }
}
