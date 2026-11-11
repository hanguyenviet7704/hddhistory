import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Types } from 'mongoose';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';
import {
  getTranslationValue,
  hasAnyTranslationValue,
} from '@utils/translate';
import { OrderType } from '@utils/type/orderByType';

import {
  assertNoImportErrors,
  createTemplateWorkbook,
  getRows,
  getSheet,
  hasTranslationValueForPrefix,
  ImportValidationError,
  numberValue,
  readWorkbook,
  resolveAssetUrl,
  setCellByHeader,
  text,
  translationCells,
  translationColumnLabel,
  translationFromValues,
  translationHeaders,
  validateNoDuplicateValues,
  workbookToBuffer,
} from '../import/excel-import.util';
import { CreateKeypointDto } from './dto/create-keypoint.dto';
import { GetListKeypointDto } from './dto/get-list-keypoint.dto';
import { UpdateKeypointDto } from './dto/update-keypoint.dto';
import { KeypointRepository } from './repository/keypoint.repository';
import { Keypoint } from './schema/keypoint.schema';
import { learningItemBrief } from '../course-version/content-projection';
import { ContentSource } from '../course-version/content-source.service';
import { LearningItemRepository } from '../learning-item/repository/learning-item.repository';

@Injectable()
export class KeypointService {
  constructor(
    private readonly keypointRepository: KeypointRepository,
    private readonly learningItemRepository: LearningItemRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
    private readonly configService: ConfigService,
    private readonly contentSource: ContentSource,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async create(createKeypointDto: CreateKeypointDto): Promise<Keypoint> {
    const { title } = createKeypointDto;
    const titleByLang = getTranslationValue(title, this.lang);

    if (!titleByLang && !hasAnyTranslationValue(title)) {
      throw new BadRequestException('title is required');
    }

    if (titleByLang) {
      // check title exits
      const titleExits = await this.keypointRepository.checkExitsTitle(
        titleByLang,
        this.lang,
      );
      if (titleExits)
        throw new ConflictException(
          this.i18n.t('error.COURSE_KEYPOINT.TITLE_EXISTS', {
            lang: this.lang,
          }),
        );
    }

    const keypoint = await this.keypointRepository.create(
      {
        ...createKeypointDto,
      },
      this.user,
    );

    return keypoint;
  }

  async findAll(getListKeypointDto: GetListKeypointDto) {
    const result = await this.keypointRepository.findOption(getListKeypointDto);

    return result;
  }

  /**
   * `versionId` null = bản đang sửa, đúng y như trước khi có phiên bản nội
   * dung. Khác null = đọc tag đang phát hành của khoá chứa keypoint này.
   * Xem `plans/260907-course-content-versions/README.md`.
   */
  async findOne(id: string, requested?: string | null): Promise<Keypoint> {
    const versionId = await this.contentSource.versionForKeypoint(
      id,
      this.requestService.headers,
      requested,
      this.user?.id,
    );

    const keypoint = versionId
      ? ((await this.contentSource.getKeypoint(
          id,
          versionId,
        )) as unknown as Keypoint | null)
      : await this.keypointRepository.findOne({
          _id: id,
        });

    if (!keypoint)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_KEYPOINT.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    // lấy danh sách theory, exercise
    if (versionId) {
      const items = await this.contentSource.getLearningItemsByKeypointIds(
        [id],
        versionId,
      );
      // Cùng projection và cùng thứ tự như `findAllBrief`, để khoá có tag trả
      // đúng shape như khoá chưa tag.
      keypoint.learningItems = items
        .map(learningItemBrief)
        .sort((a, b) => Number(a.index ?? 0) - Number(b.index ?? 0));
    } else {
      const learningItems = await this.learningItemRepository.findAllBrief(
        keypoint._id.toString(),
        OrderType.ASC,
        'index',
      );
      keypoint.learningItems = learningItems.list;
    }

    return keypoint;
  }

  async update(id: string, updateKeypointDto: UpdateKeypointDto) {
    const { title } = updateKeypointDto;
    const keypoint = await this.keypointRepository.findOne({ _id: id });
    if (!keypoint)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_KEYPOINT.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    if (title) {
      const titleByLang = getTranslationValue(title, this.lang);
      const mergedTitle = { ...(keypoint.title ?? {}), ...title };

      if (!titleByLang && !hasAnyTranslationValue(mergedTitle)) {
        throw new BadRequestException('title is required');
      }

      if (titleByLang) {
        // check title exit
        const titleExits = await this.keypointRepository.checkExitsTitle(
          titleByLang,
          this.lang,
        );
        if (titleExits && titleExits._id.toString() !== id)
          throw new ConflictException(
            this.i18n.t('error.COURSE_KEYPOINT.TITLE_EXISTS', {
              lang: this.lang,
            }),
          );
      }
    }

    const update = await this.keypointRepository.updateOne(
      { _id: id },
      {
        ...updateKeypointDto,
      },
      this.user,
    );

    return update;
  }

  async remove(id: string) {
    const keypoint = await this.keypointRepository.findOne({ _id: id });
    if (!keypoint)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_KEYPOINT.NOT_FOUND', {
          lang: this.lang,
        }),
      );
    const res = await this.keypointRepository.deleteOne({ _id: id });
    return res;
  }

  async exportKeypoints() {
    const sheet = await this.buildKeypointExportSheet();
    return createTemplateWorkbook(
      sheet.sheetName,
      sheet.headers,
      sheet.sampleRows,
    );
  }

  /** `preloaded` exports a content tag rather than the working tree. */
  async buildKeypointExportSheet(keypointIds?: string[], preloaded?: any[]) {
    const keypoints =
      preloaded ??
      (await this.keypointRepository.findAllForExport(keypointIds));
    const rows = keypoints.map(keypoint => [
      keypoint._id.toString(),
      '',
      ...translationCells(keypoint.title),
      ...translationCells(keypoint.description),
      ...translationCells(keypoint.audio?.url),
      ...translationCells(keypoint.estimateCompleTime),
      keypoint.estimateCompleTimeNumber ?? '',
      keypoint.image ?? '',
      keypoint.index ?? '',
    ]);

    return {
      sheetName: 'keypoints',
      headers: [
        'id',
        'keypoint_key',
        ...translationHeaders('title'),
        ...translationHeaders('description'),
        ...translationHeaders('audio_url'),
        ...translationHeaders('estimate_complete_time'),
        'estimate_complete_time_number',
        'image',
        'index',
      ],
      sampleRows: rows,
    };
  }

  async importKeypoints(file: Express.Multer.File) {
    const workbook = await readWorkbook(file);
    const sheet = getSheet(workbook, ['keypoints'], true);
    const rows = getRows(sheet);
    const errors: ImportValidationError[] = [];
    validateNoDuplicateValues('keypoints', rows, errors);

    for (const row of rows) {
      const id = text(row.values.id);
      if (!id) {
        if (!hasTranslationValueForPrefix(row.values, 'title')) {
          errors.push({
            sheet: 'keypoints',
            row: row.rowNumber,
            column: translationColumnLabel('title'),
            message:
              'At least one supported title translation is required when creating',
          });
        }
        continue;
      }

      if (!Types.ObjectId.isValid(id)) {
        errors.push({
          sheet: 'keypoints',
          row: row.rowNumber,
          column: 'id',
          message: 'id is not a valid ObjectId',
        });
        continue;
      }

      const existing = await this.keypointRepository.findOne({ _id: id });
      if (!existing) {
        errors.push({
          sheet: 'keypoints',
          row: row.rowNumber,
          column: 'id',
          message: 'keypoint was not found',
        });
      }
    }

    assertNoImportErrors(errors);

    for (const row of rows) {
      const id = text(row.values.id);
      const payload = this.buildKeypointImportPayload(row.values, !id);

      if (id) {
        if (Object.keys(payload).length) {
          await this.keypointRepository.updateOne(
            { _id: id },
            payload,
            this.user,
          );
        }
        continue;
      }

      const created = await this.keypointRepository.create(
        payload as any,
        this.user,
      );
      setCellByHeader(sheet, row.rowNumber, 'id', created._id.toString());
    }

    return workbookToBuffer(workbook);
  }

  private buildKeypointImportPayload(
    values: Record<string, any>,
    isCreate: boolean,
  ) {
    const cdn = this.configService.get<string>('CLOUDFLARE_R2_CDN');
    const payload: Record<string, any> = {};
    const title = translationFromValues(values, 'title');
    const description = translationFromValues(values, 'description');
    const audioUrl = translationFromValues(values, 'audio_url', value =>
      resolveAssetUrl(value, cdn),
    );
    const estimateCompleTime = translationFromValues(
      values,
      'estimate_complete_time',
    );
    const estimateCompleTimeNumber = numberValue(
      values.estimate_complete_time_number,
    );
    const image = resolveAssetUrl(values.image, cdn);
    const index = numberValue(values.index);

    if (isCreate) {
      if (title) payload.title = title;
      if (description) payload.description = description;
      if (audioUrl) payload.audio = { url: audioUrl };
      if (estimateCompleTime) payload.estimateCompleTime = estimateCompleTime;
    } else {
      this.assignTranslationUpdate(payload, 'title', title);
      this.assignTranslationUpdate(payload, 'description', description);
      this.assignTranslationUpdate(payload, 'audio.url', audioUrl);
      this.assignTranslationUpdate(
        payload,
        'estimateCompleTime',
        estimateCompleTime,
      );
    }
    if (estimateCompleTimeNumber !== undefined) {
      payload.estimateCompleTimeNumber = estimateCompleTimeNumber;
    }
    if (image) payload.image = image;
    if (index !== undefined) payload.index = index;

    return payload;
  }

  private assignTranslationUpdate(
    payload: Record<string, any>,
    path: string,
    value?: Record<string, string>,
  ) {
    if (!value) return;
    for (const [lang, textValue] of Object.entries(value)) {
      payload[`${path}.${lang}`] = textValue;
    }
  }
}
