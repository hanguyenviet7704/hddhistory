import React, { useCallback, useEffect, useRef, useState } from "react";
import { CircularProgress } from "@mui/material";
import { PhotoIcon, PlusIcon, XMarkIcon } from "@heroicons/react/24/outline";

import { cloudflareService } from "../../services/cloudflareR2Service";
import { learningImportService } from "../../services/learningImportService";
import { ILearningImportConfig } from "../../types/interface/learningImport.interface";
import { useNotification } from "../../utils/hooks/useNotification";

/**
 * The two art pools a generated lesson is dealt its images from — LESSON covers
 * and KEYPOINT-node thumbnails, uploaded here instead of shipping as mock
 * assets inside the app.
 *
 * Two separate grids because they are two different kinds of picture (a course
 * tile vs a roadmap thumbnail), not one pool read at two sizes. Every change
 * saves immediately: the pool is a list of urls, and "upload then remember to
 * press Save" is how a batch of art gets half-applied.
 *
 * Removing an image only takes it OUT OF THE POOL — the R2 object stays,
 * because every lesson already dealt that url still points at it.
 */
export default function CoverPoolPanel() {
  const { showError, showSuccess } = useNotification();

  const [config, setConfig] = useState<ILearningImportConfig | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchConfig = useCallback(async () => {
    try {
      const data = await learningImportService.getConfig();
      setConfig(data);
    } catch (e: any) {
      showError(
        e?.response?.data?.message || "Không tải được kho ảnh bài tự tạo.",
      );
    } finally {
      setLoading(false);
    }
  }, [showError]);

  useEffect(() => {
    fetchConfig();
  }, [fetchConfig]);

  const savePool = useCallback(
    async (
      field: "courseCoverUrls" | "keypointImageUrls",
      urls: string[],
    ): Promise<boolean> => {
      try {
        const updated = await learningImportService.updateConfig({
          [field]: urls,
        });
        setConfig(updated);
        return true;
      } catch (e: any) {
        showError(e?.response?.data?.message || "Lưu kho ảnh thất bại.");
        // Re-read so the grid matches what the server actually holds.
        fetchConfig();
        return false;
      }
    },
    [fetchConfig, showError],
  );

  return (
    <div className="rounded-xl border border-gray-200 bg-white p-5">
      <div className="mb-1 flex items-center gap-2">
        <PhotoIcon className="h-5 w-5 text-gray-500" />
        <h2 className="text-base font-semibold text-gray-900">
          Kho ảnh bài tự tạo
        </h2>
      </div>
      <p className="mb-4 text-sm text-gray-500">
        Ảnh được gán cho bài ngay lúc tạo và giữ nguyên từ đó — thêm/xoá ảnh ở
        đây chỉ ảnh hưởng các bài tạo sau. Kho trống thì app dùng ảnh mặc định
        đóng gói sẵn.
      </p>

      {loading || !config ? (
        <div className="flex items-center gap-2 py-6 text-sm text-gray-500">
          <CircularProgress size={16} /> Đang tải kho ảnh…
        </div>
      ) : (
        <div className="grid gap-6 lg:grid-cols-2">
          <PoolSection
            title="Ảnh bìa bài"
            hint="Cover của bài — hiện ở đầu roadmap và trên thẻ trong “Bài tôi tạo”."
            urls={config.courseCoverUrls ?? []}
            folder="user-lesson-covers/course"
            onSave={(urls) => savePool("courseCoverUrls", urls)}
            onUploaded={(n) => showSuccess(`Đã thêm ${n} ảnh bìa bài.`)}
          />
          <PoolSection
            title="Ảnh keypoint"
            hint="Thumbnail từng node keypoint trên roadmap — các node của một bài xoay vòng qua kho này."
            urls={config.keypointImageUrls ?? []}
            folder="user-lesson-covers/keypoint"
            onSave={(urls) => savePool("keypointImageUrls", urls)}
            onUploaded={(n) => showSuccess(`Đã thêm ${n} ảnh keypoint.`)}
          />
        </div>
      )}
    </div>
  );
}

interface PoolSectionProps {
  title: string;
  hint: string;
  urls: string[];
  /** R2 folder the uploads land in — keeps the two pools apart in storage too. */
  folder: string;
  /** Persist the whole list; resolves false when the server refused it. */
  onSave: (urls: string[]) => Promise<boolean>;
  onUploaded: (count: number) => void;
}

function PoolSection({
  title,
  hint,
  urls,
  folder,
  onSave,
  onUploaded,
}: PoolSectionProps) {
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFiles = async (files: FileList | null) => {
    if (!files || files.length === 0) return;
    setUploading(true);
    try {
      // Sequential rather than parallel: a batch of ten racing uploads against
      // the same endpoint is how one 429 turns into ten confusing failures.
      const uploaded: string[] = [];
      for (const file of Array.from(files)) {
        const res = await cloudflareService.upload(file, {
          prefix: "",
          folder,
        });
        const url = res?.data?.data?.url;
        if (url) uploaded.push(url);
      }
      if (uploaded.length > 0) {
        const saved = await onSave([...urls, ...uploaded]);
        if (saved) onUploaded(uploaded.length);
      }
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  const removeAt = (index: number) => {
    onSave(urls.filter((_, i) => i !== index));
  };

  return (
    <div className="rounded-lg border border-gray-200 p-4">
      <div className="mb-1 flex items-center justify-between">
        <span className="text-sm font-semibold text-gray-800">{title}</span>
        <span className="text-xs text-gray-400">{urls.length} ảnh</span>
      </div>
      <p className="mb-3 text-xs text-gray-500">{hint}</p>

      <div className="grid grid-cols-4 gap-2 sm:grid-cols-5">
        {urls.map((url, index) => (
          <div
            key={`${url}-${index}`}
            className="group relative aspect-square overflow-hidden rounded-lg border border-gray-200 bg-gray-50"
          >
            {/* eslint-disable-next-line jsx-a11y/img-redundant-alt */}
            <img
              src={url}
              alt={`${title} ${index + 1}`}
              className="h-full w-full object-cover"
              loading="lazy"
            />
            <button
              type="button"
              onClick={() => removeAt(index)}
              title="Rút khỏi kho (bài đã gán giữ nguyên ảnh)"
              className="absolute right-1 top-1 hidden rounded-full bg-black/60 p-1 text-white group-hover:block"
            >
              <XMarkIcon className="h-3.5 w-3.5" />
            </button>
          </div>
        ))}

        <button
          type="button"
          disabled={uploading}
          onClick={() => fileInputRef.current?.click()}
          className="flex aspect-square items-center justify-center rounded-lg border-2 border-dashed border-gray-300 text-gray-400 hover:border-indigo-400 hover:text-indigo-500 disabled:opacity-50"
        >
          {uploading ? (
            <CircularProgress size={18} />
          ) : (
            <PlusIcon className="h-6 w-6" />
          )}
        </button>
      </div>

      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        multiple
        hidden
        onChange={(e) => handleFiles(e.target.files)}
      />
    </div>
  );
}
