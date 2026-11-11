import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';

import { RequestService } from '@base/service/request.service';

import { CloudflareService } from '../cloudflare.service';
import { CreateDriveImportDto } from './dto/create-drive-import.dto';
import { DriveImportJobStatus } from './enum/drive-import-job-status.enum';
import {
  IDriveImportFailedFile,
  IDriveImportUploadedItem,
} from './interface/drive-import-job.interface';
import { DriveImportJobRepository } from './repository/drive-import-job.repository';
import { extractDriveFolderId } from './utils/drive-folder-url.util';

const MEDIA_FOLDERS = ['images', 'videos', 'audios'] as const;
const DRIVE_ORIGIN = 'https://drive.google.com';

interface DriveImportFile {
  id: string;
  name: string;
  mimeType: string;
  size?: number;
  path: string;
  folder: string;
}

interface PublicDriveLink {
  id: string;
  name: string;
  type: 'folder' | 'file';
}

@Injectable()
export class DriveImportService {
  private readonly logger = new Logger(DriveImportService.name);

  constructor(
    private readonly driveImportJobRepository: DriveImportJobRepository,
    private readonly cloudflareService: CloudflareService,
    private readonly requestService: RequestService,
  ) {}

  async create(dto: CreateDriveImportDto) {
    const createdBy = this.getCurrentUserId();
    const activeJob = await this.driveImportJobRepository.findActiveByUser(
      createdBy,
    );

    if (activeJob) {
      return activeJob;
    }

    const job = await this.driveImportJobRepository.create({
      createdBy,
      folderUrl: dto.folderUrl,
      status: DriveImportJobStatus.QUEUED,
      totalFiles: 0,
      uploadedFiles: 0,
      failedCount: 0,
      percent: 0,
      uploadedItems: [],
      failedFiles: [],
    } as any);

    setImmediate(() => {
      this.processJob(String(job._id)).catch(error => {
        this.logger.error(
          `Drive import job ${job._id} failed: ${error.message}`,
          error.stack,
        );
      });
    });

    return job;
  }

  async findAll() {
    return await this.driveImportJobRepository.findByUser(
      this.getCurrentUserId(),
    );
  }

  async findOne(jobId: string) {
    const job = await this.driveImportJobRepository.findOwnedJob(
      jobId,
      this.getCurrentUserId(),
    );
    if (!job) {
      throw new NotFoundException('Drive import job was not found');
    }

    return job;
  }

  async cancel(jobId: string) {
    const job = await this.driveImportJobRepository.markCancelled(
      jobId,
      this.getCurrentUserId(),
    );
    if (!job) {
      throw new NotFoundException('Active drive import job was not found');
    }

    return job;
  }

  private async processJob(jobId: string) {
    const job = await this.driveImportJobRepository.updateJob(jobId, {
      status: DriveImportJobStatus.PROCESSING,
      startedAt: new Date(),
      lastError: null,
    });

    if (!job) {
      return;
    }

    try {
      const rootFolderId = extractDriveFolderId(job.folderUrl);
      const files = await this.collectDriveFiles(rootFolderId);

      await this.driveImportJobRepository.updateJob(jobId, {
        totalFiles: files.length,
        percent: files.length === 0 ? 100 : 0,
      });

      const uploadedItems: IDriveImportUploadedItem[] = [];
      const failedFiles: IDriveImportFailedFile[] = [];

      for (const file of files) {
        const latestJob = await this.driveImportJobRepository.findById(jobId);
        if (latestJob?.status === DriveImportJobStatus.CANCELLED) {
          return;
        }

        try {
          const download = await this.downloadDriveFile(file.id);
          const result = await this.cloudflareService.uploadExternalFile({
            originalName: file.name,
            mimeType: this.resolveDownloadMimeType(download.mimeType, file),
            body: download.body,
            size: download.size || file.size,
            folder: file.folder,
          });

          uploadedItems.push({
            path: file.path,
            url: result.url,
            uploadedAt: new Date(),
          });
        } catch (error: any) {
          failedFiles.push({
            path: file.path,
            message: error?.message || 'Upload failed',
            failedAt: new Date(),
          });
        }

        await this.updateProgress(
          jobId,
          files.length,
          uploadedItems,
          failedFiles,
        );
      }

      await this.driveImportJobRepository.updateJob(jobId, {
        status:
          failedFiles.length > 0
            ? DriveImportJobStatus.COMPLETED_WITH_ERRORS
            : DriveImportJobStatus.COMPLETED,
        completedAt: new Date(),
      });
    } catch (error: any) {
      await this.driveImportJobRepository.updateJob(jobId, {
        status: DriveImportJobStatus.FAILED,
        lastError: error?.message || 'Drive import failed',
        completedAt: new Date(),
      });
    }
  }

  private async collectDriveFiles(
    rootFolderId: string,
  ): Promise<DriveImportFile[]> {
    const childFolders = await this.listPublicFolderLinks(rootFolderId);
    const files: DriveImportFile[] = [];

    for (const folderName of MEDIA_FOLDERS) {
      const folder = childFolders.find(
        item => item.type === 'folder' && item.name === folderName,
      );
      if (!folder?.id) {
        continue;
      }

      const folderFiles = await this.listPublicFolderLinks(folder.id);
      files.push(
        ...folderFiles
          .filter(file => file.type === 'file')
          .map(file => ({
          id: file.id,
          name: file.name,
          mimeType: this.inferMimeType(file.name),
          path: `${folderName}/${file.name}`,
          folder: folderName,
        })),
      );
    }

    return files;
  }

  private async listPublicFolderLinks(
    folderId: string,
  ): Promise<PublicDriveLink[]> {
    const url = `${DRIVE_ORIGIN}/embeddedfolderview?id=${folderId}`;
    const response = await fetch(url);

    if (!response.ok) {
      throw new BadRequestException(
        `Unable to read public Drive folder: ${response.status}`,
      );
    }

    const html = await response.text();
    return this.parseEmbeddedFolderLinks(html);
  }

  private parseEmbeddedFolderLinks(html: string): PublicDriveLink[] {
    const links = new Map<string, PublicDriveLink>();
    const anchorRegex =
      /<a\s+[^>]*href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/gi;
    let match: RegExpExecArray | null;

    while ((match = anchorRegex.exec(html)) !== null) {
      const href = this.decodeHtml(match[1]);
      const name = this.cleanAnchorText(match[2]);
      const item = this.parseDriveLink(href, name);

      if (item) {
        links.set(`${item.type}:${item.id}`, item);
      }
    }

    return Array.from(links.values());
  }

  private parseDriveLink(href: string, name: string): PublicDriveLink | null {
    if (!name) {
      return null;
    }

    let url: URL;
    try {
      url = new URL(href, DRIVE_ORIGIN);
    } catch {
      return null;
    }

    const folderMatch = url.pathname.match(/\/folders\/([a-zA-Z0-9_-]+)/);
    if (folderMatch?.[1]) {
      return { id: folderMatch[1], name, type: 'folder' };
    }

    const fileMatch = url.pathname.match(/\/file\/d\/([a-zA-Z0-9_-]+)/);
    const fileId = fileMatch?.[1] || url.searchParams.get('id');
    if (fileId) {
      return { id: fileId, name, type: 'file' };
    }

    return null;
  }

  private async downloadDriveFile(fileId: string): Promise<{
    body: ReadableStream;
    mimeType?: string;
    size?: number;
  }> {
    const response = await fetch(
      `${DRIVE_ORIGIN}/uc?export=download&id=${fileId}`,
    );

    if (!response.ok || !response.body) {
      throw new BadRequestException(
        `Unable to download public Drive file: ${response.status}`,
      );
    }

    const contentType = response.headers.get('content-type') || undefined;
    const contentLength = response.headers.get('content-length');

    return {
      body: response.body,
      mimeType: contentType?.split(';')[0],
      size: contentLength ? Number(contentLength) : undefined,
    };
  }

  private async updateProgress(
    jobId: string,
    totalFiles: number,
    uploadedItems: IDriveImportUploadedItem[],
    failedFiles: IDriveImportFailedFile[],
  ) {
    const processedFiles = uploadedItems.length + failedFiles.length;
    const percent =
      totalFiles === 0 ? 100 : Math.round((processedFiles / totalFiles) * 100);

    await this.driveImportJobRepository.updateJob(jobId, {
      uploadedFiles: uploadedItems.length,
      failedCount: failedFiles.length,
      uploadedItems,
      failedFiles,
      percent,
    });
  }

  private getCurrentUserId() {
    const userId = this.requestService.user?.id;
    if (!userId) {
      throw new BadRequestException('Current user is not available');
    }

    return userId;
  }

  private cleanAnchorText(value: string): string {
    return this.decodeHtml(value.replace(/<[^>]+>/g, ''))
      .replace(/\s+/g, ' ')
      .trim();
  }

  private decodeHtml(value: string): string {
    return value
      .replace(/&amp;/g, '&')
      .replace(/&quot;/g, '"')
      .replace(/&#39;/g, "'")
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>');
  }

  private inferMimeType(filename: string): string {
    const extension = filename.split('.').pop()?.toLowerCase();
    const mimeTypes: Record<string, string> = {
      jpg: 'image/jpeg',
      jpeg: 'image/jpeg',
      png: 'image/png',
      gif: 'image/gif',
      webp: 'image/webp',
      svg: 'image/svg+xml',
      heic: 'image/heic',
      heif: 'image/heif',
      mp4: 'video/mp4',
      webm: 'video/webm',
      ogg: 'video/ogg',
      mov: 'video/quicktime',
      mp3: 'audio/mpeg',
      wav: 'audio/wav',
      m4a: 'audio/x-m4a',
      pdf: 'application/pdf',
      txt: 'text/plain',
      json: 'application/json',
      lottie: 'application/vnd.lottie+json',
      zip: 'application/zip',
    };

    return extension
      ? mimeTypes[extension] || 'application/octet-stream'
      : 'application/octet-stream';
  }

  private resolveDownloadMimeType(
    responseMimeType: string | undefined,
    file: DriveImportFile,
  ) {
    if (
      responseMimeType &&
      responseMimeType !== 'application/octet-stream' &&
      responseMimeType !== 'text/html'
    ) {
      return responseMimeType;
    }

    return file.mimeType;
  }
}
