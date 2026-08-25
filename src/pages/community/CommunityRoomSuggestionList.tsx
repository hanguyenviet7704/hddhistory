import React, { useCallback, useEffect, useMemo, useState } from "react";
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
  Tooltip,
} from "@mui/material";
import { CheckIcon, ExternalLinkIcon, XIcon } from "lucide-react";
import { useSelector } from "react-redux";

import CommunityRoomSuggestionDialog from "../../components/community/CommunityRoomSuggestionDialog";
import { COMMUNITY_LANGS } from "../../components/community/TranslationFields";
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
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">Đề xuất phòng</h1>
          <p className="text-sm text-gray-500">
            Người đọc xin mở phòng mới. Sắp theo số người ủng hộ — đề xuất chỉ
            một người muốn thì để đó cũng được.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
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
        </div>
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
              <TableCell>Phòng được đề xuất</TableCell>
              <TableCell>Người đề xuất</TableCell>
              <TableCell align="right">Ủng hộ</TableCell>
              <TableCell>Trạng thái</TableCell>
              <TableCell align="right">Hành động</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading &&
              Array.from({ length: 4 }).map((_, index) => (
                <TableRow key={index}>
                  <TableCell colSpan={5}>
                    <Skeleton height={28} />
                  </TableCell>
                </TableRow>
              ))}

            {!loading && !suggestions.length && (
              <TableRow>
                <TableCell colSpan={5}>
                  <div className="py-8 text-center text-sm text-gray-500">
                    Chưa có đề xuất nào ở bộ lọc này.
                  </div>
                </TableCell>
              </TableRow>
            )}

            {!loading &&
              suggestions.map((suggestion) => (
                <TableRow key={suggestion.id} hover>
                  <TableCell className="max-w-md">
                    <div className="text-sm font-semibold">
                      {suggestion.name}
                    </div>
                    {!!suggestion.description && (
                      <div className="mt-0.5 line-clamp-2 text-xs text-gray-600">
                        {suggestion.description}
                      </div>
                    )}
                    <div className="mt-1 flex items-center gap-2 text-xs text-gray-500">
                      <span>{suggestion.locale.toUpperCase()}</span>
                      <span>
                        ·{" "}
                        {new Date(suggestion.createdAt).toLocaleDateString(
                          "vi-VN"
                        )}
                      </span>
                    </div>
                    {suggestion.reviewNote && (
                      <div className="mt-1 text-xs text-amber-700">
                        Ghi chú: {suggestion.reviewNote}
                      </div>
                    )}
                  </TableCell>
                  <TableCell>
                    <div className="text-sm">
                      {suggestion.author?.name || "(tài khoản đã xoá)"}
                    </div>
                    <div className="text-xs text-gray-500">
                      {suggestion.author?.id}
                    </div>
                  </TableCell>
                  <TableCell align="right">
                    <span className="text-sm font-semibold">
                      {suggestion.voteCount}
                    </span>
                  </TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      label={STATUS_LABEL[suggestion.status]}
                      color={STATUS_COLOR[suggestion.status]}
                    />
                    {suggestion.topicId && (
                      <div className="mt-1 flex items-center gap-1 text-xs text-indigo-600">
                        <ExternalLinkIcon size={12} />
                        {topicNameById.get(suggestion.topicId) ??
                          suggestion.topicId}
                      </div>
                    )}
                  </TableCell>
                  <TableCell align="right">
                    {suggestion.status ===
                    CommunityRoomSuggestionStatus.PENDING ? (
                      <div className="flex justify-end gap-1">
                        <Tooltip title="Gắn vào một phòng đã tạo">
                          <Button
                            size="small"
                            color="success"
                            startIcon={<CheckIcon size={14} />}
                            onClick={() =>
                              setDialog({ suggestion, mode: "approve" })
                            }
                          >
                            Mở phòng
                          </Button>
                        </Tooltip>
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
                      </div>
                    ) : (
                      <span className="text-xs text-gray-400">
                        {suggestion.reviewedAt
                          ? new Date(suggestion.reviewedAt).toLocaleDateString(
                              "vi-VN"
                            )
                          : "—"}
                      </span>
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
