import React, { useCallback, useEffect, useState } from "react";
import {
  Alert,
  Button,
  Chip,
  CircularProgress,
  FormControlLabel,
  Paper,
  Switch,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
} from "@mui/material";

import { coachService } from "../../services/coachService";
import {
  CoachRating,
  CoachRatingChip,
} from "../../types/interface/coach.interface";
import { useNotification } from "../../utils/hooks/useNotification";

/** The closed list of reasons a thumb-down can carry, spelled out for a reader. */
const CHIP_LABEL: Record<CoachRatingChip, string> = {
  imposed_thinking: "Áp đặt suy nghĩ",
  felt_judged: "Thấy bị phán xét",
  missed_the_point: "Không hiểu đúng ý",
  pushed_too_hard: "Thúc ép quá",
};

const CoachRatingList: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [rows, setRows] = useState<CoachRating[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [openOnly, setOpenOnly] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await coachService.getRatings({ needsReview: openOnly });
      setRows(Array.isArray(res?.data) ? res.data : []);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được danh sách");
    } finally {
      setLoading(false);
    }
  }, [openOnly]);

  useEffect(() => {
    load();
  }, [load]);

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
          Chỉ hỏi sau kịch bản Long, và bỏ qua ba lần thì ẩn hẳn với người đó.
          Mọi lượt chê đều vào đây, không lấy mẫu — số lượng đủ nhỏ để một người
          đọc hết, và đọc hết chính là lý do hàng đợi này tồn tại.
        </p>
      </div>

      {error && <Alert severity="error">{error}</Alert>}

      <Paper className="p-4 flex items-center gap-4">
        <FormControlLabel
          control={
            <Switch
              checked={openOnly}
              onChange={(e) => setOpenOnly(e.target.checked)}
            />
          }
          label="Chỉ hiện chưa xử lý"
        />
        <span className="text-sm text-gray-500 ml-auto">{rows.length} dòng</span>
      </Paper>

      <Paper>
        {loading ? (
          <div className="flex justify-center p-10">
            <CircularProgress />
          </div>
        ) : rows.length === 0 ? (
          <p className="p-10 text-center text-gray-400 italic">
            {openOnly
              ? "Hàng đợi trống — không có lượt chê nào đang chờ."
              : "Chưa có đánh giá nào."}
          </p>
        ) : (
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell width={170}>Thời điểm</TableCell>
                <TableCell width={90}>Đánh giá</TableCell>
                <TableCell>Lý do</TableCell>
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
                      label={row.thumb === "up" ? "Ổn" : "Chưa ổn"}
                      color={row.thumb === "up" ? "success" : "error"}
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
                          />
                        ))}
                      </div>
                    ) : (
                      <span className="text-gray-400 text-sm">—</span>
                    )}
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
