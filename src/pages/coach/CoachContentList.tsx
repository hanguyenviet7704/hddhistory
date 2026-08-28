import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  Alert,
  Button,
  Chip,
  CircularProgress,
  MenuItem,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
} from "@mui/material";

import { coachService } from "../../services/coachService";
import {
  CoachContentKind,
  CoachContentPage,
  CoachContentRow,
} from "../../types/interface/coach.interface";

/**
 * Sáu loại, xếp theo thứ tự "gần đời thật nhất trước".
 *
 * Câu kể đứng đầu vì nó là loại duy nhất chứng minh habit đã xảy ra ngoài đời;
 * câu trả lời tình huống đứng cuối vì đó là tập trong app, không tính.
 */
const KIND_META: Record<
  CoachContentKind,
  { label: string; hint: string; color: string }
> = {
  evidence: {
    label: "Câu kể",
    hint: "Lần làm thật ngoài đời — bằng chứng duy nhất",
    color: "bg-emerald-50 text-emerald-800 border-emerald-200",
  },
  problem_statement: {
    label: "Vấn đề thật",
    hint: "User tự gọi tên vấn đề của mình, sau bản nháp hai cột",
    color: "bg-indigo-50 text-indigo-800 border-indigo-200",
  },
  barrier: {
    label: "Rào cản",
    hint: "Cái gì làm họ dừng lại — dòng dạy cho nhắc hẹn biết nó quá to",
    color: "bg-amber-50 text-amber-900 border-amber-200",
  },
  quick_note: {
    label: "Ghi nhanh",
    hint: "Nhánh nông: ghi lại rồi thôi, không mở ra gì",
    color: "bg-slate-100 text-slate-700 border-slate-200",
  },
  dip: {
    label: "Dịp",
    hint: "Cụm chữ về đời thật mà nhắc hẹn neo vào",
    color: "bg-sky-50 text-sky-800 border-sky-200",
  },
  situation_answer: {
    label: "Trả lời tình huống",
    hint: "Tập trong app — KHÔNG tính là đã làm thật",
    color: "bg-violet-50 text-violet-800 border-violet-200",
  },
};

const KIND_ORDER = Object.keys(KIND_META) as CoachContentKind[];

const LIMIT_OPTIONS = [50, 100, 200, 500];

/** `YYYY-MM-DD` cho hôm nay và N ngày trước, theo giờ máy người xem. */
const dateInput = (daysAgo = 0) => {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  return date.toISOString().slice(0, 10);
};

const formatMeta = (row: CoachContentRow): string => {
  const parts: string[] = [];
  const meta = row.meta ?? {};

  if (typeof meta.round === "number") parts.push(`chặng ${meta.round}`);
  if (typeof meta.variant === "string" && meta.variant) {
    parts.push(meta.variant === "third_person" ? "ngôi thứ ba" : meta.variant);
  }
  // Tỉ lệ dòng bị kéo là chỉ số đo trực tiếp "AI có đang áp đặt không" —
  // gần bằng 0 nghĩa là đang áp đặt, nên nó phải đọc được ngay trên dòng.
  if (
    typeof meta.draftKeptCount === "number" &&
    typeof meta.draftProposedCount === "number" &&
    meta.draftProposedCount > 0
  ) {
    parts.push(`kéo ${meta.draftKeptCount}/${meta.draftProposedCount} dòng`);
  }

  return parts.join(" · ");
};

const CoachContentList: React.FC = () => {
  const [page, setPage] = useState<CoachContentPage | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [kinds, setKinds] = useState<CoachContentKind[]>([]);
  const [from, setFrom] = useState(dateInput(29));
  const [to, setTo] = useState(dateInput());
  const [userId, setUserId] = useState("");
  const [search, setSearch] = useState("");
  const [limit, setLimit] = useState(200);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await coachService.getContents({
        from,
        to,
        limit,
        ...(kinds.length ? { kinds } : {}),
        ...(userId.trim() ? { userId: userId.trim() } : {}),
        ...(search.trim() ? { search: search.trim() } : {}),
      });
      setPage(res?.data ?? null);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được nội dung");
    } finally {
      setLoading(false);
    }
  }, [from, to, limit, kinds, userId, search]);

  // Chỉ nạp lần đầu, sau đó chờ bấm Áp dụng: ô tìm kiếm quét không index, gọi
  // lại mỗi ký tự sẽ là một lượt scan collection cho mỗi phím.
  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const toggleKind = (kind: CoachContentKind) =>
    setKinds((prev) =>
      prev.includes(kind) ? prev.filter((k) => k !== kind) : [...prev, kind],
    );

  const counts = useMemo(() => {
    const map = new Map<CoachContentKind, number>();
    for (const row of page?.rows ?? []) {
      map.set(row.kind, (map.get(row.kind) ?? 0) + 1);
    }
    return map;
  }, [page]);

  return (
    <div className="space-y-5 p-6">
      <div>
        <h1 className="text-2xl font-semibold">Nội dung người dùng viết</h1>
        <p className="mt-1 text-sm text-gray-500">
          Sáu loại chữ do chính user gõ vào Coach. <b>Không có hội thoại đầy
          đủ</b> — Coach không lưu những gì nó nói, và đó là thiết kế chứ không
          phải thiếu sót: phiên đóng là mọi câu qua lại biến mất, chỉ bốn thứ
          user chủ động để lại thì còn.
        </p>
      </div>

      {error && <Alert severity="error">{error}</Alert>}

      <Paper className="space-y-4 p-4">
        <div className="flex flex-wrap items-end gap-3">
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
          <TextField
            size="small"
            label="User ID"
            placeholder="Bỏ trống = mọi user"
            value={userId}
            onChange={(e) => setUserId(e.target.value)}
          />
          <TextField
            size="small"
            label="Tìm trong chữ user viết"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") load();
            }}
          />
          <TextField
            size="small"
            select
            label="Số dòng mỗi nguồn"
            value={limit}
            onChange={(e) => setLimit(Number(e.target.value))}
            sx={{ minWidth: 150 }}
          >
            {LIMIT_OPTIONS.map((option) => (
              <MenuItem key={option} value={option}>
                {option}
              </MenuItem>
            ))}
          </TextField>
          <Button variant="contained" onClick={load} disabled={loading}>
            {loading ? "Đang tải…" : "Áp dụng"}
          </Button>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <span className="text-xs font-medium text-slate-500">Loại:</span>
          {KIND_ORDER.map((kind) => {
            const active = kinds.includes(kind);
            return (
              <button
                key={kind}
                type="button"
                title={KIND_META[kind].hint}
                onClick={() => toggleKind(kind)}
                className={`rounded-full border px-3 py-1 text-xs transition ${
                  active
                    ? "border-teal-600 bg-teal-600 text-white"
                    : "border-slate-200 bg-white text-slate-600 hover:bg-slate-50"
                }`}
              >
                {KIND_META[kind].label}
                {counts.get(kind) ? ` · ${counts.get(kind)}` : ""}
              </button>
            );
          })}
          {kinds.length > 0 && (
            <Button size="small" onClick={() => setKinds([])}>
              Bỏ lọc
            </Button>
          )}
        </div>
      </Paper>

      {page?.truncated && (
        <Alert severity="warning">
          Đã chạm trần {page.limit} dòng mỗi nguồn nên danh sách bị cắt — còn dữ
          liệu chưa hiện. Thu hẹp khoảng ngày, lọc theo loại, hoặc tăng số dòng.
        </Alert>
      )}

      <Paper>
        {loading ? (
          <div className="flex justify-center p-10">
            <CircularProgress />
          </div>
        ) : (page?.rows?.length ?? 0) === 0 ? (
          <div className="p-10 text-center text-sm text-gray-500">
            Không có dòng nào trong khoảng này.
          </div>
        ) : (
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell width={150}>Loại</TableCell>
                <TableCell>Nội dung</TableCell>
                <TableCell width={170}>User</TableCell>
                <TableCell width={160}>Lúc</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {page!.rows.map((row) => (
                <TableRow key={row.id} hover>
                  <TableCell>
                    <Chip
                      size="small"
                      variant="outlined"
                      label={KIND_META[row.kind]?.label ?? row.kind}
                      className={KIND_META[row.kind]?.color}
                    />
                  </TableCell>
                  <TableCell>
                    {/* Nguyên văn, không rút gọn: rút gọn chữ của người ta là
                        cách nhanh nhất để đọc sai ý họ. */}
                    <div className="whitespace-pre-wrap text-sm text-slate-800">
                      {row.content}
                    </div>
                    {formatMeta(row) && (
                      <div className="mt-1 text-xs text-slate-400">
                        {formatMeta(row)}
                      </div>
                    )}
                  </TableCell>
                  <TableCell>
                    <span className="font-mono text-xs text-slate-500">
                      {row.userId}
                    </span>
                  </TableCell>
                  <TableCell>
                    <span className="text-xs text-slate-500">
                      {new Date(row.createdAt).toLocaleString()}
                    </span>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Paper>

      <p className="text-xs text-slate-400">
        {page ? `${page.rows.length} dòng đang hiện` : ""}
      </p>
    </div>
  );
};

export default CoachContentList;
