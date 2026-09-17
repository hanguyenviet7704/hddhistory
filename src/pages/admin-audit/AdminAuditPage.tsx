import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  Alert,
  Button,
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

import { adminAuditService } from "../../services/adminAuditService";
import {
  AdminAuditChange,
  AdminAuditDetail,
  AdminAuditPage as AdminAuditPageData,
  AdminAuditQuery,
  AdminAuditRow,
} from "../../types/interface/adminAudit.interface";

/**
 * Đường dẫn → tên khu vực người đọc nhận ra.
 *
 * Bảng tra sống ở ĐÂY chứ không ở API, và có chủ ý: nhật ký phải lưu đường dẫn
 * THẬT — đó là sự thật về thứ đã xảy ra, và nó không được đổi nghĩa khi ai đó
 * đổi tên một mục menu. Cái tên là chuyện trình bày, nên nó ở chỗ trình bày,
 * và sửa nó không cần deploy API.
 *
 * Khớp theo mảnh, dài trước ngắn sau. Không khớp thì hiện nguyên đường dẫn —
 * một dòng nhật ký lạ vẫn phải đọc được, chứ không được rơi vào "Khác".
 */
const SECTION_LABELS: Array<[string, string]> = [
  ["/paywall-config", "Cấu hình paywall"],
  ["/coach-config", "Cấu hình Coach"],
  ["/coach-situations", "Coach · tình huống"],
  ["/coach-content", "Coach · nội dung"],
  ["/onboarding-config", "Cấu hình onboarding"],
  ["/streak-config", "Cấu hình chuỗi ngày"],
  ["/home-banner", "Banner trang chủ"],
  ["/home-popup", "Popup trang chủ"],
  ["/notification", "Thông báo đẩy"],
  ["/segment", "Nhóm người dùng"],
  ["/deeplink", "Deeplink"],
  ["/download-link", "Link tải app"],
  ["/study-theme", "Chủ đề nền"],
  ["/habit", "Thói quen"],
  ["/community", "Cộng đồng"],
  ["/voiceover", "Lồng tiếng"],
  ["/courses", "Khoá học"],
  ["/lesson", "Bài học"],
  ["/keypoint", "Keypoint"],
  ["/skillset", "Skillset"],
  ["/import", "Nhập nội dung"],
  ["/users", "Người dùng"],
  ["/payment", "Thanh toán"],
];

function sectionOf(path: string): string {
  const hit = SECTION_LABELS.find(([fragment]) => path.includes(fragment));
  return hit ? hit[1] : path;
}

/** Thao tác, nói bằng tiếng người thay vì bằng động từ HTTP. */
const METHOD_LABELS: Record<string, string> = {
  POST: "Tạo / đăng",
  PUT: "Cập nhật",
  PATCH: "Sửa",
  DELETE: "Xoá",
};

const dateInput = (daysAgo = 0) => {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  return date.toISOString().slice(0, 10);
};

const timeOf = (iso: string) => {
  if (!iso) return "—";
  const d = new Date(iso);
  return Number.isNaN(d.getTime())
    ? "—"
    : d.toLocaleString("vi-VN", { hour12: false });
};

/** Thân request, in cho dễ đọc. Không parse được thì hiện nguyên văn. */
function prettyBody(raw: string): string {
  if (!raw) return "";
  try {
    return JSON.stringify(JSON.parse(raw), null, 2);
  } catch {
    return raw;
  }
}

/**
 * Một giá trị, viết ra cho người đọc chứ không cho lập trình viên.
 *
 * `true`/`false` là thứ hay gặp nhất trong các trang cấu hình, và "true" thì
 * biên tập viên phải dịch trong đầu; "Bật" thì không.
 */
function readable(value: unknown): string {
  if (value === undefined) return "(không có)";
  if (value === null) return "(trống)";
  if (value === true) return "Bật";
  if (value === false) return "Tắt";
  if (value === "") return "(để trống)";
  if (Array.isArray(value) && value.length === 0) return "(danh sách rỗng)";
  if (typeof value === "object") return JSON.stringify(value);
  return String(value);
}

/** Bảng "đã đổi gì" — trường, trước, sau. */
const ChangeTable: React.FC<{ changes: AdminAuditChange[] }> = ({ changes }) => (
  <Table size="small" className="bg-white">
    <TableHead>
      <TableRow>
        <TableCell>Mục</TableCell>
        <TableCell>Trước</TableCell>
        <TableCell>Sau</TableCell>
      </TableRow>
    </TableHead>
    <TableBody>
      {changes.map((change) => (
        <TableRow key={change.field}>
          <TableCell className="font-mono text-[11px] text-slate-700">
            {change.field}
          </TableCell>
          <TableCell className="text-slate-500 line-through">
            {readable(change.before)}
          </TableCell>
          <TableCell className="font-medium text-slate-900">
            {readable(change.after)}
          </TableCell>
        </TableRow>
      ))}
    </TableBody>
  </Table>
);

const Row: React.FC<{ row: AdminAuditRow }> = ({ row }) => {
  const [open, setOpen] = useState(false);
  const [detail, setDetail] = useState<AdminAuditDetail | null>(null);
  const [loadingDetail, setLoadingDetail] = useState(false);
  const [showRaw, setShowRaw] = useState(false);
  const body = prettyBody(row.body);

  // Nạp khi MỞ, không nạp sẵn: so sánh tốn một truy vấn cho mỗi dòng, mà phần
  // lớn dòng không ai mở ra xem.
  const toggle = async () => {
    const next = !open;
    setOpen(next);
    if (!next || detail || loadingDetail) return;

    setLoadingDetail(true);
    try {
      const res = await adminAuditService.detail(row._id);
      setDetail(res?.data ?? null);
    } catch {
      // Không so được thì vẫn còn nội dung thô bên dưới — không chặn người đọc.
      setDetail(null);
    } finally {
      setLoadingDetail(false);
    }
  };

  return (
    <>
      <TableRow hover className={open ? "bg-slate-50" : undefined}>
        <TableCell className="whitespace-nowrap text-slate-600">
          {timeOf(row.createdAt)}
        </TableCell>
        <TableCell>
          <div className="font-medium text-slate-900">
            {row.actorName || row.actorEmail || row.actorId}
          </div>
          {row.actorName && row.actorEmail && (
            <div className="text-[11px] text-slate-500">{row.actorEmail}</div>
          )}
        </TableCell>
        <TableCell>{METHOD_LABELS[row.method] ?? row.method}</TableCell>
        <TableCell>
          <div className="text-slate-900">{sectionOf(row.path)}</div>
          <div className="text-[11px] text-slate-500 break-all">{row.path}</div>
        </TableCell>
        <TableCell align="center">
          {row.ok ? (
            <span className="text-emerald-700">OK</span>
          ) : (
            // Thao tác hỏng nổi lên: thường đó là thứ người ta mở trang này để tìm.
            <span className="font-medium text-amber-700">
              {row.statusCode || "lỗi"}
            </span>
          )}
        </TableCell>
        <TableCell align="right">
          {body ? (
            <Button size="small" onClick={toggle}>
              {open ? "Ẩn" : "Xem thay đổi"}
            </Button>
          ) : (
            <span className="text-[11px] text-slate-400">không có</span>
          )}
        </TableCell>
      </TableRow>
      {open && (
        <TableRow>
          <TableCell colSpan={6} className="bg-slate-50">
            {!row.ok && row.errorMessage && (
              <p className="mb-2 text-xs text-amber-800">{row.errorMessage}</p>
            )}

            {loadingDetail ? (
              <div className="flex justify-center p-4">
                <CircularProgress size={22} />
              </div>
            ) : detail?.changes === null || detail === null ? (
              // KHÔNG so được — nói rõ vì sao, chứ đừng để người đọc tưởng là
              // "không có gì đổi".
              <p className="mb-2 text-xs text-slate-600">
                Chưa so được với lần trước
                {row.bodyTruncated
                  ? " vì nội dung quá dài nên đã bị cắt."
                  : " — đây là lần đầu khu vực này được ghi nhận."}{" "}
                Bên dưới là toàn bộ nội dung đã gửi lên.
              </p>
            ) : detail.changes.length === 0 ? (
              // Khác hẳn ở trên: so được, và kết quả là không đổi gì.
              <p className="mb-2 text-xs text-slate-600">
                Có bấm lưu nhưng <b>không thay đổi gì</b> so với lần trước
                {detail.previousBy ? ` (${detail.previousBy})` : ""}.
              </p>
            ) : (
              <>
                <p className="mb-2 text-xs text-slate-600">
                  <b>{detail.changes.length} mục thay đổi</b> so với lần lưu
                  trước
                  {detail.previousBy ? ` của ${detail.previousBy}` : ""}
                  {detail.previousAt ? ` lúc ${timeOf(detail.previousAt)}` : ""}.
                </p>
                <ChangeTable changes={detail.changes} />
              </>
            )}

            <Button
              size="small"
              className="mt-2"
              onClick={() => setShowRaw((v) => !v)}
            >
              {showRaw ? "Ẩn nội dung gốc" : "Xem nội dung gốc"}
            </Button>
            {showRaw && (
              <>
                <pre className="mt-2 max-h-96 overflow-auto rounded-lg bg-white p-3 text-[11px] leading-relaxed text-slate-700">
                  {body}
                </pre>
                {row.bodyTruncated && (
                  // Nói thẳng là chưa đủ, chứ không im lặng để người đọc tưởng đủ.
                  <p className="mt-1 text-[11px] text-slate-500">
                    Nội dung đã bị cắt vì quá dài — đây không phải toàn bộ những
                    gì đã gửi lên.
                  </p>
                )}
              </>
            )}
          </TableCell>
        </TableRow>
      )}
    </>
  );
};

const AdminAuditPage: React.FC = () => {
  const [data, setData] = useState<AdminAuditPageData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [from, setFrom] = useState(dateInput(13));
  const [to, setTo] = useState(dateInput());
  const [actorId, setActorId] = useState("");
  const [path, setPath] = useState("");
  const [result, setResult] = useState("");
  const [page, setPage] = useState(1);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const query: AdminAuditQuery = { from, to, page, limit: 50 };
      if (actorId) query.actorId = actorId;
      if (path.trim()) query.path = path.trim();
      if (result) query.result = result as "ok" | "failed";
      const res = await adminAuditService.list(query);
      setData(res?.data ?? null);
    } catch (err: any) {
      setError(
        err?.response?.data?.message ?? "Không tải được nhật ký thao tác",
      );
    } finally {
      setLoading(false);
    }
  }, [from, to, actorId, path, result, page]);

  useEffect(() => {
    load();
  }, [load]);

  const totalPages = useMemo(
    () => (data ? Math.max(1, Math.ceil(data.total / data.limit)) : 1),
    [data],
  );

  return (
    <div className="space-y-4 p-6">
      <div>
        <h1 className="text-xl font-semibold text-slate-900">
          Nhật ký thao tác
        </h1>
        <p className="mt-1 text-sm text-slate-500">
          Ai đã sửa gì trên trang quản trị, lúc nào, và gửi lên nội dung gì.
          Chỉ ghi thao tác GHI của tài khoản admin — lượt truy cập của app
          không nằm ở đây.
        </p>
      </div>

      <Paper className="flex flex-wrap items-end gap-3 p-4">
        <TextField
          label="Từ ngày"
          type="date"
          size="small"
          value={from}
          onChange={(e) => {
            setPage(1);
            setFrom(e.target.value);
          }}
          InputLabelProps={{ shrink: true }}
        />
        <TextField
          label="Đến ngày"
          type="date"
          size="small"
          value={to}
          onChange={(e) => {
            setPage(1);
            setTo(e.target.value);
          }}
          InputLabelProps={{ shrink: true }}
        />
        <TextField
          select
          label="Người thao tác"
          size="small"
          value={actorId}
          onChange={(e) => {
            setPage(1);
            setActorId(e.target.value);
          }}
          sx={{ minWidth: 220 }}
        >
          <MenuItem value="">Tất cả</MenuItem>
          {(data?.actors ?? []).map((actor) => (
            <MenuItem key={actor.id} value={actor.id}>
              {actor.name || actor.email || actor.id}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          label="Khu vực (một phần đường dẫn)"
          size="small"
          placeholder="paywall-config"
          value={path}
          onChange={(e) => {
            setPage(1);
            setPath(e.target.value);
          }}
          sx={{ minWidth: 240 }}
        />
        <TextField
          select
          label="Kết quả"
          size="small"
          value={result}
          onChange={(e) => {
            setPage(1);
            setResult(e.target.value);
          }}
          sx={{ minWidth: 150 }}
        >
          <MenuItem value="">Tất cả</MenuItem>
          <MenuItem value="ok">Thành công</MenuItem>
          <MenuItem value="failed">Hỏng</MenuItem>
        </TextField>
        <Button variant="outlined" onClick={load}>
          Tải lại
        </Button>
      </Paper>

      {error && <Alert severity="error">{error}</Alert>}

      {loading ? (
        <div className="flex justify-center p-10">
          <CircularProgress />
        </div>
      ) : !data ? null : data.items.length === 0 ? (
        <Paper className="p-8 text-center text-sm text-slate-500">
          Không có thao tác nào trong khoảng này. Nhật ký chỉ tính từ lúc tính
          năng được deploy — thao tác trước đó không lưu ở đâu nên không dựng
          lại được.
        </Paper>
      ) : (
        <>
          <Paper className="p-4">
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Lúc</TableCell>
                  <TableCell>Ai</TableCell>
                  <TableCell>Thao tác</TableCell>
                  <TableCell>Khu vực</TableCell>
                  <TableCell align="center">Kết quả</TableCell>
                  <TableCell align="right" />
                </TableRow>
              </TableHead>
              <TableBody>
                {data.items.map((row) => (
                  <Row key={row._id} row={row} />
                ))}
              </TableBody>
            </Table>
          </Paper>

          <div className="flex items-center justify-between text-sm text-slate-600">
            <span>
              {data.total} thao tác · trang {data.page}/{totalPages}
            </span>
            <div className="flex gap-2">
              <Button
                size="small"
                disabled={page <= 1}
                onClick={() => setPage((p) => p - 1)}
              >
                Trước
              </Button>
              <Button
                size="small"
                disabled={page >= totalPages}
                onClick={() => setPage((p) => p + 1)}
              >
                Sau
              </Button>
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default AdminAuditPage;
