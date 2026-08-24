import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  Chip,
  Paper,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
} from "@mui/material";
import { PencilIcon, PlusIcon } from "lucide-react";
import { useSelector } from "react-redux";

import CommunityWeeklyModal from "../../components/community/CommunityWeeklyModal";
import { COMMUNITY_LANGS } from "../../components/community/TranslationFields";
import { communityService } from "../../services/communityService";
import { RootState } from "../../store";
import {
  ICommunityAdminPost,
  ICommunityWeeklyPayload,
} from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import { getTranslationValue } from "../../utils/translation";

const CommunityWeeklyPage: React.FC = () => {
  const { showSuccess, showError } = useNotification();
  const lang = useSelector((state: RootState) => state.lang.code);

  const [questions, setQuestions] = useState<ICommunityAdminPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<ICommunityAdminPost | null>(null);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await communityService.getWeeklyQuestions({ take: 50 });
      setQuestions(res?.items ?? []);
    } catch (err: any) {
      setError(
        err?.response?.data?.message ?? "Không tải được danh sách câu hỏi"
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const handleSubmit = async (payload: ICommunityWeeklyPayload) => {
    setSaving(true);
    try {
      if (editing) {
        await communityService.updateWeeklyQuestion(editing.id, payload);
        showSuccess("Đã lưu câu hỏi");
      } else {
        await communityService.createWeeklyQuestion(payload);
        showSuccess("Đã tạo câu hỏi của tuần");
      }
      setModalOpen(false);
      setEditing(null);
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Lưu câu hỏi thất bại");
    } finally {
      setSaving(false);
    }
  };

  const windowLabel = (question: ICommunityAdminPost) => {
    if (!question.weekly) return "—";
    const start = new Date(question.weekly.startsAt);
    const end = new Date(question.weekly.endsAt);
    return `${start.toLocaleDateString("vi-VN")} → ${end.toLocaleDateString(
      "vi-VN"
    )}`;
  };

  const state = (question: ICommunityAdminPost) => {
    if (!question.weekly) return { label: "Chưa đặt lịch", color: "default" as const };
    const now = Date.now();
    const start = new Date(question.weekly.startsAt).getTime();
    const end = new Date(question.weekly.endsAt).getTime();
    if (now < start) return { label: "Sắp mở", color: "info" as const };
    if (now > end) return { label: "Đã đóng", color: "default" as const };
    return { label: "Đang mở", color: "success" as const };
  };

  const missingLocales = (question: ICommunityAdminPost) =>
    COMMUNITY_LANGS.filter(
      ({ code }) => !question.title?.[code]?.trim()
    ).map(({ label }) => label);

  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">Câu hỏi của tuần</h1>
          <p className="text-sm text-gray-500">
            Đội ngũ MeUp đặt một câu hỏi mỗi tuần; user trả lời như bình luận.
            Câu hỏi hiện cho mọi ngôn ngữ, nên cần dịch đủ 5 thứ tiếng.
          </p>
        </div>
        <Button
          variant="contained"
          startIcon={<PlusIcon size={16} />}
          onClick={() => {
            setEditing(null);
            setModalOpen(true);
          }}
        >
          Câu hỏi mới
        </Button>
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
              <TableCell>Câu hỏi</TableCell>
              <TableCell>Tuần</TableCell>
              <TableCell>Khoảng thời gian</TableCell>
              <TableCell align="right">Trả lời</TableCell>
              <TableCell>Thiếu bản dịch</TableCell>
              <TableCell>Trạng thái</TableCell>
              <TableCell align="right" />
            </TableRow>
          </TableHead>
          <TableBody>
            {loading &&
              Array.from({ length: 3 }).map((_, index) => (
                <TableRow key={index}>
                  <TableCell colSpan={7}>
                    <Skeleton height={28} />
                  </TableCell>
                </TableRow>
              ))}

            {!loading && !questions.length && (
              <TableRow>
                <TableCell colSpan={7}>
                  <div className="py-8 text-center text-sm text-gray-500">
                    Chưa có câu hỏi nào. Không có câu hỏi đang mở thì app ẩn card
                    "Câu hỏi của tuần" ở đầu feed.
                  </div>
                </TableCell>
              </TableRow>
            )}

            {!loading &&
              questions.map((question) => {
                const questionState = state(question);
                const missing = missingLocales(question);
                return (
                  <TableRow key={question.id} hover>
                    <TableCell className="max-w-md">
                      <div className="text-sm font-medium">
                        {getTranslationValue(question.title, lang) || "—"}
                      </div>
                      {question.note && (
                        <div className="text-xs text-gray-500">
                          {getTranslationValue(question.note, lang)}
                        </div>
                      )}
                    </TableCell>
                    <TableCell className="text-sm">
                      {question.weekly
                        ? `Tuần ${question.weekly.weekNumber}/${question.weekly.year}`
                        : "—"}
                    </TableCell>
                    <TableCell className="text-sm">
                      {windowLabel(question)}
                    </TableCell>
                    <TableCell align="right">{question.commentCount}</TableCell>
                    <TableCell>
                      {missing.length ? (
                        <span className="text-xs text-amber-700">
                          {missing.join(", ")}
                        </span>
                      ) : (
                        <span className="text-xs text-gray-400">Đủ 5</span>
                      )}
                    </TableCell>
                    <TableCell>
                      <Chip
                        size="small"
                        label={questionState.label}
                        color={questionState.color}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Button
                        size="small"
                        startIcon={<PencilIcon size={14} />}
                        onClick={() => {
                          setEditing(question);
                          setModalOpen(true);
                        }}
                      >
                        Sửa
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              })}
          </TableBody>
        </Table>
      </TableContainer>

      <CommunityWeeklyModal
        open={modalOpen}
        question={editing}
        saving={saving}
        onClose={() => {
          setModalOpen(false);
          setEditing(null);
        }}
        onSubmit={handleSubmit}
      />
    </div>
  );
};

export default CommunityWeeklyPage;
