import React, { useEffect, useState } from "react";
import { ExclamationTriangleIcon } from "@heroicons/react/24/outline";

interface ConfirmDialogProps {
  open: boolean;
  title: string;
  message: React.ReactNode;
  confirmLabel?: string;
  cancelLabel?: string;
  tone?: "default" | "danger";
  /** If set, the confirm button stays disabled until the operator types this exact string. */
  requireTypedConfirmation?: string;
  loading?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

const ConfirmDialog: React.FC<ConfirmDialogProps> = ({
  open,
  title,
  message,
  confirmLabel = "Xác nhận",
  cancelLabel = "Hủy",
  tone = "default",
  requireTypedConfirmation,
  loading = false,
  onConfirm,
  onCancel,
}) => {
  const [typed, setTyped] = useState("");

  useEffect(() => {
    if (open) setTyped("");
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onCancel();
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  if (!open) return null;

  const typedOk = !requireTypedConfirmation || typed === requireTypedConfirmation;
  const isDanger = tone === "danger";

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-3"
      onClick={onCancel}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-md bg-white rounded-2xl shadow-2xl border border-slate-100 p-6 space-y-4"
      >
        <div className="flex items-start gap-3">
          <div
            className={`h-10 w-10 flex-shrink-0 rounded-full flex items-center justify-center ${
              isDanger ? "bg-red-100 text-red-600" : "bg-amber-100 text-amber-600"
            }`}
          >
            <ExclamationTriangleIcon className="h-6 w-6" />
          </div>
          <div className="space-y-1">
            <p className="font-semibold text-slate-900">{title}</p>
            <div className="text-sm text-slate-600">{message}</div>
          </div>
        </div>

        {requireTypedConfirmation && (
          <label className="flex flex-col gap-1 text-sm text-slate-700">
            <span>
              Nhập <span className="font-mono font-semibold">{requireTypedConfirmation}</span>{" "}
              để xác nhận
            </span>
            <input
              autoFocus
              value={typed}
              onChange={(e) => setTyped(e.target.value)}
              className="rounded-lg border border-slate-300 px-3 py-2 font-mono focus:ring-2 focus:ring-red-500 focus:border-red-500"
              placeholder={requireTypedConfirmation}
            />
          </label>
        )}

        <div className="flex justify-end gap-2 pt-1">
          <button
            type="button"
            onClick={onCancel}
            disabled={loading}
            className="px-4 py-2 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 disabled:opacity-70 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-500 focus-visible:ring-offset-2"
          >
            {cancelLabel}
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={loading || !typedOk}
            className={`px-4 py-2 rounded-lg text-white shadow-md disabled:opacity-50 flex items-center gap-2 min-w-[120px] justify-center focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 ${
              isDanger
                ? "bg-red-600 hover:bg-red-700 focus-visible:ring-red-500"
                : "bg-gradient-to-r from-teal-600 to-emerald-500 hover:from-teal-700 hover:to-emerald-600 focus-visible:ring-teal-500"
            }`}
          >
            {loading && (
              <span className="h-4 w-4 border-2 border-white/60 border-t-transparent rounded-full animate-spin" />
            )}
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ConfirmDialog;
