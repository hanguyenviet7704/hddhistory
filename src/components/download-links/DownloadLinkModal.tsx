import React, { useEffect, useState } from "react";
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  Switch,
  TextField,
} from "@mui/material";

import { DOWNLOAD_LINK_BASE } from "../../services/downloadLinkService";
import {
  DownloadLinkPayload,
  IDownloadLink,
} from "../../types/interface/download-link.interface";

interface Props {
  open: boolean;
  link: IDownloadLink | null;
  saving: boolean;
  onClose: () => void;
  onSubmit: (payload: DownloadLinkPayload) => void;
}

const EMPTY: DownloadLinkPayload = {
  slug: "",
  name: "",
  description: "",
  utmSource: "",
  utmMedium: "",
  utmCampaign: "",
  ogTitle: "",
  ogDescription: "",
  ogImage: "",
  isActive: true,
};

/** Mirrors the API's slug rule so the error shows before the round trip. */
const SLUG_PATTERN = /^[a-z0-9][a-z0-9-]*$/;

const slugify = (value: string) =>
  value
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/đ/g, "d")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 64);

const DownloadLinkModal: React.FC<Props> = ({
  open,
  link,
  saving,
  onClose,
  onSubmit,
}) => {
  const [form, setForm] = useState<DownloadLinkPayload>(EMPTY);
  const [slugTouched, setSlugTouched] = useState(false);

  const isEdit = Boolean(link);

  useEffect(() => {
    if (!open) return;
    setSlugTouched(false);
    setForm(
      link
        ? {
            slug: link.slug,
            name: link.name,
            description: link.description ?? "",
            utmSource: link.utmSource ?? "",
            utmMedium: link.utmMedium ?? "",
            utmCampaign: link.utmCampaign ?? "",
            ogTitle: link.ogTitle ?? "",
            ogDescription: link.ogDescription ?? "",
            ogImage: link.ogImage ?? "",
            isActive: link.isActive,
          }
        : EMPTY
    );
  }, [open, link]);

  const set = (key: keyof DownloadLinkPayload, value: string | boolean) =>
    setForm((prev) => ({ ...prev, [key]: value }));

  // Suggest a slug from the name until the user types their own.
  const onNameChange = (value: string) => {
    setForm((prev) => ({
      ...prev,
      name: value,
      ...(!isEdit && !slugTouched ? { slug: slugify(value) } : {}),
    }));
  };

  const slugError =
    !isEdit && form.slug !== "" && !SLUG_PATTERN.test(form.slug ?? "")
      ? "Chỉ dùng chữ thường, số và dấu gạch ngang"
      : "";

  // Mirrors the API's rule: crawlers reject data: URIs and http images, so
  // anything but an absolute https URL is refused before the round trip.
  const ogImageError =
    form.ogImage?.trim() && !/^https:\/\/.+/.test(form.ogImage.trim())
      ? "Phải là URL tuyệt đối bắt đầu bằng https://"
      : "";

  const canSubmit =
    form.name.trim() !== "" &&
    (isEdit || (form.slug?.trim() !== "" && !slugError)) &&
    !ogImageError &&
    !saving;

  const handleSubmit = () => {
    if (!canSubmit) return;
    const payload: DownloadLinkPayload = {
      name: form.name.trim(),
      description: form.description?.trim() || undefined,
      utmSource: form.utmSource?.trim() || undefined,
      utmMedium: form.utmMedium?.trim() || undefined,
      utmCampaign: form.utmCampaign?.trim() || undefined,
      ogTitle: form.ogTitle?.trim() || undefined,
      ogDescription: form.ogDescription?.trim() || undefined,
      ogImage: form.ogImage?.trim() || undefined,
      isActive: form.isActive,
      // Omitted when editing: the API rejects slug changes, because a link
      // already printed or turned into a QR code cannot be recalled.
      ...(isEdit ? {} : { slug: form.slug?.trim() }),
    };
    onSubmit(payload);
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>{isEdit ? "Sửa link" : "Tạo link mới"}</DialogTitle>

      <DialogContent className="flex flex-col gap-4 pt-2">
        <TextField
          label="Tên"
          value={form.name}
          onChange={(e) => onNameChange(e.target.value)}
          fullWidth
          autoFocus
          size="small"
          placeholder="Zalo OA - chiến dịch tháng 8"
        />

        <TextField
          label="Slug"
          value={form.slug}
          onChange={(e) => {
            setSlugTouched(true);
            set("slug", slugify(e.target.value));
          }}
          fullWidth
          size="small"
          disabled={isEdit}
          error={Boolean(slugError)}
          helperText={
            slugError ||
            (isEdit
              ? "Không đổi được sau khi tạo — link đã phát ra sẽ hỏng"
              : `${DOWNLOAD_LINK_BASE}/${form.slug || "..."}`)
          }
        />

        <TextField
          label="Ghi chú"
          value={form.description}
          onChange={(e) => set("description", e.target.value)}
          fullWidth
          size="small"
          multiline
          minRows={2}
          placeholder="Đăng ở Zalo OA ngày 01/08"
        />

        <div className="grid grid-cols-3 gap-3">
          <TextField
            label="utm_source"
            value={form.utmSource}
            onChange={(e) => set("utmSource", e.target.value)}
            size="small"
            placeholder="zalo"
          />
          <TextField
            label="utm_medium"
            value={form.utmMedium}
            onChange={(e) => set("utmMedium", e.target.value)}
            size="small"
            placeholder="social"
          />
          <TextField
            label="utm_campaign"
            value={form.utmCampaign}
            onChange={(e) => set("utmCampaign", e.target.value)}
            size="small"
            placeholder="thang-8"
          />
        </div>
        <p className="-mt-2 text-xs text-gray-500">
          Ba trường UTM được gắn vào tham số <code>referrer</code> của Google
          Play. Chưa có gì đọc chúng — để sẵn cho sau này, khỏi phải phát lại
          link đã in ra.
        </p>

        <div className="flex flex-col gap-4 border-t pt-4">
          <p className="-mb-1 text-sm font-semibold text-gray-700">
            Preview khi chia sẻ
          </p>
          <TextField
            label="Tiêu đề preview"
            value={form.ogTitle}
            onChange={(e) => set("ogTitle", e.target.value)}
            fullWidth
            size="small"
            placeholder="HDDhistory — Học kỹ năng mềm mỗi ngày"
          />
          <TextField
            label="Mô tả preview"
            value={form.ogDescription}
            onChange={(e) => set("ogDescription", e.target.value)}
            fullWidth
            size="small"
            multiline
            minRows={2}
            placeholder="7 ngày xây thói quen học cùng HDDhistory."
          />
          <TextField
            label="Ảnh preview (URL)"
            value={form.ogImage}
            onChange={(e) => set("ogImage", e.target.value)}
            fullWidth
            size="small"
            error={Boolean(ogImageError)}
            helperText={
              ogImageError ||
              "URL https tuyệt đối, nên là ảnh 1200×630. Bỏ trống = ảnh HDDhistory mặc định."
            }
            placeholder="https://meup.training/og-image.png"
          />
          <p className="-mt-2 text-xs text-gray-500">
            Thẻ hiển thị khi link được dán lên Facebook, Threads, TikTok,
            Zalo... Bỏ trống thì dùng thẻ HDDhistory chung.
          </p>
        </div>

        <FormControlLabel
          control={
            <Switch
              checked={Boolean(form.isActive)}
              onChange={(e) => set("isActive", e.target.checked)}
            />
          }
          label="Đang hoạt động"
        />
        {!form.isActive && (
          <p className="-mt-3 text-xs text-gray-500">
            Link tắt vẫn mở được, nhưng đưa thẳng về trang tải app chung và
            không được tính click.
          </p>
        )}
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose} disabled={saving}>
          Huỷ
        </Button>
        <Button variant="contained" onClick={handleSubmit} disabled={!canSubmit}>
          {saving ? "Đang lưu..." : "Lưu"}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default DownloadLinkModal;
