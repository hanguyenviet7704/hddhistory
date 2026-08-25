import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  Chip,
  MenuItem,
  Pagination,
  Paper,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
} from "@mui/material";
import { CheckIcon, EyeOffIcon } from "lucide-react";

import { communityService } from "../../services/communityService";
import {
  CommunityReportReason,
  CommunityReportStatus,
  CommunityTargetType,
  ICommunityReport,
} from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import CommunityStatusChip from "./CommunityStatusChip";

const TAKE = 20;

const REASON_LABELS: Record<CommunityReportReason, string> = {
  [CommunityReportReason.SPAM]: "Spam / rao bán",
  [CommunityReportReason.HARASSMENT]: "Quấy rối, xúc phạm",
  [CommunityReportReason.ADULT]: "Nội dung 18+",
  [CommunityReportReason.MISINFORMATION]: "Thông tin sai",
  [CommunityReportReason.PRIVACY]: "Tiết lộ danh tính người khác",
  [CommunityReportReason.OTHER]: "Khác",
};

const ModerationReportsTab: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [reports, setReports] = useState<ICommunityReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [status, setStatus] = useState<CommunityReportStatus>(
    CommunityReportStatus.PENDING
  );
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await communityService.getReports({
        page,
        take: TAKE,
        status,
      });
      setReports(res?.items ?? []);
      setTotalPages(res?.totalPages || 1);
    } catch (err: any) {
      setError(
        err?.response?.data?.message ?? "Không tải được hàng đợi báo cáo"
      );
    } finally {
      setLoading(false);
    }
  }, [page, status]);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => {
    setPage(1);
  }, [status]);

  const resolve = async (
    report: ICommunityReport,
    next: CommunityReportStatus
  ) => {
    setSaving(true);
    try {
      await communityService.resolveReport(report.id, next);
      showSuccess(
        next === CommunityReportStatus.RESOLVED_HIDDEN
          ? "Đã ẩn nội dung và đóng báo cáo"
          : "Đã bỏ qua báo cáo"
      );
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Không xử lý được báo cáo");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <TextField
          select
          size="small"
          label="Trạng thái"
          value={status}
          onChange={(event) =>
            setStatus(event.target.value as CommunityReportStatus)
          }
          className="min-w-[200px]"
        >
          <MenuItem value={CommunityReportStatus.PENDING}>Chờ xử lý</MenuItem>
          <MenuItem value={CommunityReportStatus.RESOLVED_HIDDEN}>
            Đã ẩn nội dung
          </MenuItem>
          <MenuItem value={CommunityReportStatus.RESOLVED_KEPT}>
            Đã bỏ qua
          </MenuItem>
        </TextField>
        <p className="text-xs text-gray-500">
          Cộng đồng hậu kiểm: bài bị báo cáo vẫn hiện cho tới khi có người xử lý
          ở đây.
        </p>
      </div>

      {error && (
        <div className="rounded-md bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      <TableContainer component={Paper}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Nội dung bị báo cáo</TableCell>
              <TableCell>Loại</TableCell>
              <TableCell>Lý do</TableCell>
              <TableCell>Người báo</TableCell>
              <TableCell align="right">Số báo cáo</TableCell>
              <TableCell align="right">Hành động</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading &&
              Array.from({ length: 5 }).map((_, index) => (
                <TableRow key={index}>
                  <TableCell colSpan={6}>
                    <Skeleton height={28} />
                  </TableCell>
                </TableRow>
              ))}

            {!loading && !reports.length && (
              <TableRow>
                <TableCell colSpan={6}>
                  <div className="py-8 text-center text-sm text-gray-500">
                    {status === CommunityReportStatus.PENDING
                      ? "Không còn báo cáo nào chờ xử lý."
                      : "Chưa có báo cáo nào ở trạng thái này."}
                  </div>
                </TableCell>
              </TableRow>
            )}

            {!loading &&
              reports.map((report) => (
                <TableRow key={report.id} hover>
                  <TableCell className="max-w-md">
                    {report.target ? (
                      <>
                        <div className="line-clamp-3 whitespace-pre-wrap text-sm">
                          {report.target.body}
                        </div>
                        <div className="mt-1 flex items-center gap-2 text-xs text-gray-500">
                          <span>
                            {report.target.author?.name || "(tài khoản đã xoá)"}
                          </span>
                          <CommunityStatusChip status={report.target.status} />
                        </div>
                        {report.target.hiddenByReports && (
                          <div className="mt-1 text-xs text-red-700">
                            Đã tự ẩn do đủ {report.target.reportCount} báo cáo —
                            chờ bạn xác nhận
                          </div>
                        )}
                      </>
                    ) : (
                      // The author deleted it before a moderator got here.
                      <span className="text-sm text-gray-500">
                        Nội dung không còn tồn tại
                      </span>
                    )}
                    {report.note && (
                      <div className="mt-1 text-xs italic text-gray-600">
                        “{report.note}”
                      </div>
                    )}
                  </TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      label={
                        report.targetType === CommunityTargetType.POST
                          ? "Bài đăng"
                          : "Bình luận"
                      }
                    />
                  </TableCell>
                  <TableCell className="text-sm">
                    {REASON_LABELS[report.reason] ?? report.reason}
                  </TableCell>
                  <TableCell>
                    <div className="text-sm">
                      {report.reporter?.name || "(tài khoản đã xoá)"}
                    </div>
                    <div className="text-xs text-gray-500">
                      {new Date(report.createdAt).toLocaleString("vi-VN")}
                    </div>
                  </TableCell>
                  <TableCell align="right">
                    <span className="font-semibold text-red-600">
                      {report.target?.reportCount ?? 1}
                    </span>
                  </TableCell>
                  <TableCell align="right">
                    {report.status === CommunityReportStatus.PENDING ? (
                      <div className="flex justify-end gap-1">
                        <Button
                          size="small"
                          color="warning"
                          startIcon={<EyeOffIcon size={14} />}
                          disabled={saving || !report.target}
                          onClick={() =>
                            resolve(
                              report,
                              CommunityReportStatus.RESOLVED_HIDDEN
                            )
                          }
                        >
                          Ẩn
                        </Button>
                        <Button
                          size="small"
                          startIcon={<CheckIcon size={14} />}
                          disabled={saving}
                          onClick={() =>
                            resolve(report, CommunityReportStatus.RESOLVED_KEPT)
                          }
                        >
                          {/* An auto-hidden item comes BACK when kept, so the
                              button has to promise that and not "ignore". */}
                          {report.target?.hiddenByReports
                            ? "Giữ lại (hiện lại)"
                            : "Bỏ qua"}
                        </Button>
                      </div>
                    ) : (
                      <span className="text-xs text-gray-500">Đã xử lý</span>
                    )}
                  </TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
      </TableContainer>

      {totalPages > 1 && (
        <div className="flex justify-end">
          <Pagination
            page={page}
            count={totalPages}
            onChange={(_, next) => setPage(next)}
          />
        </div>
      )}
    </div>
  );
};

export default ModerationReportsTab;
