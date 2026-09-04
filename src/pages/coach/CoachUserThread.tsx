import React, { useCallback, useEffect, useMemo, useState } from "react";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import {
  Alert,
  Button,
  Chip,
  CircularProgress,
  Paper,
  TextField,
} from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";

import { coachService } from "../../services/coachService";
import {
  CoachContentPage,
  CoachContentRow,
} from "../../types/interface/coach.interface";
import {
  dateInput,
  formatMeta,
  KIND_META,
  situationPrompt,
} from "../../utils/coachContentKinds";

/**
 * Cả một phiên gom lại: chữ user viết trong cùng một lần mở Coach.
 *
 * Câu kể không mang `sessionId` (nó được viết ở màn khác), nên nó rơi vào nhóm
 * "ngoài phiên" của ngày hôm đó thay vì bị ghép nhầm vào phiên gần nhất.
 */
interface ThreadGroup {
  key: string;
  sessionId: string | null;
  at: Date;
  rows: CoachContentRow[];
}

interface ThreadDay {
  day: string;
  groups: ThreadGroup[];
}

const LIMIT = 500;

/**
 * Xếp các dòng thành ngày → phiên → dòng, theo chiều thời gian TĂNG dần.
 *
 * Feed chung đọc ngược, mới nhất trước, vì câu hỏi ở đó là "vừa có gì mới".
 * Ở đây câu hỏi khác hẳn: một người đã đi qua những gì — mà chuyện thì phải
 * đọc xuôi mới ra chuyện.
 */
const toThread = (rows: CoachContentRow[]): ThreadDay[] => {
  const ascending = [...rows].sort(
    (left, right) =>
      new Date(left.createdAt).getTime() - new Date(right.createdAt).getTime(),
  );

  const days = new Map<string, Map<string, ThreadGroup>>();
  for (const row of ascending) {
    const at = new Date(row.createdAt);
    const day = at.toLocaleDateString();
    const key = row.sessionId ?? `${day}:loose`;

    const groups = days.get(day) ?? new Map<string, ThreadGroup>();
    const group =
      groups.get(key) ??
      ({ key, sessionId: row.sessionId, at, rows: [] } as ThreadGroup);
    group.rows.push(row);
    groups.set(key, group);
    days.set(day, groups);
  }

  return Array.from(days.entries()).map(([day, groups]) => ({
    day,
    groups: Array.from(groups.values()),
  }));
};

const CoachUserThread: React.FC = () => {
  const { userId = "" } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const opened = (location.state ?? {}) as { from?: string; to?: string };

  const [page, setPage] = useState<CoachContentPage | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [from, setFrom] = useState(opened.from ?? dateInput(29));
  const [to, setTo] = useState(opened.to ?? dateInput());

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await coachService.getContents({
        userId,
        from,
        to,
        limit: LIMIT,
      });
      setPage(res?.data ?? null);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được nội dung");
    } finally {
      setLoading(false);
    }
  }, [userId, from, to]);

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userId]);

  const thread = useMemo(() => toThread(page?.rows ?? []), [page]);

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
            {page?.user?.name || "Dòng thời gian của user"}
          </h1>
          <p className="mt-1 text-sm text-gray-500">
            {page?.user?.email ? `${page.user.email} · ` : ""}
            <span className="font-mono text-xs">{userId}</span>
          </p>
          <p className="mt-1 text-sm text-gray-500">
            Đọc xuôi theo thời gian, gom theo ngày và theo từng phiên Coach.{" "}
            <b>Đây không phải bản ghi hội thoại</b> — lời Coach nói bị xoá cùng
            phiên sau 48h. Chỗ duy nhất còn nghe được hai phía là câu trả lời
            tình huống: câu hỏi in nghiêng phía trên là chữ của biên tập viên.
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
          {page ? `${page.rows.length} dòng` : ""}
        </span>
      </Paper>

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
      ) : thread.length === 0 ? (
        <Paper className="p-10 text-center text-sm text-gray-500">
          User này không viết gì trong khoảng này.
        </Paper>
      ) : (
        <div className="space-y-6">
          {thread.map((day) => (
            <div key={day.day} className="space-y-3">
              <div className="sticky top-0 z-10 bg-slate-50/90 py-1 text-sm font-medium text-slate-500 backdrop-blur">
                {day.day}
              </div>

              {day.groups.map((group) => (
                <Paper key={group.key} className="space-y-4 p-4">
                  <div className="flex items-center gap-2 text-xs text-slate-400">
                    {group.sessionId ? (
                      <>
                        <span>Một phiên Coach</span>
                        <span className="font-mono">{group.sessionId}</span>
                      </>
                    ) : (
                      // Câu kể được viết ở màn habit chứ không trong phiên —
                      // ghép nó vào một phiên nào đó là bịa ra ngữ cảnh.
                      <span>Ngoài phiên</span>
                    )}
                  </div>

                  {group.rows.map((row) => (
                    <div key={row.id} className="space-y-1">
                      <div className="flex items-center gap-2">
                        <Chip
                          size="small"
                          variant="outlined"
                          title={KIND_META[row.kind]?.hint}
                          label={KIND_META[row.kind]?.label ?? row.kind}
                          className={KIND_META[row.kind]?.color}
                        />
                        <span className="text-xs text-slate-400">
                          {new Date(row.createdAt).toLocaleTimeString()}
                        </span>
                        {formatMeta(row) && (
                          <span className="text-xs text-slate-400">
                            · {formatMeta(row)}
                          </span>
                        )}
                      </div>

                      {situationPrompt(row) && (
                        <div className="border-l-2 border-slate-200 pl-3 text-sm italic text-slate-500">
                          {situationPrompt(row)}
                        </div>
                      )}

                      {/* Nguyên văn, không rút gọn. */}
                      <div className="whitespace-pre-wrap rounded-md bg-slate-50 p-3 text-sm text-slate-800">
                        {row.content}
                      </div>
                    </div>
                  ))}
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
