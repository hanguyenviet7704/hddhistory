import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  Autocomplete,
  Button,
  CircularProgress,
  FormControlLabel,
  Paper,
  Switch,
  TextField,
} from "@mui/material";

import { cloudflareService } from "../../services/cloudflareR2Service";
import {
  HomeBannerConfig,
  homeBannerService,
} from "../../services/homeBannerService";
import { useNotification } from "../../utils/hooks/useNotification";
import { COUNTRY_OPTIONS, countryLabel } from "../../config/countries";

const DEFAULTS: HomeBannerConfig = {
  enabled: false,
  imageUrl: "",
  linkUrl: "",
  countries: [],
  // Server-computed and irrelevant here; kept only so the form object matches
  // the response type. Never read it on this page.
  visible: false,
};

/**
 * Banner khuyến mãi trên màn Home của app (design "2 · Home"): một ảnh
 * full-width nằm giữa "Khóa học mới hôm nay" và "Jump back in". Ảnh, link và
 * bật/tắt đều là config nên chạy chiến dịch không cần phát hành bản app mới.
 */
const HomeBannerPage: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [form, setForm] = useState<HomeBannerConfig>(DEFAULTS);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await homeBannerService.get();
      const d = res?.data ?? {};
      setForm({
        enabled: d.enabled ?? DEFAULTS.enabled,
        imageUrl: d.imageUrl ?? DEFAULTS.imageUrl,
        linkUrl: d.linkUrl ?? DEFAULTS.linkUrl,
        countries: d.countries ?? DEFAULTS.countries,
        visible: d.visible ?? DEFAULTS.visible,
      });
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được cấu hình");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const save = async () => {
    setSaving(true);
    try {
      await homeBannerService.update(form);
      showSuccess("Đã lưu cấu hình");
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Lưu thất bại");
    } finally {
      setSaving(false);
    }
  };

  const uploadImage = async (file: File) => {
    setUploading(true);
    try {
      const res = await cloudflareService.upload(file, {
        prefix: "",
        folder: "home-banner",
      });
      const url = res?.data?.data?.url;
      if (!url) throw new Error("Không nhận được URL ảnh");
      setForm((p) => ({ ...p, imageUrl: url }));
      showSuccess("Đã tải ảnh lên — bấm Lưu để áp dụng");
    } catch (e: any) {
      console.error(e);
      showError(
        e?.response?.data?.message || "Tải ảnh thất bại, vui lòng thử lại.",
      );
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  return (
    <div className="p-6">
      <header className="mb-5">
        <h1 className="text-xl font-semibold">Banner Home</h1>
        <p className="mt-1 max-w-2xl text-sm text-gray-500">
          Banner ảnh full-width trên màn Home của app, nằm giữa khối "Khóa học
          mới hôm nay" và "Jump back in". Có thể chuẩn bị sẵn ảnh + link rồi mới
          bật công tắc khi chiến dịch bắt đầu.
        </p>
      </header>

      {loading ? (
        <div className="flex justify-center py-16">
          <CircularProgress size={26} />
        </div>
      ) : (
        <Paper variant="outlined" className="max-w-xl p-5">
          {error && (
            <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-700">
              {error}
            </p>
          )}

          <FormControlLabel
            control={
              <Switch
                checked={form.enabled}
                onChange={(e) =>
                  setForm((p) => ({ ...p, enabled: e.target.checked }))
                }
              />
            }
            label="Hiện banner trên app"
          />
          <p className="mb-5 mt-1 text-xs text-gray-500">
            Tắt là banner biến mất khỏi app ngay (app cache tối đa 60 giây),
            không cần phát hành bản mới. Chưa có ảnh thì app cũng tự ẩn banner.
          </p>

          {/* Preview đúng tỉ lệ khung banner trong app: 390 × 78, bo góc 18 */}
          <p className="mb-2 text-sm font-medium text-gray-700">Ảnh banner</p>
          <div
            className="mb-2 w-full overflow-hidden bg-gray-100"
            style={{ aspectRatio: "390 / 78", borderRadius: 18 }}
          >
            {form.imageUrl ? (
              <img
                src={form.imageUrl}
                alt="Banner preview"
                className="h-full w-full object-cover"
              />
            ) : (
              <div className="flex h-full items-center justify-center text-xs text-gray-400">
                Chưa có ảnh — banner sẽ không hiện trên app
              </div>
            )}
          </div>
          <div className="mb-4 flex items-center gap-3">
            <Button
              variant="outlined"
              size="small"
              component="label"
              disabled={uploading}
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
            {form.imageUrl && (
              <Button
                size="small"
                color="error"
                onClick={() => setForm((p) => ({ ...p, imageUrl: "" }))}
              >
                Gỡ ảnh
              </Button>
            )}
          </div>

          <TextField
            label="URL ảnh"
            size="small"
            fullWidth
            value={form.imageUrl}
            onChange={(e) =>
              setForm((p) => ({ ...p, imageUrl: e.target.value }))
            }
            helperText="Tự điền sau khi tải ảnh lên, hoặc dán URL ảnh có sẵn."
          />

          <div className="h-5" />

          <TextField
            label="Link khi bấm vào banner"
            size="small"
            fullWidth
            value={form.linkUrl}
            onChange={(e) =>
              setForm((p) => ({ ...p, linkUrl: e.target.value }))
            }
            helperText="URL https:// hoặc deeplink của app. Để trống thì banner chỉ hiển thị, không bấm được."
          />

          <div className="h-5" />

          <Autocomplete
            multiple
            size="small"
            options={COUNTRY_OPTIONS}
            // Stored codes may include ones outside the curated list (added
            // straight through the API, or from before an entry existed), so
            // map through `countryLabel` rather than assuming a match.
            value={form.countries.map(
              (code) =>
                COUNTRY_OPTIONS.find((c) => c.code === code) ?? {
                  code,
                  name: countryLabel(code),
                },
            )}
            onChange={(_, selected) =>
              setForm((p) => ({
                ...p,
                countries: selected.map((c) => c.code),
              }))
            }
            isOptionEqualToValue={(a, b) => a.code === b.code}
            getOptionLabel={(c) => `${c.name} (${c.code})`}
            renderInput={(params) => (
              <TextField
                {...params}
                label="Chỉ hiện ở các quốc gia"
                helperText="Để trống = hiện ở mọi quốc gia. Xác định theo IP người dùng; ai không xác định được vị trí sẽ KHÔNG thấy banner có giới hạn quốc gia."
              />
            )}
          />

          <div className="mt-6 flex items-center gap-3">
            <Button
              variant="contained"
              onClick={save}
              disabled={saving || uploading}
            >
              {saving ? "Đang lưu..." : "Lưu"}
            </Button>
            <Button onClick={load} disabled={saving || uploading}>
              Khôi phục
            </Button>
          </div>

          <p className="mt-5 border-t pt-4 text-xs leading-relaxed text-gray-500">
            App chỉ hiện banner khi <strong>đã bật</strong> và{" "}
            <strong>có ảnh</strong>. Ảnh hiển thị cao 78pt, bo góc 18 — nên dùng
            ảnh tỉ lệ ~5:1 (ví dụ 1170 × 234) để không bị crop lệch.
          </p>
        </Paper>
      )}
    </div>
  );
};

export default HomeBannerPage;
