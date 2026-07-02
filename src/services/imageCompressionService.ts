import axiosClient from "./axiosClient";

export interface CompressImagesParams {
  prefix?: string;
  apply?: boolean;
  maxEdge?: number;
  quality?: number;
  minBytes?: number;
  batchSize?: number;
  continuationToken?: string;
  backupPrefix?: string;
}

export type CompressImageAction =
  | "compressed"
  | "skipped-not-smaller"
  | "skipped-type"
  | "skipped-small"
  | "error";

export interface CompressImageResult {
  key: string;
  originalBytes: number;
  newBytes?: number;
  savedBytes: number;
  action: CompressImageAction;
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

export const imageCompressionService = {
  // Processes one page of images (server-driven page size via batchSize).
  // Callers loop this, threading nextContinuationToken back in, until
  // isTruncated is false.
  async compressBatch(
    params: CompressImagesParams
  ): Promise<CompressImagesReport> {
    const res = await axiosClient.post("/cloudflares/compress-images", params);
    return res.data.data;
  },
};
