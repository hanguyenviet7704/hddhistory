import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Skeleton,
  TextField,
} from "@mui/material";
import {
  EyeOffIcon,
  FileTextIcon,
  ListIcon,
  PencilIcon,
  PlusIcon,
  UsersIcon,
} from "lucide-react";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";

import CommunityEmpty from "../../components/community/CommunityEmpty";
import CommunityPageHeader from "../../components/community/CommunityPageHeader";
import CommunityTopicModal from "../../components/community/CommunityTopicModal";
import { COMMUNITY_LANGS } from "../../components/community/TranslationFields";
import { communityService } from "../../services/communityService";
import { RootState } from "../../store";
import {
  ICommunityTopic,
  ICommunityTopicPayload,
} from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import { getTranslationValue } from "../../utils/translation";

const CommunityTopicList: React.FC = () => {
  const { showSuccess, showError } = useNotification();
  const navigate = useNavigate();
  const lang = useSelector((state: RootState) => state.lang.code);

  const [topics, setTopics] = useState<ICommunityTopic[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<ICommunityTopic | null>(null);
  const [saving, setSaving] = useState(false);
  const [deactivating, setDeactivating] = useState<ICommunityTopic | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await communityService.getTopics({
        take: 100,
        ...(search.trim() ? { search: search.trim() } : {}),
      });
      setTopics(res?.items ?? []);
    } catch (err: any) {
      setError(
        err?.response?.data?.message ?? "Không tải được danh sách chủ đề"
      );
    } finally {
      setLoading(false);
    }
  }, [search]);

  useEffect(() => {
    // Debounced so typing in the search box does not fire a request per key.
    const timer = setTimeout(load, 300);
    return () => clearTimeout(timer);
  }, [load]);

  const handleSubmit = async (payload: ICommunityTopicPayload) => {
    setSaving(true);
    try {
      if (editing) {
        await communityService.updateTopic(editing._id, payload);
        showSuccess("Đã lưu chủ đề");
      } else {
        await communityService.createTopic(payload);
        showSuccess("Đã tạo chủ đề");
      }
      setModalOpen(false);
      setEditing(null);
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Lưu chủ đề thất bại");
    } finally {
      setSaving(false);
    }
  };

  const handleDeactivate = async () => {
    if (!deactivating) return;
    try {
      await communityService.deactivateTopic(deactivating._id);
      showSuccess("Đã tắt chủ đề");
      setDeactivating(null);
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Tắt chủ đề thất bại");
    }
  };

  // How many of the five locales still have no name. Surfaced in the table
  // because a topic missing a translation silently falls back to English in the
  // app, which is easy to ship and hard to notice.
  const missingLocales = (topic: ICommunityTopic) =>
    COMMUNITY_LANGS.filter(({ code }) => !topic.name?.[code]?.trim()).map(
      ({ label }) => label
    );

  return (
    <div className="p-6 space-y-4">
      {/* "Phòng", not "chủ đề": the app calls them phòng everywhere a reader
          sees them, and the sidebar already did. */}
      <CommunityPageHeader
        title="Phòng"
        subtitle="Phòng do MeUp mở — người dùng chỉ theo dõi và đề xuất, không tự tạo được."
      >
        <TextField
          size="small"
          placeholder="Tìm theo tên hoặc slug"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          className="min-w-[220px]"
        />
        <Button
          variant="contained"
          startIcon={<PlusIcon size={16} />}
          onClick={() => {
            setEditing(null);
            setModalOpen(true);
          }}
        >
          Phòng mới
        </Button>
      </CommunityPageHeader>

      {error && (
        <div className="rounded-md bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
        {loading &&
          Array.from({ length: 6 }).map((_, index) => (
            <Skeleton key={index} variant="rounded" height={168} />
          ))}
      </div>

      {!loading && !topics.length && (
        <CommunityEmpty>
          Chưa có phòng nào. Mở phòng đầu tiên để feed cộng đồng có chỗ đăng.
        </CommunityEmpty>
      )}

      {!loading && !!topics.length && (
        // A grid of room cards rather than eight columns: a room is a thing with
        // a face — a cover, a name, and how busy it is — and that is also all a
        // reader ever sees of it in the app.
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          {topics.map((topic) => {
            // Stats are per locale, so a card reports the operator's current
            // display language rather than a misleading sum.
            const stats = topic.stats?.[lang] ?? {};
            const missing = missingLocales(topic);
            const name = getTranslationValue(topic.name, lang) || "—";

            return (
              <article
                key={topic._id}
                className={[
                  "flex flex-col rounded-[18px] border border-gray-200 p-4",
                  topic.isActive ? "bg-white" : "bg-gray-50",
                ].join(" ")}
              >
                <div
                  className={[
                    "flex items-start gap-3",
                    topic.isActive ? "" : "opacity-60",
                  ].join(" ")}
                >
                  {topic.imageUrl ? (
                    <img
                      src={topic.imageUrl}
                      alt=""
                      className="h-12 w-12 shrink-0 rounded-[14px] border border-gray-200 object-cover"
                    />
                  ) : (
                    <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-[14px] bg-[#F4F3FD] text-lg font-bold text-[#7A69E8]">
                      {name.trim().charAt(0).toUpperCase() || "?"}
                    </div>
                  )}
                  <div className="min-w-0 flex-1">
                    <div className="truncate font-semibold text-gray-900">
                      {name}
                    </div>
                    <code className="text-xs text-gray-400">{topic.slug}</code>
                  </div>
                  <Chip
                    size="small"
                    label={topic.isActive ? "Đang hiện" : "Đã tắt"}
                    color={topic.isActive ? "success" : "default"}
                  />
                </div>

                <p className="mt-3 line-clamp-2 min-h-[2.5rem] text-sm leading-relaxed text-gray-600">
                  {getTranslationValue(topic.description, lang) || "—"}
                </p>

                <div className="mt-3 flex flex-wrap items-center gap-4 text-xs text-gray-500">
                  <span className="flex items-center gap-1.5" title="Người theo dõi">
                    <UsersIcon size={14} /> {stats.followers ?? 0}
                  </span>
                  <span className="flex items-center gap-1.5" title="Bài tuần này">
                    <FileTextIcon size={14} /> {stats.postsThisWeek ?? 0}
                  </span>
                  <span className="text-gray-400">#{topic.sortOrder}</span>
                </div>

                {!!missing.length && (
                  // Loud, because a missing translation is invisible in the app:
                  // the room simply does not appear for readers on that locale.
                  <div className="mt-2 text-xs text-amber-700">
                    Thiếu bản dịch: {missing.join(", ")}
                  </div>
                )}

                <div className="mt-auto flex items-center justify-end gap-2 border-t border-gray-100 pt-3">
                  {/* The room's own posts. Until now the panel could list every
                      post in the forum but not the ones in ONE room, which is
                      the question anybody looking at a room actually has. */}
                  <Button
                    size="small"
                    startIcon={<ListIcon size={14} />}
                    onClick={() =>
                      navigate(
                        `/community/moderation?tab=posts&topicId=${topic._id}`
                      )
                    }
                  >
                    Xem bài
                  </Button>
                  <Button
                    size="small"
                    startIcon={<PencilIcon size={14} />}
                    onClick={() => {
                      setEditing(topic);
                      setModalOpen(true);
                    }}
                  >
                    Sửa
                  </Button>
                  {topic.isActive && (
                    <Button
                      size="small"
                      color="warning"
                      startIcon={<EyeOffIcon size={14} />}
                      onClick={() => setDeactivating(topic)}
                    >
                      Tắt
                    </Button>
                  )}
                </div>
              </article>
            );
          })}
        </div>
      )}

      <CommunityTopicModal
        open={modalOpen}
        topic={editing}
        saving={saving}
        onClose={() => {
          setModalOpen(false);
          setEditing(null);
        }}
        onSubmit={handleSubmit}
      />

      <Dialog open={!!deactivating} onClose={() => setDeactivating(null)}>
        <DialogTitle>Tắt phòng này?</DialogTitle>
        <DialogContent>
          <DialogContentText>
            App sẽ không hiện phòng{" "}
            <strong>{getTranslationValue(deactivating?.name, lang)}</strong> nữa.
            Bài đã đăng trong phòng vẫn còn — phòng không bị xoá, nên có thể bật
            lại bất cứ lúc nào.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeactivating(null)}>Huỷ</Button>
          <Button color="warning" variant="contained" onClick={handleDeactivate}>
            Tắt phòng
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  );
};

export default CommunityTopicList;
