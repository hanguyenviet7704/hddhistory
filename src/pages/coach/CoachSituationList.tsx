import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  Alert,
  Button,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  MenuItem,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Tooltip,
} from "@mui/material";
import { PencilSquareIcon, TrashIcon } from "@heroicons/react/24/outline";

import { coachService } from "../../services/coachService";
import { habitService } from "../../services/habitService";
import {
  CoachSituation,
  CoachSituationVariant,
} from "../../types/interface/coach.interface";
import { IHabit } from "../../types/interface/habit.interface";
import { LangCode } from "../../types/enum/common.enum";
import { getTranslationValue } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";

const LOCALES = ["", "en", "vi", "zh", "ja", "ko"];

const VARIANTS: Array<{ value: "" | CoachSituationVariant; label: string }> = [
  { value: "", label: "Tất cả biến thể" },
  { value: "default", label: "default — ngôi thứ hai" },
  { value: "third_person", label: "third_person — ③B kể về người khác" },
  { value: "after_done", label: "after_done — vừa làm được" },
  { value: "after_missed", label: "after_missed — có dịp mà chưa làm" },
  { value: "after_none", label: "after_none — chưa có dịp" },
  { value: "practice", label: "practice — chỉ tập" },
];

const CoachSituationList: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [rows, setRows] = useState<CoachSituation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [locale, setLocale] = useState("");
  const [variant, setVariant] = useState<"" | CoachSituationVariant>("");
  const [habitId, setHabitId] = useState("");
  const [habits, setHabits] = useState<IHabit[]>([]);
  const [rebuilding, setRebuilding] = useState(false);

  const [editing, setEditing] = useState<CoachSituation | null>(null);
  const [draftPrompt, setDraftPrompt] = useState("");
  const [draftSamples, setDraftSamples] = useState("");
  const [draftBeats, setDraftBeats] = useState("");
  const [draftTakeaway, setDraftTakeaway] = useState("");
  const [draftGoodMove, setDraftGoodMove] = useState("");
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await coachService.getSituations({
        locale: locale || undefined,
        variant: variant || undefined,
        habitId: habitId || undefined,
      });
      setRows(Array.isArray(res?.data) ? res.data : []);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được danh sách");
    } finally {
      setLoading(false);
    }
  }, [locale, variant, habitId]);

  useEffect(() => {
    load();
  }, [load]);

  // Habit titles for the rows and the filter. Loaded once; the list is small.
  useEffect(() => {
    (async () => {
      try {
        const res: any = await habitService.getList({ isAll: true });
        const list = Array.isArray(res?.data)
          ? res.data
          : Array.isArray(res?.data?.items)
          ? res.data.items
          : Array.isArray(res)
          ? res
          : [];
        setHabits(list as IHabit[]);
      } catch {
        setHabits([]);
      }
    })();
  }, []);

  const habitTitle = useCallback(
    (id: string) => {
      const habit = habits.find((h) => h._id === id);
      return habit ? getTranslationValue(habit.title, LangCode.VI) || getTranslationValue(habit.title, LangCode.EN) : "";
    },
    [habits]
  );

  const rebuildPool = async () => {
    if (!habitId) return;
    const ok = window.confirm(
      `Xoá toàn bộ cảnh AI đã sinh của habit “${habitTitle(habitId)}”?\n\n` +
        "Kho sẽ được dựng lại từ description + contexts hiện tại ở lần tập tiếp theo. Cảnh đã sửa tay được giữ."
    );
    if (!ok) return;
    setRebuilding(true);
    try {
      const res = await coachService.rebuildHabitPool(habitId);
      showSuccess(`Đã xoá ${res?.data?.deleted ?? 0} cảnh — lần tập tới sẽ sinh lại`);
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Không dựng lại được");
    } finally {
      setRebuilding(false);
    }
  };

  const editedCount = useMemo(
    () => rows.filter((r) => r.source === "edited").length,
    [rows]
  );

  const openEditor = (row: CoachSituation) => {
    setEditing(row);
    setDraftPrompt(row.prompt);
    setDraftSamples((row.samples ?? []).join("\n"));
    setDraftBeats((row.beats ?? []).join("\n"));
    setDraftTakeaway(row.takeaway ?? "");
    setDraftGoodMove(row.goodMove ?? "");
  };

  const saveEdit = async () => {
    if (!editing) return;
    const toList = (value: string) =>
      value
        .split("\n")
        .map((line) => line.trim())
        .filter(Boolean);
    setSaving(true);
    try {
      await coachService.updateSituation(editing._id, {
        prompt: draftPrompt,
        samples: toList(draftSamples),
        beats: toList(draftBeats),
        takeaway: draftTakeaway.trim(),
        goodMove: draftGoodMove.trim(),
      });
      showSuccess("Đã sửa tình huống — từ giờ AI không ghi đè lên nữa");
      setEditing(null);
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Lưu thất bại");
    } finally {
      setSaving(false);
    }
  };

  const remove = async (row: CoachSituation) => {
    const ok = window.confirm(
      "Xoá tình huống này? Người dùng tiếp theo cần tới nó sẽ sinh lại một cái mới.\n\n" +
        "Những câu trả lời đã lưu cho tình huống cũ vẫn còn, nhưng sẽ không so sánh được với cái mới ở khối ĐỔI THAY — vì đó là hai câu hỏi khác nhau."
    );
    if (!ok) return;

    try {
      await coachService.removeSituation(row._id);
      showSuccess("Đã xoá");
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Xoá thất bại");
    }
  };

  return (
    <div className="p-6 space-y-5">
      <div>
        <h1 className="text-2xl font-semibold">Tình huống Coach</h1>
        <p className="text-sm text-gray-500 mt-1">
          Cache, không phải nội dung soạn tay. Mỗi habit (theo ngôn ngữ, biến
          thể, nhóm tuổi, mục tiêu) giữ một kho tối đa vài cảnh — đủ kho thì
          xoay cảnh cũ, không sinh thêm. Cảnh sinh từ description + contexts của
          habit; đổi hai trường đó thì bấm <strong>Dựng lại kho cảnh</strong>.
          Trang này để sửa hoặc bỏ cái dở <strong>sau khi</strong> nó đã ra.
        </p>
      </div>

      {error && <Alert severity="error">{error}</Alert>}

      <Paper className="p-4 flex flex-wrap gap-3 items-center">
        <TextField
          select
          size="small"
          label="Ngôn ngữ"
          value={locale}
          onChange={(e) => setLocale(e.target.value)}
          sx={{ minWidth: 140 }}
        >
          {LOCALES.map((l) => (
            <MenuItem key={l || "all"} value={l}>
              {l || "Tất cả"}
            </MenuItem>
          ))}
        </TextField>

        <TextField
          select
          size="small"
          label="Biến thể"
          value={variant}
          onChange={(e) =>
            setVariant(e.target.value as "" | CoachSituationVariant)
          }
          sx={{ minWidth: 280 }}
        >
          {VARIANTS.map((v) => (
            <MenuItem key={v.value || "all"} value={v.value}>
              {v.label}
            </MenuItem>
          ))}
        </TextField>

        <TextField
          select
          size="small"
          label="Habit"
          value={habitId}
          onChange={(e) => setHabitId(e.target.value)}
          sx={{ minWidth: 320 }}
        >
          <MenuItem value="">Tất cả habit</MenuItem>
          {habits.map((h) => (
            <MenuItem key={h._id} value={h._id}>
              {getTranslationValue(h.title, LangCode.VI) || getTranslationValue(h.title, LangCode.EN) || h._id}
            </MenuItem>
          ))}
        </TextField>

        {habitId && (
          <Tooltip title="Xoá cảnh AI đã sinh của habit này để kho dựng lại từ description + contexts mới">
            <Button size="small" variant="outlined" onClick={rebuildPool} disabled={rebuilding}>
              {rebuilding ? "Đang xoá…" : "Dựng lại kho cảnh"}
            </Button>
          </Tooltip>
        )}

        <div className="ml-auto text-sm text-gray-500">
          {rows.length} dòng · {editedCount} đã sửa tay
        </div>
      </Paper>

      <Paper>
        {loading ? (
          <div className="flex justify-center p-10">
            <CircularProgress />
          </div>
        ) : rows.length === 0 ? (
          <p className="p-10 text-center text-gray-400 italic">
            Chưa có tình huống nào được sinh. Cache trống là bình thường trước
            khi có người dùng thật đi qua luồng.
          </p>
        ) : (
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell width={220}>Habit</TableCell>
                <TableCell width={60}>Slot</TableCell>
                <TableCell width={70}>Locale</TableCell>
                <TableCell width={120}>Biến thể</TableCell>
                <TableCell>Tình huống</TableCell>
                <TableCell width={110}>Nguồn</TableCell>
                <TableCell width={140}>Tạo lúc</TableCell>
                <TableCell width={100} />
              </TableRow>
            </TableHead>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={row._id} hover>
                  <TableCell>
                    <span className="text-sm">{habitTitle(row.habitId) || <code className="text-xs">{row.habitId}</code>}</span>
                    {(row.audience || row.goalKey) && (
                      <div className="text-xs text-gray-400">
                        {[row.audience, row.goalKey].filter((v) => v && v !== "unknown").join(" · ")}
                      </div>
                    )}
                  </TableCell>
                  <TableCell>
                    <code className="text-xs">{row.slot ?? 0}</code>
                  </TableCell>
                  <TableCell>{row.locale}</TableCell>
                  <TableCell>
                    <code className="text-xs">{row.variant}</code>
                  </TableCell>
                  <TableCell className="!py-3">
                    <span className="text-sm">{row.prompt}</span>
                    <div className="text-xs text-gray-400 mt-1 space-y-0.5">
                      <div>
                        {row.beats?.length
                          ? `${row.beats.length} nhịp gợi`
                          : "chưa có kịch bản (cảnh cũ)"}
                      </div>
                      {row.takeaway && <div>Bài học: {row.takeaway}</div>}
                      {row.goodMove && <div>Nước đi: {row.goodMove}</div>}
                    </div>
                  </TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      label={row.source === "edited" ? "đã sửa" : "AI sinh"}
                      color={row.source === "edited" ? "success" : "default"}
                      variant={row.source === "edited" ? "filled" : "outlined"}
                    />
                  </TableCell>
                  <TableCell>
                    <span className="text-xs text-gray-500">
                      {row.createdAt ? new Date(row.createdAt).toLocaleString("vi-VN", { hour: "2-digit", minute: "2-digit", day: "2-digit", month: "2-digit" }) : ""}
                    </span>
                  </TableCell>
                  <TableCell>
                    <Tooltip title="Sửa">
                      <IconButton size="small" onClick={() => openEditor(row)}>
                        <PencilSquareIcon className="w-4 h-4" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Xoá để sinh lại">
                      <IconButton size="small" onClick={() => remove(row)}>
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

      <Dialog
        open={Boolean(editing)}
        onClose={() => setEditing(null)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Sửa tình huống & kịch bản</DialogTitle>
        <DialogContent>
          <p className="text-sm text-gray-500 mb-3">
            Cảnh: hai câu, một câu hỏi, dưới 30 từ. Câu hỏi hỏi họ{" "}
            <em>sẽ nói hay làm gì</em> — không hỏi cảm thấy thế nào, và không
            được gợi ý là có đáp án đúng.
          </p>
          <TextField
            label="Cảnh + câu hỏi"
            multiline
            minRows={3}
            fullWidth
            value={draftPrompt}
            onChange={(e) => setDraftPrompt(e.target.value)}
          />

          <TextField
            label="Gợi ý trả lời (mỗi dòng một câu, 2 câu)"
            multiline
            minRows={2}
            fullWidth
            className="!mt-4"
            value={draftSamples}
            onChange={(e) => setDraftSamples(e.target.value)}
          />

          <div className="mt-5 mb-2 text-sm font-semibold text-gray-700">
            Kịch bản
          </div>
          <p className="text-xs text-gray-400 mb-3">
            Coach đi theo các nhịp này rồi chốt bằng bài học + nước đi. Mặc định
            1 nhịp (2 lượt), tối đa 2 nhịp (3 lượt). Nhịp là ý cần khơi
            (&ldquo;họ sẽ nói câu đầu tiên là gì&rdquo;), không phải câu hỏi soạn
            sẵn.
          </p>
          <TextField
            label="Nhịp gợi (mỗi dòng một nhịp, tối đa 2)"
            multiline
            minRows={2}
            fullWidth
            value={draftBeats}
            onChange={(e) => setDraftBeats(e.target.value)}
          />
          <TextField
            label="Bài học (takeaway) — một câu"
            fullWidth
            className="!mt-4"
            value={draftTakeaway}
            onChange={(e) => setDraftTakeaway(e.target.value)}
          />
          <TextField
            label="Nước đi đúng (goodMove) — prefill Nhắc hẹn, ≤10 từ"
            fullWidth
            className="!mt-4"
            value={draftGoodMove}
            onChange={(e) => setDraftGoodMove(e.target.value)}
          />

          <p className="text-xs text-gray-400 mt-3">
            Lưu xong dòng này chuyển sang &ldquo;đã sửa&rdquo; và AI sẽ không bao
            giờ ghi đè lên nữa. Trường để trống sẽ giữ nguyên giá trị cũ.
          </p>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditing(null)}>Huỷ</Button>
          <Button
            variant="contained"
            onClick={saveEdit}
            disabled={saving || !draftPrompt.trim()}
          >
            {saving ? "Đang lưu…" : "Lưu"}
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  );
};

export default CoachSituationList;
