// src/components/common/CloudflareFileUpload.tsx
import React, { useState, useEffect, useId } from "react";
import {
  CloudArrowUpIcon,
  XMarkIcon,
  ArrowPathIcon,
} from "@heroicons/react/24/outline";
import { UploadFileToCloudflare } from "../../types/interface/files/cloudflare.interface";
import { cloudflareService } from "../../services/cloudflareR2Service";

interface Props {
  initialUrl?: string;
  onUrlChange: (url: string) => void;
  label: string;
  uploadPayload?: UploadFileToCloudflare;
  disabled?: boolean;
  accept?: string; // 👈 thêm prop để tùy loại file (vd: "image/*" hoặc "audio/*")
}

export default function CloudflareFileUpload({
  initialUrl = "",
  onUrlChange,
  label,
  uploadPayload,
  disabled = false,
  accept = "image/*", // mặc định vẫn là ảnh
}: Props) {
  const uniqueId = useId();
  const inputId = `file-upload-${label
    .replace(/\s+/g, "-")
    .toLowerCase()}-${uniqueId}`;
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [previewUrl, setPreviewUrl] = useState(initialUrl);
  const [fileType, setFileType] = useState<string>(""); // 👈 thêm state để biết đang xử lý audio hay image

  useEffect(() => {
    setPreviewUrl(initialUrl);
  }, [initialUrl]);

  const handleFileChange = async (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setError(null);
    setIsUploading(true);
    setFileType(file.type);

    try {
      const response = await cloudflareService.upload(file, uploadPayload);
      const newUrl = response?.data?.data?.url;

      if (!newUrl) throw new Error("API did not return a valid URL");

      setPreviewUrl(newUrl);
      onUrlChange(newUrl);
    } catch (err: any) {
      console.error("Upload error:", err);
      setError(err.response?.data?.message || err.message || "Upload failed.");
      setPreviewUrl(initialUrl);
    } finally {
      setIsUploading(false);
    }
  };

  const handleClearImage = () => {
    setPreviewUrl("");
    onUrlChange("");
    setError(null);
  };

  const isAudio =
    fileType.startsWith("audio") ||
    previewUrl.endsWith(".mp3") ||
    previewUrl.endsWith(".wav");

  return (
    <div>
      <label className="block text-sm font-medium text-gray-700 mb-1">
        {label}
      </label>

      <label
        htmlFor={inputId}
        className={`mt-2 flex justify-center items-center w-full h-32 px-4 transition bg-white border-2 border-gray-300 border-dashed rounded-lg appearance-none cursor-pointer hover:border-gray-400 focus:outline-none ${
          disabled ? "opacity-50 cursor-not-allowed" : ""
        }`}
      >
        {isUploading ? (
          <div className="flex flex-col items-center">
            <ArrowPathIcon className="h-8 w-8 text-gray-400 animate-spin" />
            <span className="mt-2 text-sm text-gray-500">Uploading...</span>
          </div>
        ) : previewUrl ? (
          <div className="relative w-full h-full flex items-center justify-center">
            {isAudio ? (
              <audio controls className="w-full">
                <source src={previewUrl} />
                Trình duyệt của bạn không hỗ trợ phát audio.
              </audio>
            ) : (
              <img
                src={previewUrl}
                alt="Preview"
                className="w-full h-full object-cover rounded-lg"
              />
            )}
            <button
              type="button"
              onClick={handleClearImage}
              className="absolute top-2 right-2 p-1 bg-red-500 text-white rounded-full hover:bg-red-600 transition"
            >
              <XMarkIcon className="h-4 w-4" />
            </button>
          </div>
        ) : (
          <div className="flex flex-col items-center">
            <CloudArrowUpIcon className="h-10 w-10 text-gray-400" />
            <span className="mt-2 text-sm text-gray-500">
              Click to upload or drag and drop
            </span>
            <p className="text-xs text-gray-500">
              {accept.includes("audio")
                ? "MP3, WAV up to 10MB"
                : "PNG, JPG, GIF up to 10MB"}
            </p>
          </div>
        )}
      </label>

      <input
        id={inputId}
        type="file"
        className="hidden"
        accept={accept} // 👈 hỗ trợ cả "audio/*"
        onChange={handleFileChange}
        disabled={disabled || isUploading}
      />

      {error && <p className="mt-2 text-sm text-red-600">{error}</p>}
    </div>
  );
}
