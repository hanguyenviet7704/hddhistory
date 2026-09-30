import { createReadStream, promises as fsPromises } from 'fs';
import { Readable } from 'stream';

import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { LoggerService } from '@base/logging/logger.service';
import { RequestService } from '@base/service/request.service';

import { R2Service } from './config/r2.config';
import { UploadFileDto } from './dto/upload-file.dto';

@Injectable()
export class CloudflareService {
  static readonly MAX_FILE_SIZE = 500 * 1024 * 1024; // 500MB
  private readonly maxFileSizeDefault: number = CloudflareService.MAX_FILE_SIZE;
  private readonly allowedTypesDefault: string[] = [
    // 🖼 Ảnh
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/svg+xml',
    'image/heic',
    'image/heif',

    // 📄 Tài liệu
    'application/pdf',
    'text/plain',
    'application/msword', // .doc
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document', // .docx
    'application/vnd.ms-excel', // .xls
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // .xlsx
    'application/vnd.ms-powerpoint', // .ppt
    'application/vnd.openxmlformats-officedocument.presentationml.presentation', // .pptx

    // 🧩 JSON & Lottie
    'application/json',
    'application/vnd.lottie+json',
    'application/lottie+json',

    // 📦 Định dạng nén
    'application/zip',
    'application/x-zip-compressed',
    'application/x-rar-compressed',
    'application/x-7z-compressed',

    // 🎧 Âm thanh
    'audio/mpeg', // .mp3
    'audio/wav',
    'audio/webm',
    'audio/ogg',
    'audio/mp4',
    'audio/x-m4a',

    // 🎥 Video
    'video/mp4',
    'video/webm',
    'video/ogg',
    'video/quicktime', // .mov
  ];

  constructor(
    private readonly r2Service: R2Service,
    private readonly requestService: RequestService,
    private readonly logger: LoggerService,
    private readonly i18n: I18nService,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  private get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async uploadFile(
    file: Express.Multer.File,
    dto?: UploadFileDto,
  ): Promise<{ key: string; url: string }> {
    this.validateFile(file);
    const filename = this.resolveFilename(file.originalname, dto);

    try {
      const metadata = {
        originalName: file.originalname,
        mimeType: file.mimetype,
      };

      // Uploads are stored as-is (no automatic downscale/compression) so images
      // keep their original resolution — e.g. full-screen study-theme
      // backgrounds must stay sharp on high-DPI screens. Bulk optimization is
      // still available on demand via the admin `compress-images` batch tool.
      const uploadBody = file.buffer
        ? file.buffer
        : file.path
        ? this.toWebReadable(createReadStream(file.path))
        : null;
      if (!uploadBody) {
        throw new BadRequestException('upload body is not available');
      }

      const contentLength = file.size || file.buffer?.length;
      const result = await this.r2Service.uploadFile(
        filename,
        uploadBody,
        file.mimetype,
        metadata,
        { contentLength },
      );

      return result;
    } catch (error: any) {
      throw new BadRequestException(
        this.i18n.t(error.message, {
          lang: this.lang,
        }),
      );
    } finally {
      if (file.path) {
        await fsPromises.unlink(file.path).catch(() => undefined);
      }
    }
  }

  async uploadExternalFile(payload: {
    originalName: string;
    mimeType: string;
    body: Buffer | ArrayBuffer | ReadableStream | NodeJS.ReadableStream;
    size?: number;
    key?: string;
    prefix?: string;
    folder?: string;
    /**
     * `Cache-Control` to store on the object. Without one the CDN and every
     * client re-fetch the bytes on each play — the voiceover mp3s were served
     * with no caching directive at all (found 2026-08-04). Only pass a long
     * max-age for a URL that changes when its content does.
     */
    cacheControl?: string;
  }): Promise<{ key: string; url: string }> {
    this.validateFileMeta(payload.originalName, payload.mimeType);
    const filename = this.resolveFilename(payload.originalName, payload);

    try {
      const uploadBody =
        payload.body instanceof Buffer ||
        payload.body instanceof ArrayBuffer ||
        this.isWebReadable(payload.body)
          ? payload.body
          : this.toWebReadable(payload.body as NodeJS.ReadableStream);

      return await this.r2Service.uploadFile(
        filename,
        uploadBody,
        payload.mimeType,
        {
          originalName: payload.originalName,
          mimeType: payload.mimeType,
        },
        { contentLength: payload.size, cacheControl: payload.cacheControl },
      );
    } catch (error: any) {
      throw new BadRequestException(
        this.i18n.t(error.message, {
          lang: this.lang,
        }),
      );
    }
  }

  async uploadMultipleFiles(
    files: Express.Multer.File[],
  ): Promise<Array<{ key: string; url: string }>> {
    if (!files || files.length === 0) {
      throw new BadRequestException(
        this.i18n.t('error.FILE.NOT_FOUND', {
          lang: this.lang,
        }),
      );
    }

    const settled = await Promise.all(
      files.map(async file => {
        try {
          return await this.uploadFile(file);
        } catch (error: any) {
          this.logger.error(
            `Failed to upload file ${file.originalname}: ${error.message}`,
            error.stack,
            CloudflareService.name,
          );
          return null;
        }
      }),
    );

    const results = settled.filter(
      (result): result is { key: string; url: string } => result !== null,
    );

    if (results.length === 0) {
      throw new BadRequestException(
        this.i18n.t('error.FILE.UPLOAD_FAILED', {
          lang: this.lang,
        }),
      );
    }

    return results;
  }

  async deleteFile(key: string): Promise<void> {
    try {
      await this.r2Service.deleteFile(key);
    } catch (error: any) {
      throw new error();
    }
  }

  async downloadFile(key: string) {
    try {
      const fileInfo = await this.r2Service.getFileInfo(key);

      if (!fileInfo.exists) {
        throw new NotFoundException(
          this.i18n.t('error.FILE.NOT_FOUND', {
            lang: this.lang,
          }),
        );
      }

      const response = await this.r2Service.downloadFile(key);

      return {
        stream: response.body as ReadableStream,
        contentType: fileInfo.contentType || 'application/octet-stream',
        contentLength: fileInfo.size || 0,
        filename: key.split('/').pop() || key,
      };
    } catch (error: any) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw error;
    }
  }

  async getFileInfo(
    key: string,
  ): Promise<{ exists: boolean; size?: number; contentType?: string }> {
    try {
      return await this.r2Service.getFileInfo(key);
    } catch (error: any) {
      throw error;
    }
  }

  async listFiles(
    prefix?: string,
    limit?: number,
  ): Promise<{
    files: Array<{ key: string; size: number; lastModified: Date }>;
  }> {
    try {
      return await this.r2Service.listFiles(prefix, limit);
    } catch (error: any) {
      throw error;
    }
  }

  async checkRangeSupport(url: string): Promise<{
    url: string;
    status: number;
    supportsRange: boolean;
    acceptRanges?: string;
    contentRange?: string;
    contentLength?: string;
  }> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);

    try {
      const response = await fetch(url, {
        method: 'GET',
        headers: { Range: 'bytes=0-1' },
        signal: controller.signal,
      });

      const acceptRanges = response.headers.get('accept-ranges') || undefined;
      const contentRange = response.headers.get('content-range') || undefined;
      const contentLength = response.headers.get('content-length') || undefined;
      const supportsRange =
        response.status === 206 ||
        Boolean(contentRange) ||
        acceptRanges?.includes('bytes') === true;

      return {
        url,
        status: response.status,
        supportsRange,
        acceptRanges,
        contentRange,
        contentLength,
      };
    } catch (error: any) {
      if (error?.name === 'AbortError') {
        throw new BadRequestException('range check timed out');
      }
      throw new BadRequestException(error?.message || 'range check failed');
    } finally {
      clearTimeout(timeoutId);
    }
  }

  async initMultipartUpload(payload: {
    filename: string;
    contentType: string;
    key?: string;
    prefix?: string;
    folder?: string;
  }) {
    const filename = this.resolveFilename(payload.filename, payload);

    try {
      return await this.r2Service.createMultipartUpload(
        filename,
        payload.contentType,
        {
          originalName: payload.filename,
          mimeType: payload.contentType,
        },
      );
    } catch (error: any) {
      throw new BadRequestException(
        this.i18n.t(error.message, {
          lang: this.lang,
        }),
      );
    }
  }

  async getMultipartPartSignedUrl(payload: {
    key: string;
    uploadId: string;
    partNumber: number;
    expiresIn?: number;
  }) {
    try {
      const signedUrl = await this.r2Service.getMultipartPartSignedUrl(
        payload.key,
        payload.uploadId,
        payload.partNumber,
        payload.expiresIn,
      );
      return { key: payload.key, partNumber: payload.partNumber, signedUrl };
    } catch (error: any) {
      throw new BadRequestException(
        this.i18n.t(error.message, {
          lang: this.lang,
        }),
      );
    }
  }

  async completeMultipartUpload(payload: {
    key: string;
    uploadId: string;
    parts: Array<{ ETag: string; PartNumber: number }>;
  }) {
    try {
      await this.r2Service.completeMultipartUpload(
        payload.key,
        payload.uploadId,
        payload.parts,
      );
      return {
        key: payload.key,
        url: this.r2Service.getPublicUrl(payload.key),
      };
    } catch (error: any) {
      throw new BadRequestException(
        this.i18n.t(error.message, {
          lang: this.lang,
        }),
      );
    }
  }

  async abortMultipartUpload(payload: { key: string; uploadId: string }) {
    try {
      await this.r2Service.abortMultipartUpload(payload.key, payload.uploadId);
      return { key: payload.key, aborted: true };
    } catch (error: any) {
      throw new BadRequestException(
        this.i18n.t(error.message, {
          lang: this.lang,
        }),
      );
    }
  }

  private validateFile(file: Express.Multer.File): void {
    if (!file) {
      throw new BadRequestException(
        this.i18n.t('error.FILE.NO_FILE', {
          lang: this.lang,
        }),
      );
    }

    // Check file size
    const maxSize = this.maxFileSizeDefault;
    if (file.size > maxSize) {
      throw new BadRequestException(
        this.i18n.t('error.FILE.SIZE_EXCEEDED', {
          lang: this.lang,
          args: { maxSize: this.formatBytes(maxSize) },
        }),
      );
    }

    this.validateFileMeta(file.originalname, file.mimetype);
  }

  private formatBytes(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  private resolveFilename(
    originalName: string,
    payload?: { key?: string; prefix?: string; folder?: string },
  ): string {
    const { key, prefix, folder } = payload ?? {};
    if (key) {
      return this.sanitizeObjectKey(key);
    }

    let filename = this.sanitizeFileName(originalName);
    if (prefix) {
      filename = `${this.sanitizePathSegment(prefix)}-${filename}`;
    }
    if (folder) {
      filename = `${this.sanitizeObjectKey(folder)}/${filename}`;
    }

    return filename;
  }

  private sanitizeObjectKey(key: string): string {
    return key
      .split('/')
      .filter(Boolean)
      .map(part => this.sanitizePathSegment(part))
      .join('/');
  }

  private sanitizeFileName(originalName: string): string {
    const trimmed = originalName?.trim() || 'file';
    const lastDotIndex = trimmed.lastIndexOf('.');
    const hasExtension = lastDotIndex > 0 && lastDotIndex < trimmed.length - 1;

    if (!hasExtension) {
      return this.sanitizePathSegment(trimmed);
    }

    const base = trimmed.slice(0, lastDotIndex);
    const extension = trimmed.slice(lastDotIndex + 1);
    const safeBase = this.sanitizePathSegment(base);
    const safeExt = this.sanitizePathSegment(extension).toLowerCase();

    return safeExt ? `${safeBase}.${safeExt}` : safeBase;
  }

  private sanitizePathSegment(value: string): string {
    const normalized = value
      .normalize('NFKD')
      .replace(/[\u0300-\u036f]/g, '')
      // A SPACE is not in the kept set, deliberately: an object key keeps it
      // verbatim, and the URL that comes back is then rejected outright by
      // Firebase's own URL validator -- an image named `Pop up (1).png` cost a
      // whole notification campaign (0 sent, 2279 \u00d7 messaging/invalid-payload)
      // before this. Parentheses stay; they are legal in a URL path.
      .replace(/[^\w.()-]+/g, '-')
      .replace(/-+/g, '-')
      .replace(/^[-.]+|[-.]+$/g, '');

    return normalized || 'file';
  }

  private validateFileMeta(originalname: string, mimetype: string): void {
    const allowedTypes = this.allowedTypesDefault;
    const isLottieFile = originalname?.toLowerCase().endsWith('.lottie');
    const isAllowedMimeType =
      allowedTypes.length === 0 || allowedTypes.includes(mimetype);

    if (!isAllowedMimeType && !isLottieFile) {
      throw new BadRequestException(
        this.i18n.t('error.FILE.TYPE_NOT_ALLOWED', {
          lang: this.lang,
          args: { mimeType: mimetype },
        }),
      );
    }
  }

  private isWebReadable(
    value: unknown,
  ): value is ReadableStream<Uint8Array> {
    return (
      typeof value === 'object' &&
      value !== null &&
      typeof (value as ReadableStream<Uint8Array>).getReader === 'function'
    );
  }

  private toWebReadable(stream: NodeJS.ReadableStream): ReadableStream {
    const readable = Readable as unknown as {
      toWeb?: (nodeStream: NodeJS.ReadableStream) => ReadableStream;
    };
    if (typeof readable.toWeb === 'function') {
      return readable.toWeb(stream);
    }

    return new ReadableStream({
      start(controller) {
        stream.on('data', chunk => {
          controller.enqueue(
            chunk instanceof Uint8Array ? chunk : new Uint8Array(chunk),
          );
        });
        stream.on('end', () => controller.close());
        stream.on('error', error => controller.error(error));
      },
      cancel() {
        if (
          typeof (stream as NodeJS.ReadableStream & { destroy?: () => void })
            .destroy === 'function'
        ) {
          (
            stream as NodeJS.ReadableStream & { destroy?: () => void }
          ).destroy();
        }
      },
    });
  }
}
