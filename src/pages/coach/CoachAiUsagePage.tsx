import React, { useCallback, useEffect, useState } from "react";
import {
  Alert,
  Button,
  CircularProgress,
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
  CoachAiUsageGroup,
  CoachAiUsageSummary,
} from "../../types/interface/coach.interface";

/** Tên tiếng Việt cho từng bước của luồng đã gọi AI. */
const KIND_LABEL: Record<string, string> = {
  reflect: "Trả lời hội thoại (T3)",
  draft_two_cols: "Nháp hai cột",
  match_habit: "Đối chiếu ngầm habit",
  closing_line: "Câu chốt",
  generate_situation: "Sinh bối cảnh",
  critique_situation: "Soát bối cảnh vừa sinh",
  classify_question: "Cổng câu hỏi ý nghĩa",
  score_scene: "Chấm cách xử lý cảnh",
  classify_risk: "Cổng an toàn",
  transcribe: "Nhập bằng giọng nói",
};

const vnd = (value: number | null) =>
  value === null ? "—" : `${value.toLocaleString("vi-VN")} ₫`;

const compact = (value: number) => value.toLocaleString("vi-VN");

const dateInput = (daysAgo = 0) => {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  return date.toISOString().slice(0, 10);
};

const StatCard: React.FC<{
  label: string;
  value: string;
  hint?: string;
}> = ({ label, value, hint }) => (
  <Paper className="flex-1 p-4">
    <p className="text-xs uppercase tracking-wide text-slate-500">{label}</p>
    <p className="mt-1 text-2xl font-semibold text-slate-900">{value}</p>
    {hint && <p className="mt-1 text-xs text-slate-400">{hint}</p>}
  </Paper>
);

/** Bảng dùng lại cho cả "theo bước" và "theo model". */
const GroupTable: React.FC<{
  rows: CoachAiUsageGroup[];
  keyLabel: string;
  totalCostVnd: number;
  renderKey?: (key: string) => string;
}> = ({ rows, keyLabel, totalCostVnd, renderKey }) => (
  <Table size="small">
    <TableHead>
      <TableRow>
        <TableCell>{keyLabel}</TableCell>
        <TableCell align="right">Lệnh gọi</TableCell>
        <TableCell align="right">Hỏng</TableCell>
        <TableCell align="right">Token vào</TableCell>
        <TableCell align="right">Token ra</TableCell>
        <TableCell align="right">Tiền</TableCell>
        <TableCell align="right">% tổng</TableCell>
      </TableRow>
    </TableHead>
    <TableBody>
      {rows.map((row) => (
        <TableRow key={row.key} hover>
          <TableCell>{renderKey ? renderKey(row.key) : row.key}</TableCell>
          <TableCell align="right">{compact(row.calls)}</TableCell>
          <TableCell align="right">
            {row.failedCalls > 0 ? (
              // Lệnh hỏng vẫn bị tính tiền, nên nó phải nổi lên — đây là con số
              // mà log thành công/thất bại bình thường không cho thấy.
              <span className="font-medium text-amber-700">
                {compact(row.failedCalls)}
              </span>
            ) : (
              "0"
            )}
          </TableCell>
          <TableCell align="right">{compact(row.inputTokens)}</TableCell>
          <TableCell align="right">{compact(row.outputTokens)}</TableCell>
          <TableCell align="right">{vnd(row.costVnd)}</TableCell>
          <TableCell align="right">
            {totalCostVnd > 0
              ? `${Math.round((row.costVnd / totalCostVnd) * 100)}%`
              : "—"}
          </TableCell>
        </TableRow>
      ))}
    </TableBody>
  </Table>
);

const CoachAiUsagePage: React.FC = () => {
  const [summary, setSummary] = useState<CoachAiUsageSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [from, setFrom] = useState(dateInput(29));
  const [to, setTo] = useState(dateInput());

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await coachService.getAiUsageSummary({ from, to });
      setSummary(res?.data ?? null);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được số liệu");
    } finally {
      setLoading(false);
    }
  }, [from, to]);

  useEffect(() => {
    load();
  }, [load]);

  const totals = summary?.totals;
  // `Math.max(1, ...[])` is 1, which is what keeps the bar widths finite on an
  // empty range instead of dividing by -Infinity.
  const maxDailyCost = Math.max(
    1,
    ...(summary?.daily ?? []).map((row) => row.costVnd),
  );
  const unpriced = (summary?.pricing?.models ?? []).filter((m) => !m.priced);

  return (
    <div className="space-y-5 p-6">
      <div>
        <h1 className="text-2xl font-semibold">Chi phí AI của Coach</h1>
        <p className="mt-1 text-sm text-gray-500">
          Tiền và token của mọi lệnh gọi model mà Coach thực hiện, tách theo bước
          của luồng. Số tiền được chốt ngay lúc ghi theo đơn giá đang áp dụng khi
          đó, nên đổi giá về sau không viết lại quá khứ.
        </p>
      </div>

      {error && <Alert severity="error">{error}</Alert>}

      <Alert severity="info">
        Chỉ tính từ lúc tính năng đo này được deploy. Token của các phiên chạy
        trước đó không lưu ở đâu nên không dựng lại được — một khoảng ngày trống
        trước ngày đó là chưa đo, không phải không tốn tiền.
      </Alert>

      {unpriced.length > 0 && (
        <Alert severity="warning">
          Model chưa có trong bảng giá, đang tạm tính theo giá model hội thoại:{" "}
          <b>{unpriced.map((m) => m.model).join(", ")}</b>. Thường là dấu hiệu
          Google đã đổi alias — cần cập nhật hằng số giá trong code.
        </Alert>
      )}

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
          {loading ? "Đang tải…" : "Xem"}
        </Button>
        {summary && (
          <span className="ml-auto text-xs text-slate-400">
            Tỉ giá đang dùng: 1 USD ={" "}
            {compact(summary.pricing?.usdToVnd ?? 0)} ₫
          </span>
        )}
      </Paper>

      {loading ? (
        <div className="flex justify-center p-10">
          <CircularProgress />
        </div>
      ) : !summary ? null : (
        <>
          <div className="flex flex-wrap gap-4">
            <StatCard
              label="Tổng tiền"
              value={vnd(totals!.costVnd)}
              hint={`${compact(totals!.calls)} lệnh gọi`}
            />
            <StatCard
              label="Tiền mỗi phiên"
              value={vnd(summary.sessions.costPerSessionVnd)}
              hint={`${compact(summary.sessions.count)} phiên trong kỳ`}
            />
            <StatCard
              label="Tiền mỗi user"
              value={vnd(summary.sessions.costPerUserVnd)}
              hint={`${compact(summary.sessions.users)} user có phiên`}
            />
            <StatCard
              label="Token vào / ra"
              value={`${compact(totals!.inputTokens)} / ${compact(
                totals!.outputTokens,
              )}`}
              hint={`trung bình ${compact(totals!.avgLatencyMs)} ms mỗi lệnh`}
            />
          </div>

          {totals!.failedCalls > 0 && (
            <Alert severity="warning">
              {compact(totals!.failedCalls)} lệnh gọi trả về thứ không dùng được
              (bị chặn, thiếu phần text, JSON sai) nhưng <b>vẫn bị tính tiền</b>.
              Tỉ lệ này tăng là lý do các nhánh retry ở T3 tồn tại.
            </Alert>
          )}

          <Paper className="p-4">
            <h2 className="mb-3 text-base font-semibold">Tiền theo bước</h2>
            <GroupTable
              rows={summary.byKind}
              keyLabel="Bước"
              totalCostVnd={totals!.costVnd}
              renderKey={(key) => KIND_LABEL[key] ?? key}
            />
          </Paper>

          <Paper className="p-4">
            <h2 className="mb-3 text-base font-semibold">Tiền theo model</h2>
            <GroupTable
              rows={summary.byModel}
              keyLabel="Model"
              totalCostVnd={totals!.costVnd}
            />
          </Paper>

          <Paper className="p-4">
            <h2 className="mb-3 text-base font-semibold">Theo ngày</h2>
            {(summary.daily ?? []).length === 0 ? (
              <p className="text-sm text-slate-500">Chưa có dữ liệu.</p>
            ) : (
              <div className="space-y-1">
                {summary.daily!.map((row) => (
                  <div key={row.key} className="flex items-center gap-3">
                    <span className="w-24 shrink-0 font-mono text-xs text-slate-500">
                      {row.key}
                    </span>
                    {/* Thanh ngang thay vì thư viện chart: một chuỗi số theo
                        ngày không cần trục, chỉ cần so cao thấp. */}
                    <div className="h-4 flex-1 overflow-hidden rounded bg-slate-100">
                      <div
                        className="h-full rounded bg-teal-500"
                        style={{
                          width: `${Math.max(
                            2,
                            (row.costVnd / maxDailyCost) * 100,
                          )}%`,
                        }}
                      />
                    </div>
                    <span className="w-28 shrink-0 text-right text-xs text-slate-600">
                      {vnd(row.costVnd)}
                    </span>
                    <span className="w-24 shrink-0 text-right text-xs text-slate-400">
                      {compact(row.calls)} lệnh
                    </span>
                  </div>
                ))}
              </div>
            )}
          </Paper>
        </>
      )}
    </div>
  );
};

export default CoachAiUsagePage;
