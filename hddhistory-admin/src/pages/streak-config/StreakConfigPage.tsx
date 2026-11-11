import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  CircularProgress,
  FormControlLabel,
  Paper,
  Switch,
  TextField,
} from "@mui/material";

import {
  StreakConfig,
  streakConfigService,
} from "../../services/streakConfigService";
import { useNotification } from "../../utils/hooks/useNotification";

const DEFAULTS: StreakConfig = {
  popupEnabled: true,
  triggerAfterSeconds: 120,
  autoHideSeconds: 3,
};

const StreakConfigPage: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [form, setForm] = useState<StreakConfig>(DEFAULTS);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await streakConfigService.get();
      const d = res?.data ?? {};
      setForm({
        popupEnabled: d.popupEnabled ?? DEFAULTS.popupEnabled,
        triggerAfterSeconds:
          d.triggerAfterSeconds ?? DEFAULTS.triggerAfterSeconds,
        autoHideSeconds: d.autoHideSeconds ?? DEFAULTS.autoHideSeconds,
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
      await streakConfigService.update(form);
      showSuccess("Đã lưu cấu hình");
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Lưu thất bại");
    } finally {
      setSaving(false);
    }
  };

  const minutes = (form.triggerAfterSeconds / 60).toFixed(
    form.triggerAfterSeconds % 60 === 0 ? 0 : 1
  );

  return (
    <div className="p-6">
      <header className="mb-5">
        <h1 className="text-xl font-semibold">Popup streak</h1>
        <p className="mt-1 max-w-2xl text-sm text-gray-500">
          Popup hiện sau khi người dùng đã ở trong app đủ lâu trong ngày. Trước
          đây nó chỉ hiện lúc học xong một keypoint — nghĩa là chỉ những người
          vốn đã học sâu mới thấy, đúng nhóm ít cần nhắc nhất.
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
                checked={form.popupEnabled}
                onChange={(e) =>
                  setForm((p) => ({ ...p, popupEnabled: e.target.checked }))
                }
              />
            }
            label="Bật popup streak"
          />
          <p className="mb-5 mt-1 text-xs text-gray-500">
            Tắt là popup biến mất khỏi app ngay, không cần phát hành bản mới.
          </p>

          <TextField
            label="Hiện sau (giây)"
            type="number"
            size="small"
            fullWidth
            value={form.triggerAfterSeconds}
            disabled={!form.popupEnabled}
            onChange={(e) =>
              setForm((p) => ({
                ...p,
                triggerAfterSeconds: Number(e.target.value),
              }))
            }
            inputProps={{ min: 0, max: 7200 }}
            helperText={`≈ ${minutes} phút. Tính TỔNG thời gian mở app trong ngày, cộng dồn nhiều lần vào ra — không phải 2 phút liên tục.`}
          />

          <div className="h-5" />

          <TextField
            label="Tự ẩn sau (giây)"
            type="number"
            size="small"
            fullWidth
            value={form.autoHideSeconds}
            disabled={!form.popupEnabled}
            onChange={(e) =>
              setForm((p) => ({
                ...p,
                autoHideSeconds: Number(e.target.value),
              }))
            }
            inputProps={{ min: 0, max: 60 }}
            helperText={
              form.autoHideSeconds === 0
                ? "0 = popup đứng yên cho tới khi người dùng bấm tắt."
                : "Thời gian popup tự biến mất."
            }
          />

          <div className="mt-6 flex items-center gap-3">
            <Button variant="contained" onClick={save} disabled={saving}>
              {saving ? "Đang lưu..." : "Lưu"}
            </Button>
            <Button onClick={load} disabled={saving}>
              Khôi phục
            </Button>
          </div>

          <p className="mt-5 border-t pt-4 text-xs leading-relaxed text-gray-500">
            Popup chỉ hiện <strong>một lần mỗi ngày</strong> cho mỗi người. App
            đọc cấu hình này lúc khởi động và cache 60 giây, nên đổi xong có thể
            mất tới một phút mới thấy hiệu lực.
          </p>
        </Paper>
      )}
    </div>
  );
};

export default StreakConfigPage;
