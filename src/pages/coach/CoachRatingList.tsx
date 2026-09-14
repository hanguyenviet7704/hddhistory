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
  CoachRating,
  CoachRatingChip,
  CoachRatingSource,
  POSITIVE_RATING_CHIPS,
} from "../../types/interface/coach.interface";
import { useNotification } from "../../utils/hooks/useNotification";

/**
 * Nhãn tiếng Việt của từng chip.
 *
 * Ba chip đầu cùng hai chip cũ (`imposed_thinking`, `too_long`) là bộ đang hiện
 * trên app; phần còn lại chỉ tồn tại trong hàng ghi trước 2026-09-14 và vẫn phải
 * đọc được, nếu không thì lịch sử hoá thành một chuỗi id trần.
 */
const CHIP_LABEL: Record<CoachRatingChip, string> = {
  understood_me: "Hiểu đúng chuyện mình kể",
  right_questions: "Câu hỏi đúng chỗ",
  not_helpful: "Chưa giúp được gì",
  imposed_thinking: "Áp đặt suy nghĩ",
  too_long: "Nói nhiều quá",
  too_many_questions: "Hỏi quá nhiều",
  missed_the_point: "Không hiểu đúng ý",
  too_generic: "Trả lời chung chung",
  voice_mismatch: "Giọng điệu không hợp",
  other: "Khác",
  felt_judged: "Thấy bị phán xét",
  pushed_too_hard: "Thúc ép quá",
};

const isPraise = (chip: CoachRatingChip) => POSITIVE_RATING_CHIPS.includes(chip);

/** Hàng chỉ toàn chip khen và không có chữ tự viết — không cần ai xử lý. */
const isAllPraise = (row: CoachRating) =>
  Boolean(row.chips?.length) &&
  row.chips.every(isPraise) &&
  !row.note?.trim();

type ViewFilter = "all" | "open" | "done";

const VIEWS: { value: ViewFilter; label: string }[] = [
  { value: "all", label: "Tất cả" },
  { value: "open", label: "Chưa xử lý" },
  { value: "done", label: "Đã xử lý" },
];

const SOURCES: { value: "all" | CoachRatingSource; label: string }[] = [
  { value: "all", label: "Mọi nguồn" },
  { value: "exit", label: "Popup lúc thoát" },
  { value: "rating", label: "Toast 👍/👎 (đã bỏ)" },
];

const CoachRatingList: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [rows, setRows] = useState<CoachRating[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Mặc định "Tất cả", KHÔNG phải hàng đợi: lời khen không bao giờ vào hàng đợi,
  // nên mở trang ở chế độ hàng đợi sẽ giấu vĩnh viễn một nửa số câu trả lời.
  const [view, setView] = useState<ViewFilter>("all");
  const [source, setSource] = useState<"all" | CoachRatingSource>("all");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await coachService.getRatings({
        ...(view === "all" ? {} : { needsReview: view === "open" }),
        ...(source === "all" ? {} : { source }),
        ...(from ? { from } : {}),
        ...(to ? { to } : {}),
      });
      setRows(Array.isArray(res?.data) ? res.data : []);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được danh sách");
    } finally {
      setLoading(false);
    }
  }, [view, source, from, to]);

  useEffect(() => {
    load();
  }, [load]);

  const tally = useMemo(() => {
    const praise = rows.filter(isAllPraise).length;

    return { praise, rest: rows.length - praise };
  }, [rows]);

  const markReviewed = async (row: CoachRating) => {
    try {
      await coachService.markRatingReviewed(row._id);
      showSuccess("Đã đánh dấu đọc rồi");
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Thao tác thất bại");
    }
  };

  return (
    <div className="p-6 space-y-5">
      <div>
        <h1 className="text-2xl font-semibold">Đánh giá Coach</h1>
        <p className="text-sm text-gray-500 mt-1">
          Hỏi một lần trên đường ra: user bấm ⟨Đóng⟩ → Coach níu → nếu vẫn đóng
          thì hiện popup chọn chip và viết thêm. Tần suất hỏi chỉnh ở trang{" "}
          <strong>Cấu hình</strong>. Mọi câu trả lời đều vào đây, kể cả lời khen,
          không lấy mẫu — chê mà không có gì để so thì không đọc ra được điều gì.
        </p>
      </div>

      {error && <Alert severity="error">{error}</Alert>}

      <Paper className="p-4 flex flex-wrap items-center gap-3">
        <TextField
          select
          size="small"
          label="Trạng thái"
          value={view}
          onChange={(e) => setView(e.target.value as ViewFilter)}
          className="min-w-[150px]"
        >
          {VIEWS.map((v) => (
            <MenuItem key={v.value} value={v.value}>
              {v.label}
            </MenuItem>
          ))}
        </TextField>

        <TextField
          select
          size="small"
          label="Nguồn"
          value={source}
          onChange={(e) => setSource(e.target.value as "all" | CoachRatingSource)}
          className="min-w-[190px]"
        >
          {SOURCES.map((s) => (
            <MenuItem key={s.value} value={s.value}>
              {s.label}
            </MenuItem>
          ))}
        </TextField>

        <TextField
          type="date"
          size="small"
          label="Từ ngày"
          value={from}
          onChange={(e) => setFrom(e.target.value)}
          InputLabelProps={{ shrink: true }}
        />
        <TextField
          type="date"
          size="small"
          label="Đến ngày"
          value={to}
          onChange={(e) => setTo(e.target.value)}
          InputLabelProps={{ shrink: true }}
        />

        {(from || to || source !== "all" || view !== "all") && (
          <Button
            size="small"
            onClick={() => {
              setView("all");
              setSource("all");
              setFrom("");
              setTo("");
            }}
          >
            Xoá lọc
          </Button>
        )}

        <span className="text-sm text-gray-500 ml-auto">
          {rows.length} dòng — {tally.praise} khen, {tally.rest} cần đọc
        </span>
      </Paper>

      <Paper>
        {loading ? (
          <div className="flex justify-center p-10">
            <CircularProgress />
          </div>
        ) : rows.length === 0 ? (
          <div className="p-10 text-center text-gray-500 space-y-2">
            <p className="italic">Chưa có đánh giá nào khớp bộ lọc.</p>
            <p className="text-xs">
              Trống mà không rõ vì sao thì kiểm ba thứ này trước khi nghi trang
              hỏng: popup còn bật không (trang <strong>Cấu hình</strong>), tần
              suất có đang quá thưa không, và bản app người dùng đang cài đã có
              AI Coach chưa — bản chưa có Coach thì không ai bấm được gì để mà
              ghi vào đây.
            </p>
          </div>
        ) : (
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell width={170}>Thời điểm</TableCell>
                <TableCell width={150}>Nguồn</TableCell>
                <TableCell>Ý kiến</TableCell>
                <TableCell width={220}>User</TableCell>
                <TableCell width={130} />
              </TableRow>
            </TableHead>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={row._id} hover>
                  <TableCell>
                    {row.createdAt
                      ? new Date(row.createdAt).toLocaleString("vi-VN")
                      : "—"}
                  </TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      label={
                        row.source === "rating"
                          ? "Toast (cũ)"
                          : "Popup lúc thoát"
                      }
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell>
                    {row.chips?.length ? (
                      <div className="flex flex-wrap gap-1">
                        {row.chips.map((chip) => (
                          <Chip
                            key={chip}
                            size="small"
                            label={CHIP_LABEL[chip] ?? chip}
                            color={isPraise(chip) ? "success" : "error"}
                            variant="outlined"
                          />
                        ))}
                      </div>
                    ) : (
                      <span className="text-gray-400 text-sm">
                        Không chọn chip nào
                      </span>
                    )}
                    {row.note ? (
                      <p className="mt-1 text-sm text-gray-600 italic">
                        “{row.note}”
                      </p>
                    ) : null}
                  </TableCell>
                  <TableCell>
                    <code className="text-xs">{row.userId}</code>
                  </TableCell>
                  <TableCell>
                    {row.needsReview && (
                      <Button size="small" onClick={() => markReviewed(row)}>
                        Đã đọc
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Paper>
    </div>
  );
};

export default CoachRatingList;
