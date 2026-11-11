import React, { useCallback, useEffect, useRef, useState } from "react";
import { Button, MenuItem, TextField } from "@mui/material";
import { PlayCircleIcon } from "@heroicons/react/24/outline";

import { cloudflareService } from "../../services/cloudflareR2Service";
import { learningImportService } from "../../services/learningImportService";
import {
  ImportQuota,
  ImportSourceType,
} from "../../types/interface/learningImport.interface";
import { useNotification } from "../../utils/hooks/useNotification";

// The five the app ships and the API accepts.
const LOCALES = [
  { code: "vi", label: "Tiếng Việt" },
  { code: "en", label: "English" },
  { code: "zh", label: "中文" },
  { code: "ja", label: "日本語" },
  { code: "ko", label: "한국어" },
];

/** Rejections the create endpoint returns before a job exists. */
const GATE_MESSAGES: Record<string, string> = {
  NOT_PREMIUM:
    "Tài khoản đang đăng nhập chưa phải Premium. Panel này chạy import THẬT với đúng các cổng chặn của app, nên cần một tài khoản Premium — đăng nhập bằng tài khoản test đã mua gói.",
  QUOTA_EXCEEDED: "Tài khoản này đã dùng hết lượt tạo bài trong tháng.",
  JOB_ALREADY_RUNNING:
    "Tài khoản này đang có một bài được tạo dở. Đợi nó xong rồi chạy tiếp.",
  AI_NOT_CONFIGURED:
    "Server chưa có khoá Gemini (GEMINI_API_KEY). Import sẽ bị từ chối cho tới khi khoá được nạp.",
};

/**
 * Runs one import from the admin, without opening the app.
 *
 * Calls the SAME `POST /learning-imports` the app calls, as the signed-in admin,
 * with the premium and quota gates intact. Bypassing them was the obvious
 * shortcut and was rejected twice over: a harness that skips the checks tests a
 * different system than the one users run, and this repo has no working role
 * guard (`@Roles(ADMIN)` is wired nowhere — see the docblock on
 * `analytics.controller.ts`), so a gate-free endpoint would be reachable by any
 * authenticated caller and would put unmetered Gemini spend behind a URL.
 */
export default function RunImportPanel({
  onStarted,
}: {
  /** Lets the list refresh itself the moment a job appears. */
  onStarted: () => void;
}) {
  const { showSuccess, showError } = useNotification();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [sourceType, setSourceType] = useState<ImportSourceType>("youtube");
  const [url, setUrl] = useState("");
  const [fileKey, setFileKey] = useState("");
  const [fileName, setFileName] = useState("");
  const [outputLocale, setOutputLocale] = useState("vi");

  const [uploading, setUploading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [gateError, setGateError] = useState<string | null>(null);
  const [quota, setQuota] = useState<ImportQuota | null>(null);

  const loadQuota = useCallback(async () => {
    try {
      setQuota(await learningImportService.getQuota());
    } catch {
      // Silent: the panel still works without it, and the create call enforces
      // the real limit anyway. Showing an error here would be noise.
    }
  }, []);

  useEffect(() => {
    loadQuota();
  }, [loadQuota]);

  const uploadPdf = async (file: File) => {
    setUploading(true);
    setGateError(null);
    try {
      const res = await cloudflareService.upload(file, {
        prefix: "pdf_",
        folder: "user_import",
      });
      // The API wants the object KEY and fetches the file back out of R2
      // itself. Sending `url` here would 500 on a missing key.
      const key = res?.data?.data?.key;
      if (!key) throw new Error("Không nhận được key của file");
      setFileKey(key);
      setFileName(file.name);
      showSuccess("Đã tải PDF lên — bấm Chạy thử để bắt đầu");
    } catch (e: any) {
      console.error(e);
      showError(e?.response?.data?.message || "Tải file thất bại");
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  const run = async () => {
    setSubmitting(true);
    setGateError(null);
    try {
      await learningImportService.createImport({
        sourceType,
        ...(sourceType === "pdf"
          ? { fileKey, fileName }
          : { url: url.trim() }),
        outputLocale,
      });
      showSuccess("Đã bắt đầu — theo dõi ở bảng bên dưới");
      setUrl("");
      setFileKey("");
      setFileName("");
      onStarted();
      loadQuota();
    } catch (e: any) {
      // A gate rejection carries its reason as a code; anything else is just a
      // message. Saying WHICH gate closed is the difference between a usable
      // panel and one that says "failed" and leaves you guessing.
      const code = e?.response?.data?.errors?.[0]?.code;
      setGateError(
        (code && GATE_MESSAGES[code]) ||
          e?.response?.data?.message ||
          "Không chạy được, thử lại sau.",
      );
    } finally {
      setSubmitting(false);
    }
  };

  const canRun =
    !submitting &&
    !uploading &&
    (sourceType === "pdf" ? Boolean(fileKey) : url.trim().length > 0);

  return (
    <div className="mb-6 rounded-xl border border-gray-200 bg-white p-5">
      <div className="mb-4 flex items-start justify-between gap-4">
        <div>
          <h2 className="text-lg font-semibold text-gray-900">Chạy thử</h2>
          <p className="mt-1 text-sm text-gray-500">
            Tạo một bài học thật bằng tài khoản đang đăng nhập, không cần mở app.
            Đi qua đúng các cổng chặn của app (Premium, hạn mức tháng, một job
            mỗi người).
          </p>
        </div>
        {quota && (
          <div className="whitespace-nowrap text-right text-xs text-gray-500">
            <div>
              Còn {quota.remaining}/{quota.limit} lượt tháng này
            </div>
            <div className={quota.isPremium ? "text-emerald-600" : "text-rose-600"}>
              {quota.isPremium ? "Tài khoản Premium" : "Chưa Premium"}
            </div>
          </div>
        )}
      </div>

      <div className="flex flex-wrap items-start gap-3">
        <TextField
          select
          size="small"
          label="Nguồn"
          value={sourceType}
          onChange={(e) => {
            setSourceType(e.target.value as ImportSourceType);
            setGateError(null);
          }}
          className="min-w-[140px]"
        >
          <MenuItem value="youtube">YouTube</MenuItem>
          <MenuItem value="pdf">PDF</MenuItem>
        </TextField>

        {sourceType === "youtube" ? (
          <TextField
            size="small"
            label="Link YouTube"
            placeholder="https://youtube.com/watch?v=..."
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            className="min-w-[320px] flex-1"
          />
        ) : (
          <div className="flex min-w-[320px] flex-1 items-center gap-3">
            <Button variant="outlined" component="label" disabled={uploading}>
              {uploading ? "Đang tải..." : "Chọn PDF"}
              <input
                ref={fileInputRef}
                type="file"
                accept="application/pdf"
                hidden
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  if (file) uploadPdf(file);
                }}
              />
            </Button>
            <span className="truncate text-sm text-gray-600">
              {fileName || "Chưa chọn file"}
            </span>
          </div>
        )}

        <TextField
          select
          size="small"
          label="Ngôn ngữ bài học"
          value={outputLocale}
          onChange={(e) => setOutputLocale(e.target.value)}
          className="min-w-[160px]"
        >
          {LOCALES.map((l) => (
            <MenuItem key={l.code} value={l.code}>
              {l.label}
            </MenuItem>
          ))}
        </TextField>

        <Button
          variant="contained"
          onClick={run}
          disabled={!canRun}
          startIcon={<PlayCircleIcon className="h-5 w-5" />}
        >
          {submitting ? "Đang gửi..." : "Chạy thử"}
        </Button>
      </div>

      {gateError && (
        <div className="mt-4 rounded-lg border border-rose-200 bg-rose-50 p-3 text-sm text-rose-700">
          {gateError}
        </div>
      )}
    </div>
  );
}
