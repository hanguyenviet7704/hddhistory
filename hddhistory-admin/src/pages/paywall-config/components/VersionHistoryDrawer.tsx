import React, { useEffect } from "react";
import {
  ArrowUturnLeftIcon,
  CheckCircleIcon,
  ClockIcon,
  ExclamationTriangleIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";
import { PaywallConfigVersion } from "../../../types/interface/paywall-config.interface";
import { formatDateTime } from "../paywallConfigFormat";

interface VersionHistoryDrawerProps {
  open: boolean;
  versions: PaywallConfigVersion[] | null;
  loading: boolean;
  error: string | null;
  /** Version currently mid-restore (disables every row's action, spins its own). */
  restoringVersion: number | null;
  onRetry: () => void;
  onRestore: (entry: PaywallConfigVersion) => void;
  onClose: () => void;
}

// Replaces the free version history the Firebase Remote Config console used
// to give the admin -- MySQL is append-only (see PaywallConfigService) so
// every past publish is still here; this is the only place to see or act on
// that history now.
const VersionHistoryDrawer: React.FC<VersionHistoryDrawerProps> = ({
  open,
  versions,
  loading,
  error,
  restoringVersion,
  onRetry,
  onRestore,
  onClose,
}) => {
  useEffect(() => {
    if (!open) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-40 flex justify-end bg-black/40" onClick={onClose}>
      <div
        role="dialog"
        aria-modal="true"
        aria-label="Lịch sử phiên bản"
        onClick={(e) => e.stopPropagation()}
        className="h-full w-full max-w-md bg-white shadow-2xl border-l border-slate-100 flex flex-col"
      >
        <div className="flex items-start justify-between gap-3 p-4 border-b border-slate-100 bg-slate-50/60">
          <div className="flex items-center gap-2.5">
            <div className="h-10 w-10 flex-shrink-0 rounded-xl bg-teal-50 text-teal-700 flex items-center justify-center">
              <ClockIcon className="h-5 w-5" />
            </div>
            <div>
              <p className="text-sm font-semibold text-slate-900">Lịch sử phiên bản</p>
              <p className="text-xs text-slate-500">
                Tất cả phiên bản đã đăng, mới nhất trước. Khôi phục sẽ đăng lại
                làm phiên bản mới.
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Đóng lịch sử phiên bản"
            className="h-9 w-9 flex-shrink-0 flex items-center justify-center rounded-lg text-slate-500 hover:bg-slate-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-500 focus-visible:ring-offset-1"
          >
            <XMarkIcon className="h-5 w-5" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-4 space-y-2">
          {loading ? (
            Array.from({ length: 5 }).map((_, i) => (
              <div
                key={i}
                className="h-16 rounded-xl border border-slate-100 bg-slate-100 animate-pulse"
              />
            ))
          ) : error ? (
            <div className="rounded-xl border border-slate-100 bg-white p-6 text-center space-y-3">
              <ExclamationTriangleIcon className="h-7 w-7 text-red-500 mx-auto" />
              <p className="text-sm text-red-700">{error}</p>
              <button
                type="button"
                onClick={onRetry}
                className="px-4 py-2 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 text-sm"
              >
                Thử lại
              </button>
            </div>
          ) : !versions || versions.length === 0 ? (
            <div className="rounded-xl border border-slate-100 bg-white p-6 text-center">
              <p className="text-sm text-slate-600">Chưa có phiên bản nào được đăng.</p>
            </div>
          ) : (
            versions.map((entry) => {
              const isRestoringThis = restoringVersion === entry.version;
              const restoreDisabled = entry.isCurrent || restoringVersion !== null;
              return (
                <div
                  key={entry.version}
                  className={`rounded-xl border p-3 flex items-start justify-between gap-3 ${
                    entry.isCurrent
                      ? "border-teal-200 bg-teal-50/50"
                      : "border-slate-100 bg-white"
                  }`}
                >
                  <div className="min-w-0 space-y-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-sm font-semibold text-slate-800">
                        Phiên bản {entry.version}
                      </span>
                      {entry.isCurrent && (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-teal-600 text-white text-[11px] font-medium">
                          <CheckCircleIcon className="h-3.5 w-3.5" />
                          Hiện tại
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-slate-500">
                      {formatDateTime(entry.publishedAt)}
                    </p>
                    <p className="text-xs text-slate-500 truncate">
                      Bởi {entry.publishedBy || "Không rõ"}
                    </p>
                  </div>

                  <button
                    type="button"
                    onClick={() => onRestore(entry)}
                    disabled={restoreDisabled}
                    title={entry.isCurrent ? "Đây là phiên bản đang chạy" : "Khôi phục phiên bản này"}
                    className="flex-shrink-0 inline-flex items-center gap-1.5 px-3 py-2 rounded-lg border border-slate-200 text-slate-700 text-xs font-medium hover:bg-slate-50 disabled:opacity-50 disabled:hover:bg-transparent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-500 focus-visible:ring-offset-1"
                  >
                    {isRestoringThis ? (
                      <span className="h-3.5 w-3.5 border-2 border-slate-400/60 border-t-transparent rounded-full animate-spin" />
                    ) : (
                      <ArrowUturnLeftIcon className="h-3.5 w-3.5" />
                    )}
                    Khôi phục
                  </button>
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
};

export default VersionHistoryDrawer;
