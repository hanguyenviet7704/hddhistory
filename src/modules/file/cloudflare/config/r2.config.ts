import { webcrypto } from 'crypto';

import {
  AbortMultipartUploadCommand,
  CompleteMultipartUploadCommand,
  CopyObjectCommand,
  CreateMultipartUploadCommand,
  S3Client,
  UploadPartCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { ConfigService } from '@nestjs/config';
import { AwsClient } from 'aws4fetch';

export interface R2Config {
  accountId: string;
  accessKeyId: string;
  secretAccessKey: string;
  bucketName: string;
  publicUrl?: string;
}

export class R2Service {
  private static readonly UPLOAD_TIMEOUT_MS = 120_000;
  private client: AwsClient;
  private config: R2Config;
  private s3Client: S3Client;

  constructor(config: R2Config, private readonly configService: ConfigService) {
    this.config = config;
    if (!globalThis.crypto) {
      globalThis.crypto = webcrypto as unknown as Crypto;
    }
    this.client = new AwsClient({
      accessKeyId: config.accessKeyId,
      secretAccessKey: config.secretAccessKey,
      region: 'auto',
      service: 's3',
    });
    this.s3Client = new S3Client({
      region: 'auto',
      endpoint: `https://${config.accountId}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: config.accessKeyId,
        secretAccessKey: config.secretAccessKey,
      },
      forcePathStyle: true,
    });
  }

  getEndpoint(path: string = ''): string {
    return `https://${this.config.accountId}.r2.cloudflarestorage.com/${this.config.bucketName}${path}`;
  }

  async uploadFile(
    key: string,
    file: Buffer | ArrayBuffer | ReadableStream,
    contentType: string,
    metadata?: Record<string, string>,
    options?: { cacheControl?: string; contentLength?: number },
  ) {
    const endpoint = this.getEndpoint(`/${key}`);

    const headers: Record<string, string> = {
      'Content-Type': contentType,
    };
    if (metadata) {
      for (const [metaKey, metaValue] of Object.entries(metadata)) {
        if (!metaValue) {
          continue;
        }
        headers[`x-amz-meta-${this.toMetadataKey(metaKey)}`] =
          this.toMetadataValue(metaValue);
      }
    }
    if (options?.cacheControl) {
      headers['Cache-Control'] = options.cacheControl;
    }
    if (options?.contentLength) {
      headers['Content-Length'] = options.contentLength.toString();
    }

    const body =
      file instanceof Buffer
        ? new Uint8Array(file)
        : file instanceof ArrayBuffer
        ? new Uint8Array(file)
        : file;

    const controller = new AbortController();
    const timeoutId = setTimeout(
      () => controller.abort(),
      R2Service.UPLOAD_TIMEOUT_MS,
    );

    let response: Response;
    try {
      response = await this.client.fetch(endpoint, {
        method: 'PUT',
        body: body as any,
        headers,
        signal: controller.signal,
      });
    } catch (error: any) {
      if (error?.name === 'AbortError') {
        throw new Error('Upload failed: request timed out');
      }
      throw error;
    } finally {
      clearTimeout(timeoutId);
    }
    if (!response.ok) {
      const errorBody = await response.text().catch(() => '');
      const compactError = errorBody.replace(/\s+/g, ' ').trim();
      throw new Error(
        `Upload failed: ${response.status} ${response.statusText}${
          compactError ? ` - ${compactError}` : ''
        }`,
      );
    }

    return {
      key,
      url: `${this.configService.get<string>('CLOUDFLARE_R2_CDN')}/${key}`,
    };
  }

  getPublicUrl(key: string): string {
    return `${this.configService.get<string>('CLOUDFLARE_R2_CDN')}/${key}`;
  }

  async deleteFile(key: string): Promise<void> {
    const endpoint = this.getEndpoint(`/${key}`);

    const response = await this.client.fetch(endpoint, {
      method: 'DELETE',
    });

    if (!response.ok && response.status !== 404) {
      throw new Error(`Delete failed: ${response.statusText}`);
    }
  }

  async getFileInfo(
    key: string,
  ): Promise<{ exists: boolean; size?: number; contentType?: string }> {
    const endpoint = this.getEndpoint(`/${key}`);

    const response = await this.client.fetch(endpoint, {
      method: 'HEAD',
    });

    const contentLength = response.headers.get('content-length');
    let size = contentLength ? parseInt(contentLength, 10) : undefined;

    if (response.ok && (!size || Number.isNaN(size))) {
      const rangeResponse = await this.client.fetch(endpoint, {
        method: 'GET',
        headers: { Range: 'bytes=0-0' },
      });

      if (rangeResponse.ok || rangeResponse.status === 206) {
        const contentRange = rangeResponse.headers.get('content-range');
        const match = contentRange?.match(/\/(\d+)$/);
        if (match) {
          size = parseInt(match[1], 10);
        } else {
          const buffer = await rangeResponse.arrayBuffer();
          size = buffer.byteLength;
        }
      }
    }

    return {
      exists: response.ok,
      size: response.ok ? size : undefined,
      contentType: response.ok
        ? response.headers.get('content-type') || undefined
        : undefined,
    };
  }

  async downloadFile(key: string): Promise<Response> {
    const endpoint = this.getEndpoint(`/${key}`);

    const response = await this.client.fetch(endpoint, {
      method: 'GET',
    });

    if (!response.ok) {
      throw new Error(`Download failed: ${response.statusText}`);
    }

    return response;
  }

  async listFiles(
    prefix?: string,
    limit?: number,
  ): Promise<{
    files: Array<{ key: string; size: number; lastModified: Date }>;
  }> {
    const endpoint = this.getEndpoint(
      `?list-type=2${prefix ? `&prefix=${prefix}` : ''}${
        limit ? `&max-keys=${limit}` : ''
      }`,
    );

    const response = await this.client.fetch(endpoint, {
      method: 'GET',
    });

    if (!response.ok) {
      throw new Error(`List failed: ${response.statusText}`);
    }

    const text = await response.text();
    // Parse XML response (in production, use an XML parser)
    const files: Array<{ key: string; size: number; lastModified: Date }> = [];

    // Simple regex parsing (consider using xml2js or similar in production)
    const keyMatches = text.match(/<Key>([^<]+)<\/Key>/g) || [];
    const sizeMatches = text.match(/<Size>([^<]+)<\/Size>/g) || [];
    const lastModifiedMatches =
      text.match(/<LastModified>([^<]+)<\/LastModified>/g) || [];

    for (let i = 0; i < keyMatches.length; i++) {
      const key = keyMatches[i].replace(/<Key>([^<]+)<\/Key>/, '$1');
      const size = parseInt(
        sizeMatches[i]?.replace(/<Size>([^<]+)<\/Size>/, '$1') || '0',
      );
      const lastModified = new Date(
        lastModifiedMatches[i]?.replace(
          /<LastModified>([^<]+)<\/LastModified>/,
          '$1',
        ) || '',
      );

      files.push({ key, size, lastModified });
    }

    return { files };
  }

  /**
   * Single-page ListObjectsV2, letting the caller drive pagination via the
   * returned continuation token. Used by batch/admin-triggered jobs (e.g.
   * image compression) that need to checkpoint progress between calls
   * instead of loading the whole bucket listing at once.
   */
  async listFilesPage(
    prefix?: string,
    maxKeys: number = 100,
    continuationToken?: string,
  ): Promise<{
    files: Array<{ key: string; size: number; lastModified: Date }>;
    nextContinuationToken?: string;
    isTruncated: boolean;
  }> {
    const endpoint = this.getEndpoint(
      `?list-type=2${prefix ? `&prefix=${encodeURIComponent(prefix)}` : ''}&max-keys=${maxKeys}${
        continuationToken
          ? `&continuation-token=${encodeURIComponent(continuationToken)}`
          : ''
      }`,
    );

    const response = await this.client.fetch(endpoint, { method: 'GET' });

    if (!response.ok) {
      throw new Error(`List failed: ${response.statusText}`);
    }

    const text = await response.text();
    const files: Array<{ key: string; size: number; lastModified: Date }> = [];

    const keyMatches = text.match(/<Key>([^<]+)<\/Key>/g) || [];
    const sizeMatches = text.match(/<Size>([^<]+)<\/Size>/g) || [];
    const lastModifiedMatches =
      text.match(/<LastModified>([^<]+)<\/LastModified>/g) || [];

    for (let i = 0; i < keyMatches.length; i++) {
      const key = keyMatches[i].replace(/<Key>([^<]+)<\/Key>/, '$1');
      const size = parseInt(
        sizeMatches[i]?.replace(/<Size>([^<]+)<\/Size>/, '$1') || '0',
      );
      const lastModified = new Date(
        lastModifiedMatches[i]?.replace(
          /<LastModified>([^<]+)<\/LastModified>/,
          '$1',
        ) || '',
      );

      files.push({ key, size, lastModified });
    }

    const isTruncated = /<IsTruncated>\s*true\s*<\/IsTruncated>/i.test(text);
    const tokenMatch = text.match(
      /<NextContinuationToken>([^<]+)<\/NextContinuationToken>/,
    );

    return {
      files,
      nextContinuationToken: isTruncated ? tokenMatch?.[1] : undefined,
      isTruncated,
    };
  }

  /** Server-side copy within the same bucket (used to snapshot an original before overwrite). */
  async copyObject(sourceKey: string, destinationKey: string): Promise<void> {
    const command = new CopyObjectCommand({
      Bucket: this.config.bucketName,
      CopySource: `${this.config.bucketName}/${encodeURIComponent(sourceKey)}`,
      Key: destinationKey,
    });
    await this.s3Client.send(command);
  }

  async createMultipartUpload(
    key: string,
    contentType: string,
    metadata?: Record<string, string>,
  ): Promise<{ key: string; uploadId: string }> {
    const command = new CreateMultipartUploadCommand({
      Bucket: this.config.bucketName,
      Key: key,
      ContentType: contentType,
      Metadata: metadata,
    });
    const response = await this.s3Client.send(command);
    if (!response.UploadId) {
      throw new Error('Create multipart upload failed');
    }

    return { key, uploadId: response.UploadId };
  }

  async getMultipartPartSignedUrl(
    key: string,
    uploadId: string,
    partNumber: number,
    expiresIn: number = 3600,
  ): Promise<string> {
    const command = new UploadPartCommand({
      Bucket: this.config.bucketName,
      Key: key,
      UploadId: uploadId,
      PartNumber: partNumber,
    });

    return await getSignedUrl(this.s3Client, command, { expiresIn });
  }

  async completeMultipartUpload(
    key: string,
    uploadId: string,
    parts: Array<{ ETag: string; PartNumber: number }>,
  ) {
    const command = new CompleteMultipartUploadCommand({
      Bucket: this.config.bucketName,
      Key: key,
      UploadId: uploadId,
      MultipartUpload: { Parts: parts },
    });

    return await this.s3Client.send(command);
  }

  async abortMultipartUpload(key: string, uploadId: string) {
    const command = new AbortMultipartUploadCommand({
      Bucket: this.config.bucketName,
      Key: key,
      UploadId: uploadId,
    });

    return await this.s3Client.send(command);
  }

  generateUniqueKey(originalName: string, prefix?: string): string {
    const timestamp = Date.now();
    const extension = originalName.split('.').pop();
    const nameWithoutExt = originalName.split('.').slice(0, -1).join('.');

    const key = `${nameWithoutExt}-${timestamp}.${extension}`;
    return prefix ? `${prefix}/${key}` : key;
  }

  private toMetadataKey(key: string): string {
    return key
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9_-]+/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  private toMetadataValue(value: string): string {
    // Keep metadata values ASCII-safe for HTTP headers.
    return encodeURIComponent(value.trim());
  }
}
