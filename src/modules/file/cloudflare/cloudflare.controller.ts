import { mkdirSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import { PassThrough } from 'stream';

import {
  Body,
  Controller,
  Post,
  Get,
  Delete,
  Param,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  UploadedFiles,
  Res,
  Query,
} from '@nestjs/common';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { Response } from 'express';
import { diskStorage } from 'multer';

import { Public } from '@base/decorator/public';
import { AuthGuard } from '@base/guard/auth.guard';

import { CloudflareService } from './cloudflare.service';
import { AbortMultipartUploadDto } from './dto/abort-multipart-upload.dto';
import { CompleteMultipartUploadDto } from './dto/complete-multipart-upload.dto';
import { CompressImagesDto } from './dto/compress-images.dto';
import { InitMultipartUploadDto } from './dto/init-multipart-upload.dto';
import { GetListFileDto } from './dto/list-file.dto';
import { PresignMultipartPartDto } from './dto/presign-multipart-part.dto';
import { RangeCheckDto } from './dto/range-check.dto';
import { UploadFileDto } from './dto/upload-file.dto';
import { ImageCompressionService } from './image-compression.service';

const UPLOAD_DIR = join(tmpdir(), 'hddhistory-uploads');
mkdirSync(UPLOAD_DIR, { recursive: true });

const uploadStorage = diskStorage({
  destination: (_req, _file, cb) => cb(null, UPLOAD_DIR),
  filename: (_req, file, cb) => {
    const safeName = file.originalname.replace(/\s+/g, '-');
    cb(
      null,
      `${Date.now()}-${Math.random().toString(16).slice(2)}-${safeName}`,
    );
  },
});

@ApiTags('FILES-CLOUDFLARE')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'cloudflares', version: '1' })
export class CloudflareController {
  constructor(
    private readonly cloudflareService: CloudflareService,
    private readonly imageCompressionService: ImageCompressionService,
  ) {}

  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: uploadStorage,
      limits: { fileSize: CloudflareService.MAX_FILE_SIZE },
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
        key: {
          type: 'string',
          description: 'File key for organizing files',
        },
        prefix: {
          type: 'string',
          description: 'File prefix for organizing files',
        },
        folder: {
          type: 'string',
          description: 'File folder for organizing files',
        },
      },
    },
  })
  async uploadFile(
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: UploadFileDto,
  ) {
    return await this.cloudflareService.uploadFile(file, dto);
  }

  @Post('upload-multiple')
  @UseInterceptors(
    FilesInterceptor('files', 10, {
      storage: uploadStorage,
      limits: { fileSize: CloudflareService.MAX_FILE_SIZE },
    }),
  ) // Max 10 files
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        files: {
          type: 'array',
          items: {
            type: 'string',
            format: 'binary',
          },
        },
        prefix: {
          type: 'string',
          description: 'File prefix for organizing files',
        },
        folder: {
          type: 'string',
          description: 'File folder for organizing files',
        },
      },
    },
  })
  async uploadMultipleFiles(@UploadedFiles() files: Express.Multer.File[]) {
    const results = await this.cloudflareService.uploadMultipleFiles(files);

    return results.map(result => ({
      key: result.key,
      url: result.url,
    }));
  }

  @Post('multipart/init')
  async initMultipartUpload(@Body() dto: InitMultipartUploadDto) {
    return await this.cloudflareService.initMultipartUpload(dto);
  }

  @Get('multipart/presign')
  async presignMultipartPart(@Query() dto: PresignMultipartPartDto) {
    return await this.cloudflareService.getMultipartPartSignedUrl(dto);
  }

  @Post('multipart/complete')
  async completeMultipartUpload(@Body() dto: CompleteMultipartUploadDto) {
    return await this.cloudflareService.completeMultipartUpload(dto);
  }

  @Post('multipart/abort')
  async abortMultipartUpload(@Body() dto: AbortMultipartUploadDto) {
    return await this.cloudflareService.abortMultipartUpload(dto);
  }

  @Public()
  @Get('download/:key')
  async downloadFile(@Param('key') key: string, @Res() res: Response) {
    const { stream, contentType, contentLength, filename } =
      await this.cloudflareService.downloadFile(key);

    // Set MIME headers
    res.set({
      'Content-Type': contentType || 'application/octet-stream',
      'Content-Length': contentLength?.toString() || undefined,
      // 👇 Dùng "inline" để preview trực tiếp
      'Content-Disposition': `inline; filename="${filename}"`,
    });

    // Convert Web ReadableStream -> Node Readable
    const reader = stream.getReader();
    const passThrough = new PassThrough();

    async function pump() {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        // Honor backpressure: if the internal buffer is full (write()
        // returns false), wait for 'drain' before reading more from R2 —
        // otherwise a slow client lets buffered chunks pile up in memory.
        const canContinue = passThrough.write(Buffer.from(value));
        if (!canContinue) {
          await new Promise<void>(resolve =>
            passThrough.once('drain', resolve),
          );
        }
      }
      passThrough.end();
    }

    pump();

    // Pipe stream trực tiếp tới response
    passThrough.pipe(res);
  }

  @Get('info/:key(*)')
  async getFileInfo(@Param('key') key: string) {
    return await this.cloudflareService.getFileInfo(key);
  }

  @Get('')
  async listFiles(@Query() query: GetListFileDto) {
    const { page, take, ...options } = query;

    // Get files from R2
    const { files } = await this.cloudflareService.listFiles(
      options.prefix,
      take + 1,
    );

    // Apply pagination
    const hasNextPage = files.length > take;
    const paginatedFiles = hasNextPage ? files.slice(0, -1) : files;

    return {
      items: paginatedFiles,
      pagination: {
        page,
        total: files.length,
        hasNextPage,
        hasPrevPage: page > 1,
      },
    };
  }

  /**
   * Processes one page of images under `prefix` (size driven by `batchSize`).
   * Admin UI loops this call, passing back `nextContinuationToken`, until
   * `isTruncated` is false. Defaults to a dry-run (`apply: false`) so the
   * savings can be previewed before any object is overwritten.
   */
  @Post('compress-images')
  async compressImages(@Body() dto: CompressImagesDto) {
    return await this.imageCompressionService.compress(dto);
  }

  @Get('range-check')
  async checkRange(@Query() query: RangeCheckDto) {
    return await this.cloudflareService.checkRangeSupport(query.url);
  }

  @Delete(':key(*)')
  async deleteFile(@Param('key') key: string) {
    await this.cloudflareService.deleteFile(key);
    return { message: 'File deleted successfully' };
  }
}
