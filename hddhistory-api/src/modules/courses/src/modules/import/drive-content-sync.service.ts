import * as path from 'path';
import { Readable } from 'stream';

import {
  BadRequestException,
  HttpException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { google } from 'googleapis';

import {
  CourseContentImportStats,
  CourseContentTransferService,
} from './course-content-transfer.service';
import { getRows, getSheet, readWorkbook, text } from './excel-import.util';
import { CourseRepository } from '../course/repository/course.repository';

const XLSX_MIME =
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
const GOOGLE_SHEET_MIME = 'application/vnd.google-apps.spreadsheet';
const TEMPLATE_NAME = '_TEMPLATE';

export interface DriveCourseSyncResult {
  fileId: string;
  fileName: string;
  courseId?: string;
  /** created = khoá mới được tạo từ sheet; updated = khoá có sẵn được cập
   *  nhật; noop = sheet không có nội dung import; failed = có lỗi. */
  action: 'created' | 'updated' | 'noop' | 'failed';
  /**
   * Tag published for this course by `autoTag`, or null when the option was
   * off. A sync writes the WORKING TREE, so on a tagged course nothing reaches
   * the app until a tag exists -- this is how the caller can tell.
   * See `plans/260907-course-content-versions/README.md`.
   */
  autoTaggedAs?: string | null;
  stats?: CourseContentImportStats;
  errorCount: number;
  errors: Array<{
    sheet: string;
    row: number;
    column?: string;
    message: string;
  }>;
}

/**
 * Mirrors course content to a Google Drive folder: one Google Sheet per
 * course (identified by the `meupCourseId` appProperty). Sync pulls each
 * sheet back through the full course-content import, then writes the result
 * (created ids, or an `import_errors` tab) back onto the same sheet, so the
 * Drive file always stays the working copy.
 *
 * Requires GOOGLE_DRIVE_CONTENT_FOLDER_ID and a google-service.json service
 * account with access to that folder. The folder MUST live in a Shared Drive
 * (SA added as Content manager): service accounts have zero My-Drive storage
 * quota since 2025, so files.create into a personal folder always fails with
 * "storage quota has been exceeded".
 */
@Injectable()
export class DriveContentSyncService {
  private readonly logger = new Logger(DriveContentSyncService.name);

  constructor(
    private readonly transferService: CourseContentTransferService,
    private readonly courseRepository: CourseRepository,
    private readonly configService: ConfigService,
  ) {}

  private folderId() {
    const folderId = this.configService.get<string>(
      'GOOGLE_DRIVE_CONTENT_FOLDER_ID',
    );
    if (!folderId) {
      throw new BadRequestException(
        'GOOGLE_DRIVE_CONTENT_FOLDER_ID is not configured',
      );
    }
    return folderId;
  }

  private drive() {
    // Two ways around the zero My-Drive quota of service accounts:
    // a Shared Drive folder, or GOOGLE_DRIVE_IMPERSONATE_SUBJECT — a real
    // Workspace user the SA impersonates (requires domain-wide delegation),
    // which makes that user the owner of every file the sync creates.
    const subject = this.configService.get<string>(
      'GOOGLE_DRIVE_IMPERSONATE_SUBJECT',
    );
    const auth = new google.auth.GoogleAuth({
      keyFile: path.join(process.cwd(), 'google-service.json'),
      scopes: ['https://www.googleapis.com/auth/drive'],
      ...(subject ? { clientOptions: { subject } } : {}),
    });
    return google.drive({ version: 'v3', auth });
  }

  /**
   * Google/gaxios failures otherwise surface as an opaque 500 — unwrap the
   * real Drive error message for the admin toast and the log.
   */
  private async withDriveErrors<T>(operation: () => Promise<T>): Promise<T> {
    try {
      return await operation();
    } catch (error: any) {
      if (error instanceof HttpException) throw error;
      const message = this.describeDriveError(error);
      // `error?.stack` thêm vào ĐÂY vì trước đó chỉ log `message` — một lỗi
      // JS thô ném ra trước khi kịp gọi Drive (như vụ "toString" 2026-09-10)
      // không có `response.data` để soi, và không có stack thì log không nói
      // được throw ở dòng nào.
      this.logger.error(
        `Drive API error: ${message} | detail: ${JSON.stringify(
          error?.response?.data ?? {},
        ).slice(0, 1000)} | stack: ${error?.stack ?? '(none)'}`,
      );
      throw new BadRequestException(message);
    }
  }

  /**
   * `versionId` đẩy nội dung của một TAG vào sheet thay vì bản đang sửa — để
   * xem lại hoặc khôi phục một bản cũ ngay trên Drive. Sheet `_VERSION` sẽ
   * ghi rõ đây là bản đóng băng nào và nó có khác bản đang phát hành không.
   */
  async pushCourseToDrive(courseId: string, versionId: string | null = null) {
    return this.withDriveErrors(() =>
      this.doPushCourseToDrive(courseId, versionId),
    );
  }

  private async doPushCourseToDrive(
    courseId: string,
    versionId: string | null = null,
  ) {
    const folderId = this.folderId();
    const drive = this.drive();
    const { file: existing, fileName } = await this.courseFileOnDrive(
      drive,
      folderId,
      courseId,
    );

    if (!existing) {
      throw new BadRequestException(
        `Chưa có sheet cho khoá này trên Drive. Hãy tạo một Google Sheet trống tên "${fileName}" trong folder rồi bấm lại.`,
      );
    }

    const buffer = await this.transferService.exportCourseFull(
      courseId,
      versionId,
    );

    // HAI lệnh riêng, KHÔNG gộp requestBody + media vào một `files.update`.
    //
    // googleapis-common rẽ nhánh theo việc `resource` (requestBody) có mặt
    // hay không: chỉ `media` đi đường đơn giản (`options.data = media.body`,
    // gaxios nhận thẳng luồng); có thêm `resource` thì đổi sang
    // `uploadType: 'multipart'`, tự dựng boundary rồi pipe qua một
    // `PassThrough` thủ công (`apirequest.js` — `multipartUpload`). Hai lệnh
    // update còn lại trong file này (`ensureTemplateOnDrive`, `writeBack` của
    // `syncFromDrive`) chỉ truyền `media` và chưa từng lỗi; lệnh DUY NHẤT gộp
    // cả hai — chính lệnh này — là lệnh production báo
    // "Cannot read properties of undefined (reading 'toString')". Tách ra để
    // đi đúng đường đã chạy sạch ở hai chỗ kia, thay vì đoán chính xác dòng
    // nào trong thư viện ném lỗi.
    await drive.files.update({
      fileId: existing.id as string,
      requestBody: {
        name: fileName,
        appProperties: { meupCourseId: courseId },
      },
      supportsAllDrives: true,
    });
    const updated = await drive.files.update({
      fileId: existing.id as string,
      media: { mimeType: XLSX_MIME, body: Readable.from(buffer) },
      fields: 'id, webViewLink',
      supportsAllDrives: true,
    });
    return { fileId: updated.data.id, webViewLink: updated.data.webViewLink };
  }

  async ensureTemplateOnDrive() {
    return this.withDriveErrors(() => this.doEnsureTemplateOnDrive());
  }

  private async doEnsureTemplateOnDrive() {
    const folderId = this.folderId();
    const drive = this.drive();
    const listed = await drive.files.list({
      q: `'${folderId}' in parents and name = '${TEMPLATE_NAME}' and trashed = false`,
      fields: 'files(id, webViewLink)',
      pageSize: 1,
      supportsAllDrives: true,
      includeItemsFromAllDrives: true,
    });
    const found = listed.data.files?.[0];
    if (!found) {
      throw new BadRequestException(
        `Chưa có sheet "${TEMPLATE_NAME}" trên Drive. Hãy tạo một Google Sheet trống tên "${TEMPLATE_NAME}" trong folder rồi gọi lại — hệ thống sẽ tự đổ nội dung mẫu vào.`,
      );
    }

    // Fill (or refresh) the hand-made blank sheet with the template content.
    const buffer = await this.transferService.buildFullTemplate();
    const updated = await drive.files.update({
      fileId: found.id as string,
      media: { mimeType: XLSX_MIME, body: Readable.from(buffer) },
      fields: 'id, webViewLink',
      supportsAllDrives: true,
    });
    return { fileId: updated.data.id, webViewLink: updated.data.webViewLink };
  }

  /**
   * Pull every course sheet in the folder (or just `fileId`) through the full
   * import, then write the result workbook back onto the sheet.
   */
  async syncFromDrive(
    fileId?: string,
    opts: { autoTag?: boolean } = {},
  ): Promise<DriveCourseSyncResult[]> {
    return this.withDriveErrors(() => this.doSyncFromDrive(fileId, opts));
  }

  /**
   * Kéo về ĐÚNG MỘT khoá thay vì quét cả folder.
   *
   * Đi qua nguyên luồng của `syncFromDrive` (kể cả cái bẫy bắt lỗi từng file)
   * chứ không dựng đường riêng — kéo một khoá và kéo cả folder phải cho ra
   * cùng một kết quả, nếu tách đôi thì sớm muộn hai bên lệch nhau.
   */
  async pullCourseFromDrive(
    courseId: string,
    opts: { autoTag?: boolean } = {},
  ): Promise<DriveCourseSyncResult> {
    return this.withDriveErrors(() =>
      this.doPullCourseFromDrive(courseId, opts),
    );
  }

  private async doPullCourseFromDrive(
    courseId: string,
    opts: { autoTag?: boolean } = {},
  ): Promise<DriveCourseSyncResult> {
    const folderId = this.folderId();
    const drive = this.drive();
    const { file, fileName } = await this.courseFileOnDrive(
      drive,
      folderId,
      courseId,
    );

    if (!file?.id) {
      throw new BadRequestException(
        `Chưa có sheet cho khoá "${fileName}" trên Drive nên không có gì để kéo về. Bấm đẩy lên Drive trước.`,
      );
    }

    const [result] = await this.doSyncFromDrive(file.id, opts);
    return result;
  }

  private async doSyncFromDrive(
    fileId?: string,
    opts: { autoTag?: boolean } = {},
  ): Promise<DriveCourseSyncResult[]> {
    const folderId = this.folderId();
    const drive = this.drive();

    let files: Array<{ id?: string | null; name?: string | null }>;
    if (fileId) {
      const file = await drive.files.get({
        fileId,
        fields: 'id, name',
        supportsAllDrives: true,
      });
      files = [file.data];
    } else {
      const listed = await drive.files.list({
        q: `'${folderId}' in parents and mimeType = '${GOOGLE_SHEET_MIME}' and name != '${TEMPLATE_NAME}' and trashed = false`,
        fields: 'files(id, name)',
        pageSize: 200,
        supportsAllDrives: true,
        includeItemsFromAllDrives: true,
      });
      files = listed.data.files ?? [];
    }

    const results: DriveCourseSyncResult[] = [];
    for (const file of files) {
      if (!file.id) continue;
      try {
        results.push(await this.syncOneFile(drive, file, opts));
      } catch (error: any) {
        // One broken sheet must not abort the rest of the folder.
        const message = this.describeDriveError(error);
        this.logger.error(`Drive sync "${file.name}" FAILED: ${message}`);
        results.push({
          fileId: file.id,
          fileName: file.name ?? file.id,
          action: 'failed',
          errorCount: 1,
          errors: [{ sheet: 'drive', row: 0, message }],
        });
      }
    }

    return results;
  }

  private async syncOneFile(
    drive: ReturnType<DriveContentSyncService['drive']>,
    file: { id?: string | null; name?: string | null },
    opts: { autoTag?: boolean } = {},
  ): Promise<DriveCourseSyncResult> {
    const exported = await drive.files.export(
      { fileId: file.id as string, mimeType: XLSX_MIME },
      { responseType: 'arraybuffer' },
    );
    const buffer = Buffer.from(exported.data as ArrayBuffer);

    const result = await this.transferService.importCourseContent(
      {
        buffer,
        originalname: `${file.name ?? file.id}.xlsx`,
        mimetype: XLSX_MIME,
        size: buffer.length,
      } as Express.Multer.File,
      // Unattended, so no actor: the tag records `createdBy: null`, which the
      // admin version table reads as a system tag.
      { autoTag: opts.autoTag },
    );

    // Google's xlsx→Sheets converter can 500 ("Internal Error") on workbooks
    // exceljs re-serialized from a Drive export. On success we upload a
    // freshly built export instead (same ids, canonical form); only the
    // error case falls back to the round-tripped workbook so the
    // import_errors tab reaches the PO.
    const importedCourseId = await this.firstCourseId(result.buffer);
    let writeBack = result.buffer;
    if (!result.errors.length && importedCourseId) {
      // Ghi lại SAU khi autoTag đã chạy, nên `_VERSION` trong sheet đọc ra
      // tag mới; truyền thêm tag vừa đánh để sheet nói thẳng "lần sync vừa
      // rồi đã phát hành thành v1.0.4" thay vì để người sửa tự suy ra.
      writeBack = await this.transferService.exportCourseFull(
        importedCourseId,
        null,
        result.autoTagged?.find(t => t.courseId === importedCourseId)?.tag ??
          null,
      );
    }

    await drive.files.update({
      fileId: file.id as string,
      media: { mimeType: XLSX_MIME, body: Readable.from(writeBack) },
      supportsAllDrives: true,
    });

    // Stamp the sheet with its course id so later pushes/syncs match it
    // even after renames (new-course sheets start unclaimed).
    if (importedCourseId) {
      await drive.files.update({
        fileId: file.id as string,
        requestBody: { appProperties: { meupCourseId: importedCourseId } },
        supportsAllDrives: true,
      });
    }

    const action = this.resolveAction(result.errors.length, result.stats);
    this.logger.log(
      `Drive sync "${file.name}": ${action.toUpperCase()}${
        importedCourseId ? ` course ${importedCourseId}` : ''
      } — ${this.describeStats(result.stats)} — ${
        result.errors.length
      } error(s)`,
    );
    return {
      fileId: file.id as string,
      fileName: file.name ?? file.id ?? '',
      courseId: importedCourseId,
      action,
      stats: result.stats,
      errorCount: result.errors.length,
      errors: result.errors,
      autoTaggedAs:
        result.autoTagged?.find(t => t.courseId === importedCourseId)?.tag ??
        null,
    };
  }

  private resolveAction(
    errorCount: number,
    stats: CourseContentImportStats,
  ): DriveCourseSyncResult['action'] {
    if (errorCount) return 'failed';
    if (stats.courses.created > 0) return 'created';
    const touched = Object.values(stats).some(
      entity => entity.created > 0 || entity.updated > 0,
    );
    return touched ? 'updated' : 'noop';
  }

  private describeStats(stats: CourseContentImportStats) {
    return (Object.keys(stats) as Array<keyof CourseContentImportStats>)
      .map(name => `${name} +${stats[name].created}/~${stats[name].updated}`)
      .join(', ');
  }

  private describeDriveError(error: any) {
    const googleMessage =
      error?.response?.data?.error?.message ||
      error?.errors?.[0]?.message ||
      error?.message ||
      'Unknown Google Drive error';
    const call = error?.config?.url
      ? ` [${error?.config?.method ?? ''} ${error.config.url}]`
      : '';
    return `Google Drive: ${googleMessage}${call}`;
  }

  /**
   * Sheet của một khoá: ưu tiên file đã gắn `meupCourseId`, sau đó tới file
   * người ta tự tạo tay trùng tên khoá (service account không tự tạo file
   * được — không có quota My Drive — nên PO tạo sheet trống, sync chỉ đổ vào).
   *
   * Trả về cả `fileName` để chỗ gọi báo đúng tên cần tìm khi không thấy gì.
   */
  private async courseFileOnDrive(
    drive: ReturnType<DriveContentSyncService['drive']>,
    folderId: string,
    courseId: string,
  ) {
    const course = await this.courseRepository.findOne({ _id: courseId });
    const title = (course?.title ?? {}) as Record<string, string>;
    const fileName = title.vi || title.en || `course-${courseId}`;

    const file =
      (await this.findCourseFile(drive, folderId, courseId)) ??
      (await this.findFileByNames(drive, folderId, [
        fileName,
        title.vi,
        title.en,
        courseId,
      ]));

    return { file, fileName };
  }

  private async findCourseFile(
    drive: ReturnType<DriveContentSyncService['drive']>,
    folderId: string,
    courseId: string,
  ) {
    const listed = await drive.files.list({
      q: `'${folderId}' in parents and appProperties has { key = 'meupCourseId' and value = '${courseId}' } and trashed = false`,
      fields: 'files(id, name)',
      pageSize: 1,
      supportsAllDrives: true,
      includeItemsFromAllDrives: true,
    });
    return listed.data.files?.[0];
  }

  private async findFileByNames(
    drive: ReturnType<DriveContentSyncService['drive']>,
    folderId: string,
    names: Array<string | undefined>,
  ) {
    const candidates = [
      ...new Set(names.map(name => (name ?? '').trim()).filter(Boolean)),
    ];
    for (const name of candidates) {
      const listed = await drive.files.list({
        q: `'${folderId}' in parents and mimeType = '${GOOGLE_SHEET_MIME}' and name = '${name.replace(
          /'/g,
          "\\'",
        )}' and trashed = false`,
        fields: 'files(id, name)',
        pageSize: 1,
        supportsAllDrives: true,
        includeItemsFromAllDrives: true,
      });
      const found = listed.data.files?.[0];
      if (found) return found;
    }
    return undefined;
  }

  private async firstCourseId(buffer: Buffer) {
    try {
      const workbook = await readWorkbook({ buffer } as Express.Multer.File);
      const rows = getRows(getSheet(workbook, ['courses']));
      for (const row of rows) {
        const id = text(row.values.id);
        if (id) return id;
      }
    } catch {
      // result buffers are always workbooks; a parse failure just means no stamp
    }
    return undefined;
  }
}
