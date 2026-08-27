import React, { useRef, useState } from "react";
import { Button, TextField } from "@mui/material";

import { cloudflareService } from "../../services/cloudflareR2Service";

interface Props {
  /** Empty string means "no image" — that is also what clears one server-side. */
  value: string;
  onChange: (imageUrl: string) => void;
  /** Lifted so the page can block Save while an upload is still running. */
  onUploadingChange?: (uploading: boolean) => void;
  onError?: (message: string) => void;
  onSuccess?: (message: string) => void;
  disabled?: boolean;
  /** Distinguishes the R2 folder for campaigns vs scheduled templates. */
  folder?: string;
  label?: string;
}

/**
 * Ô ảnh của một noti: preview, tải lên R2, gỡ, và ô URL để dán ảnh có sẵn.
 *
 * Dùng chung cho campaign gửi thủ công và template định kỳ vì hai chỗ đó cần
 * đúng một hành vi giống nhau — kể cả cái quy ước "chuỗi rỗng = xoá ảnh" mà API
 * dựa vào để phân biệt với "không gửi field thì giữ ảnh cũ".
 *
 * Preview để tỉ lệ 2:1 theo BigPictureStyle của Android, chỗ ảnh hiện to nhất.
 * iOS crop khác nên đây là gợi ý bố cục, không phải khung chính xác.
 */
const NotificationImageField: React.FC<Props> = ({
  value,
  onChange,
  onUploadingChange,
  onError,
  onSuccess,
  disabled = false,
  folder = "notification",
  label = "Ảnh kèm noti",
}) => {
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const uploadImage = async (file: File) => {
    setUploading(true);
    onUploadingChange?.(true);
    try {
      const res = await cloudflareService.upload(file, { prefix: "", folder });
      const url = res?.data?.data?.url;
      if (!url) throw new Error("Không nhận được URL ảnh");
      onChange(url);
      onSuccess?.("Đã tải ảnh lên — bấm Lưu để áp dụng");
    } catch (e: any) {
      console.error(e);
      onError?.(
        e?.response?.data?.message || "Tải ảnh thất bại, vui lòng thử lại.",
      );
    } finally {
      setUploading(false);
      onUploadingChange?.(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  return (
    <div>
      <p className="mb-2 text-sm font-medium text-gray-700">{label}</p>

      <div
        className="mb-2 w-full overflow-hidden rounded-lg bg-gray-100"
        style={{ aspectRatio: "2 / 1", maxWidth: 360 }}
      >
        {value ? (
          <img
            src={value}
            alt="Ảnh noti"
            className="h-full w-full object-cover"
          />
        ) : (
          <div className="flex h-full items-center justify-center px-4 text-center text-xs text-gray-400">
            Chưa có ảnh — noti sẽ chỉ có chữ
          </div>
        )}
      </div>

      <div className="mb-2 flex items-center gap-3">
        <Button
          variant="outlined"
          size="small"
          component="label"
          disabled={uploading || disabled}
        >
          {uploading ? "Đang tải..." : "Tải ảnh lên"}
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            hidden
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) uploadImage(file);
            }}
          />
        </Button>
        {value && (
          <Button
            size="small"
            color="error"
            disabled={disabled}
            onClick={() => onChange("")}
          >
            Gỡ ảnh
          </Button>
        )}
      </div>

      <TextField
        label="URL ảnh"
        size="small"
        fullWidth
        disabled={disabled}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        helperText="Tự điền sau khi tải ảnh lên, hoặc dán URL ảnh có sẵn. Android hiện ảnh ở mọi trạng thái app; iOS cần bản app có NotificationService extension."
      />
    </div>
  );
};

export default NotificationImageField;
