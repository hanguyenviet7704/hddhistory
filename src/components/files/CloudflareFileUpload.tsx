// src/components/common/CloudflareFileUpload.tsx
import React, { useState, useEffect, useId, useRef } from "react";
import {
  CloudArrowUpIcon,
  XMarkIcon,
  ArrowPathIcon,
} from "@heroicons/react/24/outline";
import lottie, { AnimationItem } from "lottie-web";
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
  const [fileName, setFileName] = useState<string>("");
  const [animationError, setAnimationError] = useState(false);
  const animationContainerRef = useRef<HTMLDivElement | null>(null);
  const animationInstanceRef = useRef<AnimationItem | null>(null);
  const extractKeyFromUrl = (url: string) => {
    const clean = url.split("?")[0].split("#")[0];
    if (!clean) return "";
    try {
      const parsed = new URL(clean);
      const path = decodeURIComponent(parsed.pathname);
      const marker = "/cloudflares/download/";
      const idx = path.indexOf(marker);
      if (idx >= 0) {
        return path.slice(idx + marker.length).replace(/^\/+/, "");
      }
      const parts = path.split("/").filter(Boolean);
      if (parts.length === 0) return "";
      return parts.slice(-2).join("/");
    } catch {
      const path = decodeURIComponent(clean);
      const marker = "/cloudflares/download/";
      const idx = path.indexOf(marker);
      if (idx >= 0) {
        return path.slice(idx + marker.length).replace(/^\/+/, "");
      }
      const parts = path.split("/").filter(Boolean);
      if (parts.length === 0) return "";
      return parts.slice(-2).join("/");
    }
  };

  const normalizeAnimationData = (raw: any) => {
    if (!raw) return null;
    if (typeof raw === "string") {
      try {
        return JSON.parse(raw);
      } catch {
        return null;
      }
    }
    if (raw.data) return raw.data;
    return raw;
  };

  useEffect(() => {
    setPreviewUrl(initialUrl);
    setFileType("");
    setFileName(initialUrl ? initialUrl.split("/").pop() || "" : "");
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
      setFileName(file.name);
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
    setAnimationError(false);
  };

  const isAudio =
    fileType.startsWith("audio") ||
    previewUrl.endsWith(".mp3") ||
    previewUrl.endsWith(".wav");

  const isImage =
    fileType.startsWith("image") ||
    /\.(png|jpg|jpeg|gif|webp|svg)$/i.test(previewUrl);

  const isAnimation =
    fileType.includes("json") ||
    fileType.includes("lottie") ||
    accept.includes("json") ||
    accept.includes("lottie") ||
    /\.(json|lottie)$/i.test(previewUrl);

  useEffect(() => {
    if (!isAnimation || !previewUrl || !animationContainerRef.current) {
      animationInstanceRef.current?.destroy();
      animationInstanceRef.current = null;
      setAnimationError(false);
      return;
    }

    let cancelled = false;

    const loadAnimation = async () => {
      setAnimationError(false);
      animationInstanceRef.current?.destroy();
      animationInstanceRef.current = null;

      const attachAnimation = (animationData: any) => {
        if (cancelled || !animationContainerRef.current) return;
        animationInstanceRef.current = lottie.loadAnimation({
          container: animationContainerRef.current,
          renderer: "svg",
          loop: true,
          autoplay: true,
          animationData,
        });
        const onDataFailed = () => setAnimationError(true);
        animationInstanceRef.current?.addEventListener(
          "data_failed",
          onDataFailed
        );
        animationInstanceRef.current?.addEventListener("error", onDataFailed);
      };

      try {
        let data: any = null;

        // Prefer backend proxy to avoid CORS issues with R2
        const key = extractKeyFromUrl(previewUrl) || previewUrl;
        console.log(222, key);

        try {
          const proxied = await cloudflareService.download(key);
          data = normalizeAnimationData(proxied);
        } catch (proxyErr) {
          console.error("Animation proxy error:", proxyErr);
        }

        // Fallback to direct fetch if proxy did not return usable data
        try {
          const res = await fetch(previewUrl, { mode: "cors" });
          if (res.ok) {
            data = await res.json();
          }
        } catch {
          // Ignore fetch errors; we'll show a preview error instead
        }

        if (!data) {
          throw new Error("Cannot load animation data");
        }

        attachAnimation(data);
      } catch (err) {
        console.error("Animation preview error:", err);
        if (!cancelled) setAnimationError(true);
      }
    };

    loadAnimation();

    return () => {
      cancelled = true;
      animationInstanceRef.current?.destroy();
      animationInstanceRef.current = null;
    };
  }, [isAnimation, previewUrl]);

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
            ) : isAnimation ? (
              <div className="relative w-full h-full bg-gray-50 rounded-lg overflow-hidden flex items-center justify-center">
                <div
                  ref={animationContainerRef}
                  className="w-full h-full flex items-center justify-center"
                />
                {animationError && (
                  <div className="absolute inset-0 flex items-center justify-center bg-white/80 text-sm text-red-600 px-3 text-center">
                    Không thể hiển thị preview cho animation này. Vui lòng kiểm
                    tra lại file.
                  </div>
                )}
                <div className="absolute bottom-2 left-2 right-2 flex items-center justify-between gap-2 text-xs text-gray-700">
                  <span className="font-semibold truncate">
                    {fileName || "Animation preview"}
                  </span>
                  <a
                    href={previewUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="text-indigo-600 hover:underline"
                  >
                    Open
                  </a>
                </div>
              </div>
            ) : isImage ? (
              <img
                src={previewUrl}
                alt="Preview"
                className="w-full h-full object-cover rounded-lg"
              />
            ) : (
              <div className="text-center text-sm text-gray-700 px-3 py-2 bg-gray-100 border border-dashed border-gray-300 rounded">
                <div className="font-semibold">Uploaded file</div>
                <div className="text-xs text-gray-500 break-all">
                  {fileName || previewUrl}
                </div>
                <a
                  href={previewUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="mt-1 inline-block text-indigo-600 hover:underline text-xs"
                >
                  Open
                </a>
              </div>
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
                : accept.includes("json") || accept.includes("lottie")
                ? "JSON / Lottie"
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
