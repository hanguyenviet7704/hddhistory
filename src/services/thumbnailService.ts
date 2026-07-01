import axiosClient from "./axiosClient";

export type ThumbnailBackfillMode = "missing" | "all";

export interface ThumbnailBackfillStartResponse {
  started: boolean;
  alreadyRunning: boolean;
}

export interface ThumbnailBackfillStatus {
  running: boolean;
  mode: string | null;
  processed: number;
  created: number;
  skipped: number;
  failed: number;
  total: number;
  startedAt: string | null;
  finishedAt: string | null;
  lastError: string | null;
}

export const thumbnailService = {
  async startBackfill(
    mode: ThumbnailBackfillMode
  ): Promise<ThumbnailBackfillStartResponse> {
    const res = await axiosClient.post("/files/thumbnails/backfill", { mode });
    // API wraps every response as { statusCode, message, data }; the page reads
    // the payload fields directly, so unwrap here.
    return res.data.data;
  },

  async getBackfillStatus(): Promise<ThumbnailBackfillStatus> {
    const res = await axiosClient.get("/files/thumbnails/backfill/status");
    return res.data.data;
  },
};
