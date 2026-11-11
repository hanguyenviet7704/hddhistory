import { Injectable, Logger } from '@nestjs/common';

import { R2Service } from 'src/modules/file/cloudflare/config/r2.config';

import { ResolvedSource } from '../ai/lesson-generation.types';
import { ImportErrorCode } from '../enum/learning-import.enum';
import { LEARNING_IMPORT_CONFIG } from '../learning-import.config';
import { SourceResolutionError } from './source-resolution.error';

@Injectable()
export class PdfSourceResolver {
  private readonly logger = new Logger(PdfSourceResolver.name);

  constructor(private readonly r2Service: R2Service) {}

  /**
   * Fetch the user's PDF from R2 and hand it over as bytes.
   *
   * No text extraction: the model reads the document itself, which is what lets
   * scanned pages, tables and multi-column layouts survive. That also removes a
   * PDF-parsing dependency and, with it, the class of import that fails because
   * a library disagreed with a producer about the spec.
   */
  async resolve(fileKey: string, fileName: string): Promise<ResolvedSource> {
    let bytes: Buffer;

    try {
      const response = await this.r2Service.downloadFile(fileKey);
      bytes = Buffer.from(await response.arrayBuffer());
    } catch (error: any) {
      this.logger.error(
        `Could not download PDF ${fileKey}: ${error?.message}`,
        error?.stack,
      );
      throw new SourceResolutionError(
        ImportErrorCode.SOURCE_FETCH_FAILED,
        'Could not read the uploaded file',
      );
    }

    if (bytes.length === 0) {
      throw new SourceResolutionError(
        ImportErrorCode.PDF_UNREADABLE,
        'The uploaded file is empty',
      );
    }

    if (bytes.length > LEARNING_IMPORT_CONFIG.maxPdfBytes) {
      throw new SourceResolutionError(
        ImportErrorCode.PDF_TOO_LARGE,
        `File is larger than the ${Math.round(
          LEARNING_IMPORT_CONFIG.maxPdfBytes / (1024 * 1024),
        )}MB limit`,
      );
    }

    if (!this.looksLikePdf(bytes)) {
      throw new SourceResolutionError(
        ImportErrorCode.PDF_UNREADABLE,
        'The uploaded file is not a PDF',
      );
    }

    const pageCount = this.countPages(bytes);
    if (pageCount !== null && pageCount > LEARNING_IMPORT_CONFIG.maxPdfPages) {
      throw new SourceResolutionError(
        ImportErrorCode.PDF_TOO_LARGE,
        `Document has ${pageCount} pages, over the ${LEARNING_IMPORT_CONFIG.maxPdfPages}-page limit`,
      );
    }

    return { kind: 'pdfBytes', bytes, fileName };
  }

  // Every PDF starts with `%PDF-`. Cheaper and more honest than trusting the
  // upload's declared MIME type, which the client chooses.
  private looksLikePdf(bytes: Buffer): boolean {
    return bytes.subarray(0, 5).toString('latin1') === '%PDF-';
  }

  /**
   * Page count from the file's own structure, or `null` when it cannot be read.
   *
   * Reads the `/Type /Pages` node's `/Count`, which is metadata sitting in the
   * object table -- no rendering, no text extraction, effectively free. It is
   * also genuinely optional: PDFs that keep their objects inside compressed
   * object streams (1.5+) hide this from a byte scan, and some producers write a
   * `/Count` that disagrees with reality.
   *
   * `null` therefore means "unknown", and the caller must treat that as "allow"
   * and lean on the byte cap instead. Rejecting an unreadable count would block
   * users over a header quirk they cannot see, to enforce a limit the size cap
   * already approximates.
   */
  countPages(bytes: Buffer): number | null {
    // Only the head and tail: the page tree root lives near one end or the
    // other, and scanning 20MB of image data for it would cost more than the
    // check is worth.
    const window = 512 * 1024;
    const haystack =
      bytes.length <= window * 2
        ? bytes.toString('latin1')
        : bytes.subarray(0, window).toString('latin1') +
          bytes.subarray(bytes.length - window).toString('latin1');

    const counts: number[] = [];
    const pagesNode = /\/Type\s*\/Pages\b/g;

    let match: RegExpExecArray | null;
    while ((match = pagesNode.exec(haystack)) !== null) {
      // `/Count` can sit on either side of `/Type /Pages` within the same
      // dictionary, so look at a window around the match rather than after it.
      const from = Math.max(0, match.index - 200);
      const nearby = haystack.slice(from, match.index + 200);
      const count = /\/Count\s+(\d+)/.exec(nearby);
      if (count) counts.push(Number(count[1]));
    }

    if (counts.length === 0) return null;

    // Page trees nest, and every intermediate node carries its own subtree
    // count. The root's is the largest, so the page total is the maximum.
    return Math.max(...counts);
  }
}
