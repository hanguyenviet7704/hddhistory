import React, { useEffect, useState } from "react";
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  TextField,
} from "@mui/material";

import {
  ICommunityAdminPost,
  ICommunityWeeklyPayload,
} from "../../types/interface/community.interface";
import { ITranslation } from "../../utils/translation";
import TranslationFields from "./TranslationFields";

interface Props {
  open: boolean;
  question: ICommunityAdminPost | null;
  saving?: boolean;
  onClose: () => void;
  onSubmit: (payload: ICommunityWeeklyPayload) => void;
}

/** ISO week number, so the default matches the "TUẦN 34" label in the design. */
const isoWeek = (date: Date) => {
  const target = new Date(
    Date.UTC(date.getFullYear(), date.getMonth(), date.getDate())
  );
  const day = target.getUTCDay() || 7;
  target.setUTCDate(target.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(target.getUTCFullYear(), 0, 1));
  return Math.ceil(((target.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
};

/**
 * Format for a `datetime-local` input, which reads and writes LOCAL time.
 *
 * `toISOString()` converts to UTC first, so a naive version showed an operator
 * in UTC+7 a window shifted seven hours back — and saving it shifted it again,
 * because `new Date(value)` then read those digits as local.
 */
const toInputValue = (value?: string | null) => {
  if (!value) return "";
  const date = new Date(value);
  const localMs = date.getTime() - date.getTimezoneOffset() * 60_000;
  return new Date(localMs).toISOString().slice(0, 16);
};

const CommunityWeeklyModal: React.FC<Props> = ({
  open,
  question,
  saving,
  onClose,
  onSubmit,
}) => {
  const [title, setTitle] = useState<ITranslation>({});
  const [note, setNote] = useState<ITranslation>({});
  const [weekNumber, setWeekNumber] = useState(isoWeek(new Date()));
  const [year, setYear] = useState(new Date().getFullYear());
  const [startsAt, setStartsAt] = useState("");
  const [endsAt, setEndsAt] = useState("");

  useEffect(() => {
    if (!open) return;

    if (question) {
      setTitle(question.title ?? {});
      setNote(question.note ?? {});
      setWeekNumber(
        question.weekly?.weekNumber ?? isoWeek(new Date(question.createdAt))
      );
      setYear(
        question.weekly?.year ?? new Date(question.createdAt).getFullYear()
      );
      setStartsAt(toInputValue(question.weekly?.startsAt));
      setEndsAt(toInputValue(question.weekly?.endsAt));
      return;
    }

    // Default to the current Monday→Sunday window, which is what the app's
    // "còn N ngày" countdown reads.
    const now = new Date();
    const monday = new Date(now);
    const weekday = monday.getDay() === 0 ? 7 : monday.getDay();
    monday.setDate(monday.getDate() - (weekday - 1));
    monday.setHours(0, 0, 0, 0);
    const sunday = new Date(monday);
    sunday.setDate(sunday.getDate() + 7);

    setTitle({});
    setNote({});
    setWeekNumber(isoWeek(now));
    setYear(now.getFullYear());
    setStartsAt(toInputValue(monday.toISOString()));
    setEndsAt(toInputValue(sunday.toISOString()));
  }, [open, question]);

  const canSave =
    !!title.en?.trim() && !!startsAt && !!endsAt && endsAt > startsAt;

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="md">
      <DialogTitle>
        {question ? "Sửa câu hỏi của tuần" : "Câu hỏi của tuần mới"}
      </DialogTitle>
      <DialogContent className="space-y-5">
        <TranslationFields
          label="Câu hỏi"
          value={title}
          onChange={setTitle}
          rows={2}
          hint="Câu hỏi hiện cho MỌI user bất kể ngôn ngữ, nên nên dịch đủ 5 thứ tiếng."
        />
        <TranslationFields
          label="Ghi chú dưới câu hỏi"
          value={note}
          onChange={setNote}
          rows={2}
          hint='Dòng nhắc kiểu "Hãy trả lời bằng trải nghiệm của chính bạn".'
        />
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <TextField
            label="Tuần"
            size="small"
            type="number"
            value={weekNumber}
            onChange={(event) =>
              setWeekNumber(Number(event.target.value) || 1)
            }
          />
          <TextField
            label="Năm"
            size="small"
            type="number"
            value={year}
            onChange={(event) => setYear(Number(event.target.value) || year)}
          />
          <TextField
            label="Bắt đầu"
            size="small"
            type="datetime-local"
            value={startsAt}
            InputLabelProps={{ shrink: true }}
            onChange={(event) => setStartsAt(event.target.value)}
          />
          <TextField
            label="Kết thúc"
            size="small"
            type="datetime-local"
            value={endsAt}
            InputLabelProps={{ shrink: true }}
            onChange={(event) => setEndsAt(event.target.value)}
          />
        </div>
        <p className="text-xs text-gray-500">
          Chỉ một câu hỏi được mở tại một thời điểm — app lấy câu có khoảng thời
          gian đang chứa hiện tại. Đặt hai câu trùng khoảng thì app lấy câu bắt
          đầu muộn hơn.
        </p>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={saving}>
          Huỷ
        </Button>
        <Button
          variant="contained"
          disabled={saving || !canSave}
          onClick={() =>
            onSubmit({
              title,
              note,
              weekNumber,
              year,
              startsAt: new Date(startsAt).toISOString(),
              endsAt: new Date(endsAt).toISOString(),
            })
          }
        >
          Lưu
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default CommunityWeeklyModal;
