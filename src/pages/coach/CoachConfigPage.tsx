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

const EMPTY: CoachConfig = {
  enabled: false,
  hotlines: [],
  geminiModel: "",
  geminiSceneModel: "",
  onboardAskStyle: true,
  onboardAskAge: true,
  onboardAskGender: true,
  onboardAskJob: true,
};

/** Bốn câu onboarding tắt được — ba câu đầu (mục tiêu, khó khăn, đang làm) luôn hỏi. */
const ONBOARD_TOGGLES: { key: keyof CoachConfig; label: string; hint: string }[] = [
  { key: "onboardAskStyle", label: "Hỏi cách học", hint: "Nghe · Đọc · Thực hành — practice làm Coach trả lời ngắn hơn." },
  { key: "onboardAskAge", label: "Hỏi độ tuổi", hint: "Sáng sẵn từ user.age nếu app đã biết; ghi ngược lại vào user." },
  { key: "onboardAskGender", label: "Hỏi giới tính", hint: "Có lựa chọn không nói; sáng sẵn từ user.gender." },
  { key: "onboardAskJob", label: "Hỏi công việc", hint: "Gõ tay được — server gom về 6 nhóm để chọn cảnh cho đúng người." },
];

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
        geminiModel: d.geminiModel ?? "",
        geminiSceneModel: d.geminiSceneModel ?? "",
        onboardAskStyle: d.onboardAskStyle ?? true,
        onboardAskAge: d.onboardAskAge ?? true,
        onboardAskGender: d.onboardAskGender ?? true,
        onboardAskJob: d.onboardAskJob ?? true,
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
        <div>
          <h2 className="text-lg font-medium">Model AI</h2>
          <p className="text-sm text-gray-500 mt-1">
            Đổi ở đây ăn ngay (ưu tiên hơn biến môi trường của server), không
            cần deploy. Để trống = dùng env <code>GEMINI_MODEL</code> /{" "}
            <code>GEMINI_SCENE_MODEL</code>.
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <TextField
            label="Model hội thoại"
            size="small"
            fullWidth
            placeholder="vd: gemini-flash-lite-latest"
            value={form.geminiModel ?? ""}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, geminiModel: e.target.value }))
            }
            helperText="Chạy trên MỌI lượt trả lời của Coach — model to lên là giá mỗi lượt tăng theo."
          />
          <TextField
            label="Model viết cảnh"
            size="small"
            fullWidth
            placeholder="vd: gemini-flash-latest"
            value={form.geminiSceneModel ?? ""}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, geminiSceneModel: e.target.value }))
            }
            helperText="Chỉ chạy 1 lần mỗi lượt luyện tình huống (prompt nặng nhất) — nên để model mạnh hơn hội thoại. Trống = theo model hội thoại."
          />
        </div>
      </Paper>

      <Paper className="p-5 space-y-3">
        <div>
          <h2 className="text-lg font-medium">Onboarding Coach</h2>
          <p className="text-sm text-gray-500 mt-1">
            Phiên Home đầu tiên của mỗi người: Coach tự giới thiệu, hỏi xưng hô,
            mục tiêu, khó khăn, đang làm gì — rồi bốn câu dưới đây nếu bật. Ai
            đã qua onboarding (có <code>onboardedAt</code>) sẽ không gặp lại.
            Mọi câu đều bỏ qua được trừ xưng hô.
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-x-6">
          {ONBOARD_TOGGLES.map((t) => (
            <div key={t.key} className="py-1">
              <FormControlLabel
                control={
                  <Switch
                    checked={Boolean(form[t.key])}
                    onChange={(e) =>
                      setForm((prev) => ({ ...prev, [t.key]: e.target.checked }))
                    }
                  />
                }
                label={t.label}
              />
              <p className="text-xs text-gray-500 -mt-1 ml-12">{t.hint}</p>
            </div>
          ))}
        </div>
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
