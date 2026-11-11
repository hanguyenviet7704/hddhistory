import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  Button,
  Chip,
  MenuItem,
  Pagination,
  Skeleton,
  TextField,
  Tooltip,
} from "@mui/material";
import { CheckIcon, ExternalLinkIcon, XIcon } from "lucide-react";
import { useSelector } from "react-redux";

import CommunityRoomSuggestionDialog from "../../components/community/CommunityRoomSuggestionDialog";
import { COMMUNITY_LANGS } from "../../components/community/TranslationFields";
import CommunityEmpty from "../../components/community/CommunityEmpty";
import CommunityPageHeader from "../../components/community/CommunityPageHeader";
import { communityService } from "../../services/communityService";
import { RootState } from "../../store";
import {
  CommunityRoomSuggestionStatus,
  ICommunityRoomSuggestion,
  ICommunityTopic,
} from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import { getTranslationValue } from "../../utils/translation";

const TAKE = 20;

const STATUS_LABEL: Record<CommunityRoomSuggestionStatus, string> = {
  [CommunityRoomSuggestionStatus.PENDING]: "Chờ xử lý",
  [CommunityRoomSuggestionStatus.APPROVED]: "Đã mở phòng",
  [CommunityRoomSuggestionStatus.DECLINED]: "Đã từ chối",
};

const STATUS_COLOR: Record<
  CommunityRoomSuggestionStatus,
  "warning" | "success" | "default"
> = {
  [CommunityRoomSuggestionStatus.PENDING]: "warning",
  [CommunityRoomSuggestionStatus.APPROVED]: "success",
  [CommunityRoomSuggestionStatus.DECLINED]: "default",
};

/**
 * "Đề xuất phòng mới" — what readers asked for, and what we did about it.
 *
 * Sorted by vote count, not by date: the queue's job is to surface what enough
 * people want, and the oldest ask is usually the one nobody else backed.
 *
 * Approving asks for a topic to link to rather than creating one, because a
 * room needs a name in five languages, a slug and an image that a free-text ask
 * has none of. The dialog says so and links to the Topics screen.
 */
const CommunityRoomSuggestionList: React.FC = () => {
  const { showSuccess, showError } = useNotification();
  const lang = useSelector((state: RootState) => state.lang.code);

  const [suggestions, setSuggestions] = useState<ICommunityRoomSuggestion[]>([]);
  const [topics, setTopics] = useState<ICommunityTopic[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<CommunityRoomSuggestionStatus | "">(
    CommunityRoomSuggestionStatus.PENDING
  );
  const [locale, setLocale] = useState("");
  const [dialog, setDialog] = useState<{
    suggestion: ICommunityRoomSuggestion;
    mode: "approve" | "decline";
  } | null>(null);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await communityService.getRoomSuggestions({
        page,
        take: TAKE,
        ...(search.trim() ? { search: search.trim() } : {}),
        ...(status ? { status } : {}),
        ...(locale ? { locale } : {}),
      });
      setSuggestions(res?.items ?? []);
      setTotalPages(res?.totalPages || 1);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được danh sách");
    } finally {
      setLoading(false);
    }
  }, [page, search, status, locale]);

  useEffect(() => {
    const timer = setTimeout(load, 300);
    return () => clearTimeout(timer);
  }, [load]);

  // Loaded once, not per dialog open: the approve dialog needs the whole topic
  // list to pick from, and fetching it on every open would stall the dialog.
  useEffect(() => {
    communityService
      .getTopics({ page: 1, take: 200 })
      .then((res) => setTopics(res?.items ?? []))
      .catch(() => setTopics([]));
  }, []);

  const topicNameById = useMemo(() => {
    const map = new Map<string, string>();
    topics.forEach((topic) =>
      map.set(topic._id, getTranslationValue(topic.name, lang) || topic.slug)
    );
    return map;
  }, [topics, lang]);

  const handleReview = async (topicId: string, note: string) => {
    if (!dialog) return;
    setSaving(true);
    try {
      if (dialog.mode === "approve") {
        await communityService.approveRoomSuggestion(
          dialog.suggestion.id,
          topicId,
          note || undefined
        );
        showSuccess("Đã gắn đề xuất vào phòng");
      } else {
        await communityService.declineRoomSuggestion(
          dialog.suggestion.id,
          note || undefined
        );
        showSuccess("Đã từ chối đề xuất");
      }
      setDialog(null);
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Không lưu được");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="p-6 space-y-4">
      <CommunityPageHeader
        title="Đề xuất phòng"
        subtitle="Người đọc xin mở phòng mới. Sắp theo số người ủng hộ — đề xuất chỉ một người muốn thì để đó cũng được."
      >
          <TextField
            size="small"
            placeholder="Tìm theo tên phòng"
            value={search}
            onChange={(event) => {
              setPage(1);
              setSearch(event.target.value);
            }}
          />
          <TextField
            select
            size="small"
            label="Trạng thái"
            value={status}
            onChange={(event) => {
              setPage(1);
              setStatus(
                event.target.value as CommunityRoomSuggestionStatus | ""
              );
            }}
            className="min-w-[150px]"
          >
            <MenuItem value="">Tất cả</MenuItem>
            {Object.values(CommunityRoomSuggestionStatus).map((value) => (
              <MenuItem key={value} value={value}>
                {STATUS_LABEL[value]}
              </MenuItem>
            ))}
          </TextField>
          <TextField
            select
            size="small"
            label="Ngôn ngữ"
            value={locale}
            onChange={(event) => {
              setPage(1);
              setLocale(event.target.value);
            }}
            className="min-w-[130px]"
          >
            <MenuItem value="">Tất cả</MenuItem>
          {COMMUNITY_LANGS.map(({ code, label }) => (
            <MenuItem key={code} value={code}>
              {label}
            </MenuItem>
          ))}
        </TextField>
      </CommunityPageHeader>

      {error && (
        <div className="rounded-md bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      <div className="space-y-3">
        {loading &&
          Array.from({ length: 4 }).map((_, index) => (
            <Skeleton key={index} variant="rounded" height={120} />
          ))}

        {!loading && !suggestions.length && (
          <CommunityEmpty>Chưa có đề xuất nào ở bộ lọc này.</CommunityEmpty>
        )}

        {!loading &&
          suggestions.map((suggestion) => (
            <article
              key={suggestion.id}
              className="flex gap-4 rounded-[18px] border border-gray-200 bg-white p-4"
            >
              {/* The vote count as a block on the left, not a number in a
                  column: how many people asked IS the decision, and it should
                  be the first thing the eye lands on down a list. */}
              <div className="flex w-16 shrink-0 flex-col items-center justify-center rounded-[14px] bg-[#F4F3FD] py-2">
                <span className="text-xl font-bold text-[#7A69E8]">
                  {suggestion.voteCount}
                </span>
                <span className="text-[10px] font-semibold uppercase tracking-wide text-[#7A69E8]/70">
                  ủng hộ
                </span>
              </div>

              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="min-w-0">
                    <h3 className="font-semibold text-gray-900">
                      {suggestion.name}
                    </h3>
                    <div className="mt-0.5 flex flex-wrap items-center gap-x-2 text-xs text-gray-500">
                      <span>
                        {suggestion.author?.name || "(tài khoản đã xoá)"}
                      </span>
                      <span>·</span>
                      <span>{suggestion.locale.toUpperCase()}</span>
                      <span>·</span>
                      <span>
                        {new Date(suggestion.createdAt).toLocaleDateString(
                          "vi-VN"
                        )}
                      </span>
                    </div>
                  </div>
                  <div className="shrink-0 text-right">
                    <Chip
                      size="small"
                      label={STATUS_LABEL[suggestion.status]}
                      color={STATUS_COLOR[suggestion.status]}
                    />
                    {suggestion.topicId && (
                      <div className="mt-1 flex items-center justify-end gap-1 text-xs text-bronze-600">
                        <ExternalLinkIcon size={12} />
                        {topicNameById.get(suggestion.topicId) ??
                          suggestion.topicId}
                      </div>
                    )}
                  </div>
                </div>

                {!!suggestion.description && (
                  <p className="mt-2 whitespace-pre-wrap text-sm leading-relaxed text-gray-600">
                    {suggestion.description}
                  </p>
                )}

                {suggestion.reviewNote && (
                  <div className="mt-2 text-xs text-amber-700">
                    Ghi chú: {suggestion.reviewNote}
                  </div>
                )}

                <div className="mt-3 flex items-center justify-end gap-2 border-t border-gray-100 pt-3">
                  {suggestion.status ===
                  CommunityRoomSuggestionStatus.PENDING ? (
                    <>
                      <Button
                        size="small"
                        color="inherit"
                        startIcon={<XIcon size={14} />}
                        onClick={() =>
                          setDialog({ suggestion, mode: "decline" })
                        }
                      >
                        Từ chối
                      </Button>
                      <Tooltip title="Gắn vào một phòng đã tạo">
                        <Button
                          size="small"
                          variant="outlined"
                          color="success"
                          startIcon={<CheckIcon size={14} />}
                          onClick={() =>
                            setDialog({ suggestion, mode: "approve" })
                          }
                        >
                          Mở phòng
                        </Button>
                      </Tooltip>
                    </>
                  ) : (
                    <span className="text-xs text-gray-400">Đã xử lý</span>
                  )}
                </div>
              </div>
            </article>
          ))}
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

      <CommunityRoomSuggestionDialog
        open={!!dialog}
        mode={dialog?.mode ?? "approve"}
        suggestion={dialog?.suggestion ?? null}
        topics={topics}
        lang={lang}
        saving={saving}
        onClose={() => setDialog(null)}
        onSubmit={handleReview}
      />
    </div>
  );
};

export default CommunityRoomSuggestionList;
