import React from "react";

import {
  ImportJobStatus,
  ImportSourceType,
} from "../../types/interface/learningImport.interface";

const STATUS_STYLES: Record<ImportJobStatus, { label: string; className: string }> =
  {
    queued: { label: "Queued", className: "bg-gray-100 text-gray-700" },
    processing: { label: "Processing", className: "bg-blue-100 text-blue-700" },
    completed: {
      label: "Completed",
      className: "bg-emerald-100 text-emerald-700",
    },
    failed: { label: "Failed", className: "bg-rose-100 text-rose-700" },
    // Amber rather than red: the run died with the process (deploy, restart), it
    // did not reject the user's material and it cost them nothing.
    interrupted: { label: "Interrupted", className: "bg-amber-100 text-amber-800" },
  };

export function StatusBadge({ status }: { status: ImportJobStatus }) {
  const style = STATUS_STYLES[status] ?? {
    label: status,
    className: "bg-gray-100 text-gray-700",
  };

  return (
    <span
      className={`inline-block rounded-full px-2 py-0.5 text-xs font-semibold ${style.className}`}
    >
      {style.label}
    </span>
  );
}

export function SourceBadge({ type }: { type: ImportSourceType }) {
  return (
    <span className="inline-block rounded-full bg-slate-100 px-2 py-0.5 text-xs font-semibold uppercase text-slate-600">
      {type}
    </span>
  );
}

/**
 * What actually went wrong, in the words the user saw.
 *
 * The app renders its own localized sentence from the same code; showing the
 * matching English here is what lets a support reply and this screen agree about
 * what happened.
 */
export const ERROR_LABELS: Record<string, string> = {
  PDF_UNREADABLE: "PDF could not be read",
  PDF_TOO_LARGE: "PDF over the size / page limit",
  YOUTUBE_NO_TRANSCRIPT: "Video has no captions",
  YOUTUBE_UNAVAILABLE: "Video is private, deleted or blocked",
  YOUTUBE_TOO_LONG: "Video over the duration limit (3h)",
  YOUTUBE_TOO_SHORT: "Video under the 10-minute minimum",
  CONTENT_TOO_SHORT: "Source too thin to build a lesson",
  AI_TIMEOUT: "Model did not respond in time",
  AI_FAILED: "Model call failed",
  AI_NOT_CONFIGURED: "No API key configured on the server",
  SOURCE_FETCH_FAILED: "Could not fetch the source",
  INTERNAL: "Unexpected server error",
};

export function formatDateTime(value?: string | null): string {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";

  return date.toLocaleString();
}

export function formatVnd(amount?: number | null): string {
  if (amount === null || amount === undefined) return "—";

  return `${amount.toLocaleString("vi-VN")} ₫`;
}

export function formatDuration(seconds?: number | null): string {
  if (!seconds) return "—";
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);

  return hours > 0 ? `${hours}h ${minutes % 60}m` : `${minutes}m`;
}
