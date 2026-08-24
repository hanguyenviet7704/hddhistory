import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
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
import { EyeOffIcon, PencilIcon, PlusIcon } from "lucide-react";
import { useSelector } from "react-redux";

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
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">Chủ đề cộng đồng</h1>
          <p className="text-sm text-gray-500">
            Chủ đề do MeUp tạo — người dùng chỉ theo dõi, không tự tạo được.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <TextField
            size="small"
            placeholder="Tìm theo tên hoặc slug"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
          />
          <Button
            variant="contained"
            startIcon={<PlusIcon size={16} />}
            onClick={() => {
              setEditing(null);
              setModalOpen(true);
            }}
          >
            Chủ đề mới
          </Button>
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
              <TableCell>Tên</TableCell>
              <TableCell>Slug</TableCell>
              <TableCell align="right">Người theo dõi</TableCell>
              <TableCell align="right">Bài tuần này</TableCell>
              <TableCell>Thiếu bản dịch</TableCell>
              <TableCell align="right">Thứ tự</TableCell>
              <TableCell>Trạng thái</TableCell>
              <TableCell align="right">Hành động</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading &&
              Array.from({ length: 4 }).map((_, index) => (
                <TableRow key={index}>
                  <TableCell colSpan={8}>
                    <Skeleton height={28} />
                  </TableCell>
                </TableRow>
              ))}

            {!loading && !topics.length && (
              <TableRow>
                <TableCell colSpan={8}>
                  <div className="py-8 text-center text-sm text-gray-500">
                    Chưa có chủ đề nào. Tạo chủ đề đầu tiên để mở feed cộng đồng.
                  </div>
                </TableCell>
              </TableRow>
            )}

            {!loading &&
              topics.map((topic) => {
                // Stats are per locale, so the table reports the operator's
                // current display language rather than a misleading sum.
                const stats = topic.stats?.[lang] ?? {};
                const missing = missingLocales(topic);

                return (
                  <TableRow key={topic._id} hover>
                    <TableCell>
                      <div className="font-medium">
                        {getTranslationValue(topic.name, lang) || "—"}
                      </div>
                      <div className="max-w-md truncate text-xs text-gray-500">
                        {getTranslationValue(topic.description, lang)}
                      </div>
                    </TableCell>
                    <TableCell>
                      <code className="text-xs">{topic.slug}</code>
                    </TableCell>
                    <TableCell align="right">{stats.followers ?? 0}</TableCell>
                    <TableCell align="right">
                      {stats.postsThisWeek ?? 0}
                    </TableCell>
                    <TableCell>
                      {missing.length ? (
                        <span className="text-xs text-amber-700">
                          {missing.join(", ")}
                        </span>
                      ) : (
                        <span className="text-xs text-gray-400">Đủ 5</span>
                      )}
                    </TableCell>
                    <TableCell align="right">{topic.sortOrder}</TableCell>
                    <TableCell>
                      <Chip
                        size="small"
                        label={topic.isActive ? "Đang hiện" : "Đã tắt"}
                        color={topic.isActive ? "success" : "default"}
                      />
                    </TableCell>
                    <TableCell align="right">
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
                    </TableCell>
                  </TableRow>
                );
              })}
          </TableBody>
        </Table>
      </TableContainer>

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
        <DialogTitle>Tắt chủ đề này?</DialogTitle>
        <DialogContent>
          <DialogContentText>
            App sẽ không hiện chủ đề{" "}
            <strong>{getTranslationValue(deactivating?.name, lang)}</strong> nữa.
            Bài đã đăng trong chủ đề vẫn còn — chủ đề không bị xoá, nên có thể
            bật lại bất cứ lúc nào.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeactivating(null)}>Huỷ</Button>
          <Button color="warning" variant="contained" onClick={handleDeactivate}>
            Tắt chủ đề
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  );
};

export default CommunityTopicList;
