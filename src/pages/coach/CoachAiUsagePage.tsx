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

/**
 * Mã lỗi dịch ra thứ nói được nên làm gì.
 *
 * Mỗi nhãn nói NGUYÊN NHÂN, không nói triệu chứng: người mở trang này đang tìm
 * việc phải làm, và "429" tự nó không bảo được là đi nạp tiền hay đi chờ.
 * Mã lạ thì hiện nguyên xi — bảng tra thiếu một dòng còn hơn nuốt mất mã mà
 * Google vừa nghĩ ra.
 */
const ERROR_LABEL: Record<string, string> = {
  "429": "429 — hết hạn mức hoặc hết credit Gemini",
  "503": "503 — model đang quá tải",
  "500": "500 — lỗi phía Google",
  "400": "400 — mình gửi sai",
  timeout: "Quá giờ — chạm trần thời gian của lượt",
  network: "Không nối được tới provider",
  budget_spent: "Hết ngân sách thời gian của lượt trước khi kịp gọi",
  blocked: "Prompt bị provider chặn",
  max_tokens: "Cụt giữa chừng vì chạm trần token (vẫn bị tính tiền)",
  no_text: "Trả về không có phần chữ nào",
  malformed: "JSON hỏng, không đọc được",
  no_key: "Chưa cấu hình GEMINI_API_KEY",
};

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

/**
 * Mili-giây, hoặc "—" khi api chưa trả.
 *
 * Không rơi về 0: admin có thể lên trước api, và "0 ms" sẽ đọc ra là "nhanh
 * lắm" đúng ở chỗ đáng lẽ phải đọc ra "chưa biết".
 */
const ms = (value?: number): string =>
  typeof value === "number" && value > 0 ? `${compact(value)} ms` : "—";

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
        <TableCell align="right">Trễ TB</TableCell>
        <TableCell align="right">Trễ max</TableCell>
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
          {/* Em dash chứ không phải 0 khi api chưa trả: "chưa đo" và "0ms"
              là hai chuyện khác hẳn nhau. */}
          <TableCell align="right">{ms(row.avgLatencyMs)}</TableCell>
          <TableCell align="right">{ms(row.maxLatencyMs)}</TableCell>
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
              <b>{compact(totals!.failedCalls)} lệnh gọi không trả lời được</b> —
              mỗi cái là một người đọc nhìn ba chấm rồi không nhận được gì, vì
              mọi lỗi của provider đều thành câu rỗng. Bảng bên dưới nói vì sao.
            </Alert>
          )}

          {(summary.errors ?? []).length > 0 && (
            <Paper className="p-4">
              <h2 className="mb-1 text-base font-semibold">Hỏng vì cái gì</h2>
              {/* Nằm riêng khỏi phần tiền: phần lớn những lỗi này KHÔNG tốn
                  đồng nào — 503 bị từ chối trước khi tiêu một token — nên ai
                  dò cột "Tiền" sẽ không bao giờ tìm thấy chúng. */}
              <p className="mb-3 text-xs text-slate-500">
                Phần lớn không tốn tiền, nên không xuất hiện ở bảng nào phía
                trên. 429 là hết hạn mức hoặc hết credit; 503 là model đang
                đầy; timeout là chạm trần thời gian của lượt.
              </p>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Lỗi</TableCell>
                    <TableCell align="right">Số lần</TableCell>
                    <TableCell>Đánh trúng bước</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {summary.errors!.map((row) => (
                    <TableRow key={row.key} hover>
                      <TableCell>
                        <span className="font-medium text-amber-700">
                          {ERROR_LABEL[row.key] ?? row.key}
                        </span>
                      </TableCell>
                      <TableCell align="right">{compact(row.calls)}</TableCell>
                      <TableCell className="text-slate-600">
                        {(row.kinds ?? [])
                          .map((kind) => KIND_LABEL[kind] ?? kind)
                          .join(", ") || "—"}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </Paper>
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
