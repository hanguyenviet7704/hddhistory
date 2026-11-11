import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  Chip,
  Pagination,
  Skeleton,
  TextField,
} from "@mui/material";
import { BanIcon, PlusIcon, RotateCcwIcon } from "lucide-react";

import CommunitySanctionModal from "../../components/community/CommunitySanctionModal";
import CommunityEmpty from "../../components/community/CommunityEmpty";
import CommunityPageHeader from "../../components/community/CommunityPageHeader";
import { communityService } from "../../services/communityService";
import { ICommunitySanction } from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";

const TAKE = 20;

const isActive = (sanction: ICommunitySanction) => {
  if (sanction.revokedAt) return false;
  if (!sanction.mutedUntil) return true;
  return new Date(sanction.mutedUntil).getTime() > Date.now();
};

const CommunitySanctionList: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [sanctions, setSanctions] = useState<ICommunitySanction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [userId, setUserId] = useState("");
  const [modalOpen, setModalOpen] = useState(false);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await communityService.getSanctions({
        page,
        take: TAKE,
        ...(userId.trim() ? { userId: userId.trim() } : {}),
      });
      setSanctions(res?.items ?? []);
      setTotalPages(res?.totalPages || 1);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được danh sách");
    } finally {
      setLoading(false);
    }
  }, [page, userId]);

  useEffect(() => {
    const timer = setTimeout(load, 300);
    return () => clearTimeout(timer);
  }, [load]);

  const handleCreate = async (payload: {
    userId: string;
    mutedUntil?: string;
    reason: string;
  }) => {
    setSaving(true);
    try {
      await communityService.createSanction(payload);
      showSuccess("Đã khoá quyền đăng");
      setModalOpen(false);
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Khoá thất bại");
    } finally {
      setSaving(false);
    }
  };

  const handleRevoke = async (sanction: ICommunitySanction) => {
    try {
      await communityService.revokeSanction(sanction._id);
      showSuccess("Đã mở khoá");
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Mở khoá thất bại");
    }
  };

  return (
    <div className="p-6 space-y-4">
      <CommunityPageHeader
        title="Khoá quyền đăng"
        subtitle="Mỗi lần khoá là một dòng riêng — mở khoá không xoá dòng đó, nên lịch sử vi phạm của một người vẫn đọc được ở đây."
      >
        <TextField
          size="small"
          placeholder="Lọc theo User ID"
          value={userId}
          onChange={(event) => setUserId(event.target.value)}
          className="min-w-[220px]"
        />
        <Button
          variant="contained"
          color="warning"
          startIcon={<PlusIcon size={16} />}
          onClick={() => setModalOpen(true)}
        >
          Khoá người dùng
        </Button>
      </CommunityPageHeader>

      {error && (
        <div className="rounded-md bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      <div className="space-y-2">
        {loading &&
          Array.from({ length: 4 }).map((_, index) => (
            <Skeleton key={index} variant="rounded" height={84} />
          ))}

        {!loading && !sanctions.length && (
          <CommunityEmpty>Chưa khoá ai cả.</CommunityEmpty>
        )}

        {!loading &&
          sanctions.map((sanction) => {
            const active = isActive(sanction);

            return (
              <article
                key={sanction._id}
                className={[
                  "flex flex-wrap items-start gap-4 rounded-[18px] border p-4",
                  // An active mute is the only row anyone can act on, and the
                  // only one that is doing something to a person right now.
                  active
                    ? "border-amber-300 bg-amber-50/50"
                    : "border-gray-200 bg-white",
                ].join(" ")}
              >
                <div
                  className={[
                    "flex h-10 w-10 shrink-0 items-center justify-center rounded-full",
                    active
                      ? "bg-amber-100 text-amber-700"
                      : "bg-gray-100 text-gray-400",
                  ].join(" ")}
                >
                  <BanIcon size={18} />
                </div>

                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <code className="text-xs text-gray-700">
                      {sanction.userId}
                    </code>
                    <Chip
                      size="small"
                      label={
                        sanction.revokedAt
                          ? "Đã mở khoá"
                          : active
                          ? "Đang khoá"
                          : "Đã hết hạn"
                      }
                      color={active ? "warning" : "default"}
                    />
                  </div>
                  <p className="mt-1 text-sm text-gray-700">
                    {sanction.reason}
                  </p>
                  <div className="mt-1 flex flex-wrap items-center gap-x-3 text-xs text-gray-500">
                    <span>
                      Đến khi:{" "}
                      <strong className="font-semibold">
                        {sanction.mutedUntil
                          ? new Date(sanction.mutedUntil).toLocaleString("vi-VN")
                          : "Vĩnh viễn"}
                      </strong>
                    </span>
                    <span>
                      · Khoá lúc{" "}
                      {new Date(sanction.createdAt).toLocaleString("vi-VN")}
                    </span>
                  </div>
                </div>

                {active && (
                  <Button
                    size="small"
                    variant="outlined"
                    startIcon={<RotateCcwIcon size={14} />}
                    onClick={() => handleRevoke(sanction)}
                  >
                    Mở khoá
                  </Button>
                )}
              </article>
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

      <CommunitySanctionModal
        open={modalOpen}
        saving={saving}
        onClose={() => setModalOpen(false)}
        onSubmit={handleCreate}
      />
    </div>
  );
};

export default CommunitySanctionList;
