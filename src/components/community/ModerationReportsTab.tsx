import React, { useCallback, useEffect, useState } from "react";
import { Button, MenuItem, Pagination, Skeleton, TextField } from "@mui/material";
import { CheckIcon, EyeOffIcon } from "lucide-react";

import { communityService } from "../../services/communityService";
import {
  CommunityReportReason,
  CommunityReportStatus,
  CommunityTargetType,
  ICommunityReport,
} from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import CommunityContentCard from "./CommunityContentCard";

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

      <div className="space-y-3">
        {loading &&
          Array.from({ length: 3 }).map((_, index) => (
            <Skeleton key={index} variant="rounded" height={172} />
          ))}

        {!loading && !reports.length && (
          <div className="rounded-2xl border border-dashed border-gray-300 py-12 text-center text-sm text-gray-500">
            {status === CommunityReportStatus.PENDING
              ? "Không còn báo cáo nào chờ xử lý."
              : "Chưa có báo cáo nào ở trạng thái này."}
          </div>
        )}

        {!loading &&
          reports.map((report) => {
            // The author deleted it before a moderator got here. The report is
            // still worth showing as history, just with nothing left to act on.
            if (!report.target) {
              return (
                <div
                  key={report.id}
                  className="rounded-2xl border border-gray-200 bg-gray-50 p-4 text-sm text-gray-500"
                >
                  Nội dung không còn tồn tại · báo cáo vì{" "}
                  {REASON_LABELS[report.reason] ?? report.reason} ·{" "}
                  {report.reporter?.name || "(tài khoản đã xoá)"}
                </div>
              );
            }

            return (
              <CommunityContentCard
                key={report.id}
                author={report.target.author}
                createdAt={report.createdAt}
                status={report.target.status}
                body={report.target.body}
                reportCount={report.target.reportCount}
                // The verdict a moderator is being asked for is about the
                // CONTENT, so the content is the card and the accusation sits
                // above it — the reason and who said it, in one strip, instead
                // of three columns to look across.
                banner={
                  <div className="mb-3 flex flex-wrap items-center gap-x-3 gap-y-1 rounded-xl bg-red-50 px-3 py-2 text-xs text-red-800">
                    <span className="font-semibold">
                      {report.targetType === CommunityTargetType.POST
                        ? "Bài đăng"
                        : "Bình luận"}{" "}
                      · {REASON_LABELS[report.reason] ?? report.reason}
                    </span>
                    <span className="text-red-700/80">
                      Người báo: {report.reporter?.name || "(tài khoản đã xoá)"}
                    </span>
                    {!!report.note && (
                      <span className="italic text-red-700/80">
                        “{report.note}”
                      </span>
                    )}
                  </div>
                }
                note={
                  report.target.hiddenByReports ? (
                    <span className="text-red-700">
                      Đã tự ẩn do đủ {report.target.reportCount} báo cáo — chờ
                      bạn xác nhận
                    </span>
                  ) : null
                }
                actions={
                  report.status === CommunityReportStatus.PENDING ? (
                    <>
                      <Button
                        size="small"
                        startIcon={<CheckIcon size={15} />}
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
                      <Button
                        size="small"
                        variant="outlined"
                        color="warning"
                        startIcon={<EyeOffIcon size={15} />}
                        disabled={saving}
                        onClick={() =>
                          resolve(report, CommunityReportStatus.RESOLVED_HIDDEN)
                        }
                      >
                        Ẩn nội dung
                      </Button>
                    </>
                  ) : (
                    <span className="text-xs text-gray-500">Đã xử lý</span>
                  )
                }
              />
            );
          })}
      </div>

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
