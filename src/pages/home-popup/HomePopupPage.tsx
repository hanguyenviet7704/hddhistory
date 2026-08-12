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
  HomePopupConfig,
  homePopupService,
} from "../../services/homePopupService";
import { useNotification } from "../../utils/hooks/useNotification";
import { COUNTRY_OPTIONS, countryLabel } from "../../config/countries";

const DEFAULTS: HomePopupConfig = {
  enabled: false,
  imageUrl: "",
  linkUrl: "",
  countries: [],
};

/**
 * Popup khuyến mãi trên màn Home: một ảnh duy nhất, bấm được, và ngừng hiện với
 * người đã bấm. Ảnh, link, thị trường và bật/tắt đều là config nên chạy chiến
 * dịch không cần phát hành app.
 */
const HomePopupPage: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [form, setForm] = useState<HomePopupConfig>(DEFAULTS);
  // Kept from the last load so an edit can be compared against what is live:
  // changing image or link starts a new campaign, and that is worth saying out
  // loud before Save rather than discovering it from analytics.
  const [savedCreative, setSavedCreative] = useState({ imageUrl: "", linkUrl: "" });
  const [campaignKey, setCampaignKey] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await homePopupService.get();
      const d = (res?.data ?? {}) as Partial<HomePopupConfig>;
      setForm({
        enabled: d.enabled ?? DEFAULTS.enabled,
        imageUrl: d.imageUrl ?? DEFAULTS.imageUrl,
        linkUrl: d.linkUrl ?? DEFAULTS.linkUrl,
        countries: d.countries ?? DEFAULTS.countries,
      });
      setSavedCreative({
        imageUrl: d.imageUrl ?? "",
        linkUrl: d.linkUrl ?? "",
      });
      setCampaignKey(d.campaignKey ?? "");
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
      await homePopupService.update(form);
      showSuccess("Đã lưu cấu hình");
      // Reload so the campaign key shown is the one the server computed, not a
      // guess made here.
      await load();
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
        folder: "home-popup",
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

  const startsNewCampaign =
    !loading &&
    Boolean(form.imageUrl) &&
    (form.imageUrl !== savedCreative.imageUrl ||
      form.linkUrl !== savedCreative.linkUrl);

  return (
    <div className="p-6">
      <header className="mb-5">
        <h1 className="text-xl font-semibold">Popup Home</h1>
        <p className="mt-1 max-w-2xl text-sm text-gray-500">
          Popup hiện trên màn Home, tối đa một lần mỗi lần mở app. Ai{" "}
          <strong>bấm vào ảnh</strong> thì không thấy lại nữa; ai đóng đi thì lần
          mở app sau vẫn thấy. Chữ nằm trong ảnh, không có ô nhập text — nhờ vậy
          không phải dịch ra 5 ngôn ngữ app đang chạy.
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
            label="Hiện popup trên app"
          />
          <p className="mb-5 mt-1 text-xs text-gray-500">
            Tắt là popup ngừng hiện ngay (app cache tối đa 60 giây), không cần
            phát hành bản mới. Bật/tắt <strong>không</strong> làm mới chiến dịch —
            ai đã bấm vẫn không thấy lại.
          </p>

          <p className="mb-2 text-sm font-medium text-gray-700">Ảnh popup</p>
          <div className="mb-2 w-full overflow-hidden rounded-xl bg-gray-100">
            {form.imageUrl ? (
              <img
                src={form.imageUrl}
                alt="Popup preview"
                className="max-h-80 w-full object-contain"
              />
            ) : (
              <div className="flex h-40 items-center justify-center text-xs text-gray-400">
                Chưa có ảnh — popup sẽ không hiện trên app
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
            helperText="Ảnh hiện nguyên tỉ lệ (không crop) nên dùng ảnh dọc vừa phải, chữ nằm trong ảnh."
          />

          <div className="h-5" />

          <TextField
            label="Link khi bấm vào popup"
            size="small"
            fullWidth
            value={form.linkUrl}
            onChange={(e) => setForm((p) => ({ ...p, linkUrl: e.target.value }))}
            helperText="URL https:// hoặc deeplink. Để trống thì popup chỉ để thông báo, bấm vào vẫn tính là đã xem và không hiện lại."
          />

          <div className="h-5" />

          <Autocomplete
            multiple
            size="small"
            options={COUNTRY_OPTIONS}
            value={form.countries.map(
              (code) =>
                COUNTRY_OPTIONS.find((c) => c.code === code) ?? {
                  code,
                  name: countryLabel(code),
                },
            )}
            onChange={(_, selected) =>
              setForm((p) => ({ ...p, countries: selected.map((c) => c.code) }))
            }
            isOptionEqualToValue={(a, b) => a.code === b.code}
            getOptionLabel={(c) => `${c.name} (${c.code})`}
            renderInput={(params) => (
              <TextField
                {...params}
                label="Chỉ hiện với các thị trường"
                helperText="Để trống = hiện với mọi người. Khớp theo BẤT KỲ tín hiệu nào: IP, region của máy, hoặc ngôn ngữ app (chọn VN thì người Việt ở nước ngoài vẫn thấy)."
              />
            )}
          />

          {startsNewCampaign && (
            <p className="mt-4 rounded bg-amber-50 px-3 py-2 text-xs leading-relaxed text-amber-800">
              Ảnh hoặc link đã đổi — lưu là <strong>bắt đầu chiến dịch mới</strong>
              , nên cả những người từng bấm popup cũ cũng sẽ thấy popup này.
            </p>
          )}

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
            Chiến dịch hiện tại:{" "}
            <code className="rounded bg-gray-100 px-1">
              {campaignKey || "chưa có"}
            </code>
            . Mã này là dấu vân tay của ảnh + link, dùng để nhớ ai đã bấm. Quay lại
            dùng đúng ảnh và link cũ thì mã cũ trở lại, nên người đã bấm chiến dịch
            đó sẽ không bị hỏi lại.
          </p>
        </Paper>
      )}
    </div>
  );
};

export default HomePopupPage;
