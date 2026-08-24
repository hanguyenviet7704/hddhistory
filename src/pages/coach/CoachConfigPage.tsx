import React, { useCallback, useEffect, useState } from "react";
import {
  Alert,
  Button,
  CircularProgress,
  FormControlLabel,
  IconButton,
  Paper,
  Switch,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Tooltip,
} from "@mui/material";
import { PlusIcon, TrashIcon } from "@heroicons/react/24/outline";

import { coachService } from "../../services/coachService";
import {
  CoachConfig,
  CoachHotline,
} from "../../types/interface/coach.interface";
import { useNotification } from "../../utils/hooks/useNotification";

const LOCALES = ["en", "vi", "zh", "ja", "ko"];

const EMPTY: CoachConfig = { enabled: false, hotlines: [] };

const CoachConfigPage: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [form, setForm] = useState<CoachConfig>(EMPTY);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await coachService.getConfig();
      const d = res?.data ?? {};
      setForm({
        enabled: d.enabled ?? false,
        hotlines: Array.isArray(d.hotlines) ? d.hotlines : [],
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
      await coachService.updateConfig(form);
      showSuccess("Đã lưu cấu hình AI Coach");
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Lưu thất bại");
    } finally {
      setSaving(false);
    }
  };

  const patchHotline = (index: number, patch: Partial<CoachHotline>) =>
    setForm((prev) => ({
      ...prev,
      hotlines: prev.hotlines.map((h, i) =>
        i === index ? { ...h, ...patch } : h
      ),
    }));

  const addHotline = () =>
    setForm((prev) => ({
      ...prev,
      hotlines: [
        ...prev.hotlines,
        { locale: "vi", country: "", label: "", number: "" },
      ],
    }));

  const removeHotline = (index: number) =>
    setForm((prev) => ({
      ...prev,
      hotlines: prev.hotlines.filter((_, i) => i !== index),
    }));

  if (loading) {
    return (
      <div className="flex justify-center p-10">
        <CircularProgress />
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">AI Coach</h1>
        <p className="text-sm text-gray-500 mt-1">
          Công tắc tổng và số đường dây nóng cho đường thoát an toàn.
        </p>
      </div>

      {error && <Alert severity="error">{error}</Alert>}

      <Paper className="p-5 space-y-3">
        <FormControlLabel
          control={
            <Switch
              checked={form.enabled}
              onChange={(e) =>
                setForm((prev) => ({ ...prev, enabled: e.target.checked }))
              }
            />
          }
          label="Bật AI Coach"
        />
        <p className="text-sm text-gray-500">
          Tắt thì bong bóng không hiện ở đâu cả và các endpoint phiên đều từ
          chối. Mặc định là tắt — Coach nói chuyện với người thật về chuyện khó
          nói, nên nó bật khi có người quyết định bật.
        </p>
      </Paper>

      <Paper className="p-5 space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-medium">Đường dây nóng</h2>
            <p className="text-sm text-gray-500 mt-1">
              Tra theo locale + quốc gia, thiếu thì rơi về dòng cùng locale
              không có quốc gia, cuối cùng là <code>en</code>. Để trống hết cũng
              hợp lệ — app sẽ nói &ldquo;hãy liên hệ cấp cứu tại địa phương&rdquo;
              thay vì đưa một số không gọi được ở nơi họ đang sống.
            </p>
          </div>
          <Button
            variant="outlined"
            startIcon={<PlusIcon className="w-4 h-4" />}
            onClick={addHotline}
          >
            Thêm dòng
          </Button>
        </div>

        {form.hotlines.length === 0 ? (
          <p className="text-sm text-gray-400 italic py-4">
            Chưa có số nào.
          </p>
        ) : (
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell width={110}>Locale</TableCell>
                <TableCell width={110}>Quốc gia</TableCell>
                <TableCell>Tên hiển thị</TableCell>
                <TableCell width={180}>Số</TableCell>
                <TableCell width={60} />
              </TableRow>
            </TableHead>
            <TableBody>
              {form.hotlines.map((hotline, index) => (
                <TableRow key={index}>
                  <TableCell>
                    <TextField
                      select
                      size="small"
                      fullWidth
                      SelectProps={{ native: true }}
                      value={hotline.locale}
                      onChange={(e) =>
                        patchHotline(index, { locale: e.target.value })
                      }
                    >
                      {LOCALES.map((l) => (
                        <option key={l} value={l}>
                          {l}
                        </option>
                      ))}
                    </TextField>
                  </TableCell>
                  <TableCell>
                    <TextField
                      size="small"
                      fullWidth
                      placeholder="VN"
                      value={hotline.country ?? ""}
                      onChange={(e) =>
                        patchHotline(index, { country: e.target.value })
                      }
                    />
                  </TableCell>
                  <TableCell>
                    <TextField
                      size="small"
                      fullWidth
                      placeholder="Đường dây nóng Ngày Mai"
                      value={hotline.label}
                      onChange={(e) =>
                        patchHotline(index, { label: e.target.value })
                      }
                    />
                  </TableCell>
                  <TableCell>
                    <TextField
                      size="small"
                      fullWidth
                      placeholder="096 306 1414"
                      value={hotline.number}
                      onChange={(e) =>
                        patchHotline(index, { number: e.target.value })
                      }
                    />
                  </TableCell>
                  <TableCell>
                    <Tooltip title="Xoá dòng">
                      <IconButton
                        size="small"
                        onClick={() => removeHotline(index)}
                      >
                        <TrashIcon className="w-4 h-4" />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Paper>

      <div className="flex gap-2">
        <Button variant="contained" onClick={save} disabled={saving}>
          {saving ? "Đang lưu…" : "Lưu"}
        </Button>
        <Button variant="text" onClick={load} disabled={saving}>
          Tải lại
        </Button>
      </div>
    </div>
  );
};

export default CoachConfigPage;
