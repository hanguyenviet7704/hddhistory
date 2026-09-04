import React, { useCallback, useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Alert,
  Button,
  Chip,
  CircularProgress,
  MenuItem,
  Paper,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Tabs,
  TextField,
} from "@mui/material";

import { coachService } from "../../services/coachService";
import {
  CoachContentKind,
  CoachContentPage,
  CoachContentUserPage,
} from "../../types/interface/coach.interface";
import {
  dateInput,
  formatMeta,
  KIND_META,
  KIND_ORDER,
  situationPrompt,
} from "../../utils/coachContentKinds";

const LIMIT_OPTIONS = [50, 100, 200, 500];

/** Hai cách đọc cùng một tập dữ liệu, cùng một bộ lọc. */
type View = "feed" | "users";

const CoachContentList: React.FC = () => {
  const navigate = useNavigate();

  const [view, setView] = useState<View>("feed");
  const [page, setPage] = useState<CoachContentPage | null>(null);
  const [users, setUsers] = useState<CoachContentUserPage | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [kinds, setKinds] = useState<CoachContentKind[]>([]);
  const [from, setFrom] = useState(dateInput(29));
  const [to, setTo] = useState(dateInput());
  const [userId, setUserId] = useState("");
  const [search, setSearch] = useState("");
  const [limit, setLimit] = useState(200);

  const load = useCallback(
    async (which: View) => {
      setLoading(true);
      setError(null);
      const params = {
        from,
        to,
        limit,
        ...(kinds.length ? { kinds } : {}),
        ...(search.trim() ? { search: search.trim() } : {}),
      };
      try {
        if (which === "users") {
          // Lọc theo user ID không đi cùng bảng theo user: nó sẽ biến danh
          // sách thành một dòng, mà muốn xem một người thì đã có trang riêng.
          const res = await coachService.getContentUsers(params);
          setUsers(res?.data ?? null);
        } else {
          const res = await coachService.getContents({
            ...params,
            ...(userId.trim() ? { userId: userId.trim() } : {}),
          });
          setPage(res?.data ?? null);
        }
      } catch (err: any) {
        setError(err?.response?.data?.message ?? "Không tải được nội dung");
      } finally {
        setLoading(false);
      }
    },
    [from, to, limit, kinds, userId, search],
  );

  // Chỉ nạp lần đầu, sau đó chờ bấm Áp dụng: ô tìm kiếm quét không index, gọi
  // lại mỗi ký tự sẽ là một lượt scan collection cho mỗi phím.
  useEffect(() => {
    load("feed");
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Đổi tab thì nạp ngay: tab là một câu hỏi khác về cùng khoảng thời gian,
  // không phải một bộ lọc đang chờ xác nhận.
  const switchView = (next: View) => {
    setView(next);
    load(next);
  };

  const toggleKind = (kind: CoachContentKind) =>
    setKinds((prev) =>
      prev.includes(kind) ? prev.filter((k) => k !== kind) : [...prev, kind],
    );

  const counts = useMemo(() => {
    const map = new Map<CoachContentKind, number>();
    if (view === "users") {
      for (const row of users?.rows ?? []) {
        for (const kind of KIND_ORDER) {
          const seen = row.byKind?.[kind] ?? 0;
          if (seen) map.set(kind, (map.get(kind) ?? 0) + seen);
        }
      }
      return map;
    }
    for (const row of page?.rows ?? []) {
      map.set(row.kind, (map.get(row.kind) ?? 0) + 1);
    }
    return map;
  }, [page, users, view]);

  return (
    <div className="space-y-5 p-6">
      <div>
        <h1 className="text-2xl font-semibold">Nội dung người dùng viết</h1>
        <p className="mt-1 text-sm text-gray-500">
          Sáu loại chữ do chính user gõ vào Coach. <b>Không có hội thoại đầy
          đủ</b> — lời Coach nói chỉ sống trong phiên và bị xoá sau 48h, đó là
          thiết kế chứ không phải thiếu sót. Riêng câu hỏi tình huống là chữ
          của biên tập viên nên còn lâu dài: dòng trả lời nào cũng hiện kèm
          câu hỏi nó đang trả lời.
        </p>
      </div>

      {error && <Alert severity="error">{error}</Alert>}

      <Paper>
        <Tabs
          value={view}
          onChange={(_, next: View) => switchView(next)}
          className="border-b border-slate-200"
        >
          <Tab value="feed" label="Theo dòng thời gian" />
          <Tab value="users" label="Theo user" />
        </Tabs>
      </Paper>

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
          {view === "feed" && (
            <TextField
              size="small"
              label="User ID"
              placeholder="Bỏ trống = mọi user"
              value={userId}
              onChange={(e) => setUserId(e.target.value)}
            />
          )}
          <TextField
            size="small"
            label="Tìm trong chữ user viết"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") load(view);
            }}
          />
          <TextField
            size="small"
            select
            label={view === "users" ? "Số user tối đa" : "Số dòng mỗi nguồn"}
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
          <Button
            variant="contained"
            onClick={() => load(view)}
            disabled={loading}
          >
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

        {/* Dịp nằm trên phiên chứ không có bảng riêng, mà phiên thì Mongo xoá
            sau 48h. Không nói ra thì "0 dịp" bị đọc thành "user không có dịp
            nào", trong khi sự thật là dữ liệu đã bị xoá. */}
        <p className="text-xs text-slate-400">
          Loại <b>Dịp</b> đọc từ phiên Coach nên chỉ có dữ liệu trong 48h gần
          nhất — cũ hơn là đã bị xoá, không phải user không viết.
        </p>
      </Paper>

      {view === "feed" && page?.truncated && (
        <Alert severity="warning">
          Đã chạm trần {page.limit} dòng mỗi nguồn nên danh sách bị cắt — còn dữ
          liệu chưa hiện. Thu hẹp khoảng ngày, lọc theo loại, hoặc tăng số dòng.
        </Alert>
      )}

      {view === "users" && users?.truncated && (
        <Alert severity="warning">
          Còn {users.total - users.rows.length} user nữa chưa hiện — tăng số
          dòng hoặc thu hẹp khoảng ngày.
        </Alert>
      )}

      <Paper>
        {loading ? (
          <div className="flex justify-center p-10">
            <CircularProgress />
          </div>
        ) : view === "users" ? (
          (users?.rows?.length ?? 0) === 0 ? (
            <div className="p-10 text-center text-sm text-gray-500">
              Không user nào viết gì trong khoảng này.
            </div>
          ) : (
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>User</TableCell>
                  <TableCell width={90} align="right">
                    Số dòng
                  </TableCell>
                  <TableCell>Đã viết những loại nào</TableCell>
                  <TableCell width={170}>Lần cuối viết</TableCell>
                  <TableCell width={170}>Lần đầu viết</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {users!.rows.map((row) => (
                  <TableRow
                    key={row.userId}
                    hover
                    className="cursor-pointer"
                    onClick={() =>
                      navigate(`/coach-contents/users/${row.userId}`, {
                        // Trang kia mở đúng khoảng đang xem, chứ không nhảy về
                        // mặc định 30 ngày và làm người đọc mất chỗ.
                        state: { from, to },
                      })
                    }
                  >
                    <TableCell>
                      <div className="text-sm text-slate-800">
                        {row.name || (row.anonymous ? "Khách" : "—")}
                      </div>
                      <div className="text-xs text-slate-400">
                        {row.email || "không có email"}
                      </div>
                      <div className="font-mono text-xs text-slate-400">
                        {row.userId}
                      </div>
                    </TableCell>
                    <TableCell align="right">
                      <span className="text-sm font-medium text-slate-700">
                        {row.total}
                      </span>
                    </TableCell>
                    <TableCell>
                      <div className="flex flex-wrap gap-1">
                        {KIND_ORDER.filter((kind) => row.byKind?.[kind]).map(
                          (kind) => (
                            <Chip
                              key={kind}
                              size="small"
                              variant="outlined"
                              title={KIND_META[kind].hint}
                              label={`${KIND_META[kind].label} · ${row.byKind[kind]}`}
                              className={KIND_META[kind].color}
                            />
                          ),
                        )}
                      </div>
                    </TableCell>
                    <TableCell>
                      <span className="text-xs text-slate-500">
                        {new Date(row.lastAt).toLocaleString()}
                      </span>
                    </TableCell>
                    <TableCell>
                      <span className="text-xs text-slate-400">
                        {new Date(row.firstAt).toLocaleString()}
                      </span>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )
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
                    {/* Câu hỏi đứng trên câu trả lời, nhạt hơn: đọc một câu
                        trả lời mà không thấy câu hỏi là đọc trượt. */}
                    {situationPrompt(row) && (
                      <div className="mb-1 border-l-2 border-slate-200 pl-2 text-xs italic text-slate-500">
                        {situationPrompt(row)}
                      </div>
                    )}
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
                    <button
                      type="button"
                      title="Xem dòng thời gian của user này"
                      onClick={() =>
                        navigate(`/coach-contents/users/${row.userId}`, {
                          state: { from, to },
                        })
                      }
                      className="font-mono text-xs text-teal-700 underline-offset-2 hover:underline"
                    >
                      {row.userId}
                    </button>
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
        {view === "users"
          ? users
            ? `${users.rows.length} user đang hiện`
            : ""
          : page
            ? `${page.rows.length} dòng đang hiện`
            : ""}
      </p>
    </div>
  );
};

export default CoachContentList;
