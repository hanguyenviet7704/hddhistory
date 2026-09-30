import { Injectable } from '@nestjs/common';

import { LoggerService } from '@base/logging/logger.service';

import { R2Service } from './config/r2.config';
import { CompressImagesDto } from './dto/compress-images.dto';

const IMAGE_EXTENSIONS = ['.png', '.jpg', '.jpeg', '.webp'];
const CONCURRENCY = 4;
const CACHE_CONTROL = 'public, max-age=31536000, immutable';

export interface CompressImageResult {
  key: string;
  originalBytes: number;
  newBytes?: number;
  savedBytes: number;
  action: 'compressed' | 'skipped-not-smaller' | 'skipped-type' | 'skipped-small' | 'error';
  error?: string;
}

export interface CompressImagesReport {
  apply: boolean;
  scanned: number;
  candidates: number;
  compressed: number;
  skipped: number;
  errors: number;
  bytesBefore: number;
  bytesAfter: number;
  bytesSaved: number;
  isTruncated: boolean;
  nextContinuationToken?: string;
  results: CompressImageResult[];
}

// Raster image mime types the on-upload path will auto-compress. Kept in sync
// with IMAGE_EXTENSIONS (png/jpg/jpeg/webp) — gif/svg/heic are deliberately
// excluded (animation / vector / codec sharp shouldn't silently re-encode).
export const COMPRESSIBLE_IMAGE_MIME_TYPES = new Set<string>([
  'image/png',
  'image/jpeg',
  'image/webp',
]);

// Defaults for the on-upload compression, mirroring the admin batch tool's
// defaults so a freshly uploaded image comes out identical to one the batch
// job would have produced.
const UPLOAD_MAX_EDGE = 1080;
const UPLOAD_QUALITY = 80;
const UPLOAD_MIN_BYTES = 20 * 1024;

@Injectable()
export class ImageCompressionService {
  constructor(
    private readonly r2Service: R2Service,
    private readonly logger: LoggerService,
  ) {}

  /**
   * Compresses a single in-memory image buffer for the upload path: same
   * transform as the batch tool (downscale to `maxEdge` + WebP at `quality`),
   * but with no R2 download/backup round-trip. Returns `null` when compression
   * shouldn't apply — below `minBytes`, sharp unavailable on this runtime, the
   * transform failed, or the result isn't actually smaller — so the caller
   * uploads the original bytes untouched instead of ever failing the upload.
   */
  async compressBufferForUpload(
    input: Buffer,
    opts?: { maxEdge?: number; quality?: number; minBytes?: number },
  ): Promise<{ buffer: Buffer; contentType: 'image/webp'; cacheControl: string } | null> {
    const maxEdge = opts?.maxEdge ?? UPLOAD_MAX_EDGE;
    const quality = opts?.quality ?? UPLOAD_QUALITY;
    const minBytes = opts?.minBytes ?? UPLOAD_MIN_BYTES;

    if (input.length < minBytes) return null;

    let sharpModule: typeof import('sharp');
    try {
      sharpModule = (await import('sharp')).default as unknown as typeof import('sharp');
    } catch (error: any) {
      this.logger.error(
        `sharp unavailable, uploading image without compression: ${error?.message}`,
        error?.stack,
        ImageCompressionService.name,
      );
      return null;
    }

    try {
      const output = await sharpModule(input)
        .rotate()
        .resize({
          width: maxEdge,
          height: maxEdge,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality })
        .toBuffer();

      if (output.length >= input.length) return null;

      return {
        buffer: output,
        contentType: 'image/webp',
        cacheControl: CACHE_CONTROL,
      };
    } catch (error: any) {
      this.logger.error(
        `Failed to compress uploaded image, using original: ${error?.message}`,
        error?.stack,
        ImageCompressionService.name,
      );
      return null;
    }
  }

  async compress(dto: CompressImagesDto): Promise<CompressImagesReport> {
    const prefix = dto.prefix ?? 'images/';
    const apply = dto.apply === true;
    const maxEdge = dto.maxEdge ?? 1080;
    const quality = dto.quality ?? 80;
    const minBytes = dto.minBytes ?? 20 * 1024;
    const batchSize = dto.batchSize ?? 100;
    const backupPrefix = (dto.backupPrefix ?? 'originals-backup').replace(/\/+$/, '');

    const page = await this.r2Service.listFilesPage(
      prefix,
      batchSize,
      dto.continuationToken,
    );

    const results: CompressImageResult[] = [];

    const candidates = page.files.filter(file => {
      if (file.key.startsWith(`${backupPrefix}/`)) return false;
      const ext = this.extname(file.key);
      if (!IMAGE_EXTENSIONS.includes(ext)) {
        results.push({
          key: file.key,
          originalBytes: file.size,
          savedBytes: 0,
          action: 'skipped-type',
        });
        return false;
      }
      if (file.size < minBytes) {
        results.push({
          key: file.key,
          originalBytes: file.size,
          savedBytes: 0,
          action: 'skipped-small',
        });
        return false;
      }
      return true;
    });

    let sharpModule: typeof import('sharp') | null = null;
    let sharpLoadError: string | null = null;
    if (candidates.length > 0) {
      try {
        sharpModule = (await import('sharp')).default as unknown as typeof import('sharp');
      } catch (error: any) {
        sharpLoadError = error?.message || 'unknown error loading sharp';
        this.logger.error(
          `sharp unavailable, skipping image compression batch: ${sharpLoadError}`,
          error?.stack,
          ImageCompressionService.name,
        );
      }
    }

    if (sharpLoadError) {
      for (const file of candidates) {
        results.push({
          key: file.key,
          originalBytes: file.size,
          savedBytes: 0,
          action: 'error',
          error: `sharp unavailable on this runtime: ${sharpLoadError}`,
        });
      }
    } else {
      for (let i = 0; i < candidates.length; i += CONCURRENCY) {
        const chunk = candidates.slice(i, i + CONCURRENCY);
        const chunkResults = await Promise.all(
          chunk.map(file =>
            this.compressOne(file, {
              apply,
              maxEdge,
              quality,
              backupPrefix,
              sharpModule: sharpModule!,
            }),
          ),
        );
        results.push(...chunkResults);
      }
    }

    const compressed = results.filter(r => r.action === 'compressed');
    const bytesBefore = results.reduce((sum, r) => sum + r.originalBytes, 0);
    const bytesAfter = results.reduce(
      (sum, r) => sum + (r.newBytes ?? r.originalBytes),
      0,
    );

    return {
      apply,
      scanned: page.files.length,
      candidates: candidates.length,
      compressed: compressed.length,
      skipped: results.length - compressed.length - results.filter(r => r.action === 'error').length,
      errors: results.filter(r => r.action === 'error').length,
      bytesBefore,
      bytesAfter,
      bytesSaved: bytesBefore - bytesAfter,
      isTruncated: page.isTruncated,
      nextContinuationToken: page.nextContinuationToken,
      results,
    };
  }

  private async compressOne(
    file: { key: string; size: number },
    opts: {
      apply: boolean;
      maxEdge: number;
      quality: number;
      backupPrefix: string;
      sharpModule: typeof import('sharp');
    },
  ): Promise<CompressImageResult> {
    try {
      const response = await this.r2Service.downloadFile(file.key);
      const arrayBuffer = await response.arrayBuffer();
      const originalBuffer = Buffer.from(arrayBuffer);

      const outputBuffer = await opts
        .sharpModule(originalBuffer)
        .rotate()
        .resize({
          width: opts.maxEdge,
          height: opts.maxEdge,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .webp({ quality: opts.quality })
        .toBuffer();

      if (outputBuffer.length >= originalBuffer.length) {
        return {
          key: file.key,
          originalBytes: originalBuffer.length,
          newBytes: originalBuffer.length,
          savedBytes: 0,
          action: 'skipped-not-smaller',
        };
      }

      if (opts.apply) {
        const backupKey = `${opts.backupPrefix}/${file.key}`;
        const backupInfo = await this.r2Service.getFileInfo(backupKey);
        if (!backupInfo.exists) {
          await this.r2Service.copyObject(file.key, backupKey);
        }

        await this.r2Service.uploadFile(file.key, outputBuffer, 'image/webp', undefined, {
          cacheControl: CACHE_CONTROL,
          contentLength: outputBuffer.length,
        });
      }

      return {
        key: file.key,
        originalBytes: originalBuffer.length,
        newBytes: outputBuffer.length,
        savedBytes: originalBuffer.length - outputBuffer.length,
        action: 'compressed',
      };
    } catch (error: any) {
      this.logger.error(
        `Failed to compress ${file.key}: ${error?.message}`,
        error?.stack,
        ImageCompressionService.name,
      );
      return {
        key: file.key,
        originalBytes: file.size,
        savedBytes: 0,
        action: 'error',
        error: error?.message || 'unknown error',
      };
    }
  }

  private extname(key: string): string {
    const match = key.toLowerCase().match(/\.[a-z0-9]+$/);
    return match ? match[0] : '';
  }
}
