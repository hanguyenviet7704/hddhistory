import React, { useCallback, useEffect, useMemo, useState } from "react";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import {
  Alert,
  Button,
  Chip,
  CircularProgress,
  Paper,
  TextField,
  Tooltip,
} from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";

import { coachService } from "../../services/coachService";
import {
  CoachThreadMessage,
  CoachThreadPage,
  CoachThreadSession,
} from "../../types/interface/coach.interface";
import {
  dateInput,
  ENTRY_LABEL,
  formatMetaBits,
  KIND_META,
  KIND_QUESTION,
} from "../../utils/coachContentKinds";

const LIMIT = 500;

const time = (iso: string) =>
  new Date(iso).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });

/** Gom các phiên theo ngày để dòng thời gian có mốc. */
const byDay = (sessions: CoachThreadSession[]) => {
  const days: Array<{ day: string; sessions: CoachThreadSession[] }> = [];
  for (const session of sessions) {
    const day = new Date(session.startedAt).toLocaleDateString();
    const last = days[days.length - 1];
    if (last?.day === day) last.sessions.push(session);
    else days.push({ day, sessions: [session] });
  }
  return days;
};

/**
 * Một bong bóng chat.
 *
 * Coach bên trái nền xám, user bên phải nền teal — quy ước chat mà ai cũng đọc
 * được ngay, không phải học. Dòng tái dựng thì viền đứt và có nhãn, vì "Coach
 * đã nói câu này" và "bước này Coach luôn hỏi câu này" là hai khẳng định khác
 * nhau, và người đọc đang rút ra kết luận từ chúng.
 */
const Bubble: React.FC<{ message: CoachThreadMessage }> = ({ message }) => {
  const mine = message.role === "user";
  const kind = message.kind ? KIND_META[message.kind] : null;
  const text =
    message.text ??
    (message.kind ? KIND_QUESTION[message.kind] : "(không còn lời Coach)");

  return (
    <div className={`flex flex-col ${mine ? "items-end" : "items-start"}`}>
      {mine && kind && (
        <Tooltip title={kind.hint} placement="left">
          <span
            className={`mb-1 rounded-full border px-2 py-0.5 text-[11px] ${kind.color}`}
          >
            {kind.label}
          </span>
        </Tooltip>
      )}

      <div
        className={`max-w-[68%] whitespace-pre-wrap rounded-2xl px-3.5 py-2.5 text-sm ${
          mine
            ? "rounded-br-sm bg-teal-600 text-white"
            : message.derived
              ? "rounded-bl-sm border border-dashed border-slate-300 bg-white italic text-slate-500"
              : "rounded-bl-sm bg-slate-100 text-slate-800"
        }`}
      >
        {text}
      </div>

      <div className="mt-0.5 flex items-center gap-1 text-[11px] text-slate-400">
        <span>{time(message.at)}</span>
        {mine && formatMetaBits(message.meta) && (
          <span>· {formatMetaBits(message.meta)}</span>
        )}
        {message.derived && <span>· câu cố định của bước này, tái dựng</span>}
      </div>
    </div>
  );
};

const CoachUserThread: React.FC = () => {
  const { userId = "" } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const opened = (location.state ?? {}) as { from?: string; to?: string };

  const [page, setPage] = useState<CoachThreadPage | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [from, setFrom] = useState(opened.from ?? dateInput(29));
  const [to, setTo] = useState(opened.to ?? dateInput());

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await coachService.getUserThread(userId, {
        from,
        to,
        limit: LIMIT,
      });
      setPage(res?.data ?? null);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được hội thoại");
    } finally {
      setLoading(false);
    }
  }, [userId, from, to]);

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userId]);

  const days = useMemo(() => byDay(page?.sessions ?? []), [page]);
  const derivedCount = useMemo(
    () => (page?.sessions ?? []).filter((s) => s.source === "derived").length,
    [page],
  );

  return (
    <div className="space-y-5 p-6">
      <div className="flex items-start gap-3">
        <Button
          size="small"
          startIcon={<ArrowBackIcon />}
          onClick={() => navigate("/coach-contents")}
        >
          Danh sách
        </Button>
        <div>
          <h1 className="text-2xl font-semibold">
            {page?.user?.name || "Hội thoại Coach"}
          </h1>
          <p className="mt-1 text-sm text-gray-500">
            {page?.user?.email ? `${page.user.email} · ` : ""}
            <span className="font-mono text-xs">{userId}</span>
          </p>
        </div>
      </div>

      {error && <Alert severity="error">{error}</Alert>}

      <Paper className="flex flex-wrap items-end gap-3 p-4">
        <TextField
          size="small"
          label="Từ ngày"
          type="date"
          InputLabelProps={{ shrink: true }}
          value={from}
          onChange={(e) => setFrom(e.target.value)}
        />
        <TextField
          size="small"
          label="Đến ngày"
          type="date"
          InputLabelProps={{ shrink: true }}
          value={to}
          onChange={(e) => setTo(e.target.value)}
        />
        <Button variant="contained" onClick={load} disabled={loading}>
          {loading ? "Đang tải…" : "Áp dụng"}
        </Button>
        <span className="text-xs text-slate-400">
          {page ? `${page.sessions.length} phiên` : ""}
        </span>
      </Paper>

      {derivedCount > 0 && (
        <Alert severity="info">
          {derivedCount} phiên đã quá hạn lưu nên được <b>tái dựng</b>: chữ user
          là thật, còn lời Coach chỉ còn với câu hỏi tình huống — các câu khác
          hiện là câu cố định của bước đó, không phải bản ghi. Phiên mở sau khi
          bản này lên sẽ được lưu nguyên văn 30 ngày.
        </Alert>
      )}

      {page?.truncated && (
        <Alert severity="warning">
          Đã chạm trần {page.limit} dòng mỗi nguồn — user này viết nhiều hơn số
          đang hiện. Thu hẹp khoảng ngày để đọc đủ.
        </Alert>
      )}

      {loading ? (
        <div className="flex justify-center p-10">
          <CircularProgress />
        </div>
      ) : days.length === 0 ? (
        <Paper className="p-10 text-center text-sm text-gray-500">
          Không có hội thoại nào trong khoảng này.
        </Paper>
      ) : (
        <div className="space-y-6">
          {days.map((day) => (
            <div key={day.day} className="space-y-3">
              <div className="sticky top-0 z-10 bg-slate-50/90 py-1 text-sm font-medium text-slate-500 backdrop-blur">
                {day.day}
              </div>

              {day.sessions.map((session, index) => (
                <Paper
                  key={session.sessionId ?? `loose-${day.day}-${index}`}
                  className="space-y-4 p-4"
                >
                  <div className="flex flex-wrap items-center gap-2 border-b border-slate-100 pb-2 text-xs text-slate-400">
                    <span className="font-medium text-slate-500">
                      {time(session.startedAt)}
                    </span>
                    {session.sessionId ? (
                      <span>
                        {ENTRY_LABEL[session.entry ?? ""] ?? "Phiên Coach"}
                      </span>
                    ) : (
                      // Câu kể viết ở màn habit chứ không trong phiên — ghép nó
                      // vào một phiên nào đó là bịa ra ngữ cảnh.
                      <span>Ngoài phiên</span>
                    )}
                    <Chip
                      size="small"
                      variant="outlined"
                      label={
                        session.source === "transcript"
                          ? "Nguyên văn"
                          : "Tái dựng"
                      }
                      className={
                        session.source === "transcript"
                          ? "border-emerald-200 bg-emerald-50 text-emerald-800"
                          : "border-amber-200 bg-amber-50 text-amber-900"
                      }
                    />
                    {session.sessionId && (
                      <span className="font-mono">{session.sessionId}</span>
                    )}
                  </div>

                  <div className="flex flex-col gap-3">
                    {session.messages.map((message, position) => (
                      <Bubble
                        key={`${message.at}-${position}`}
                        message={message}
                      />
                    ))}
                  </div>
                </Paper>
              ))}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default CoachUserThread;
