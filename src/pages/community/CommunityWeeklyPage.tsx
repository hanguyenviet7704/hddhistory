import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  Chip,
  Skeleton,
} from "@mui/material";
import {
  CalendarDaysIcon,
  MessageCircleIcon,
  PencilIcon,
  PlusIcon,
} from "lucide-react";
import { useSelector } from "react-redux";

import CommunityWeeklyModal from "../../components/community/CommunityWeeklyModal";
import { COMMUNITY_LANGS } from "../../components/community/TranslationFields";
import CommunityEmpty from "../../components/community/CommunityEmpty";
import CommunityPageHeader from "../../components/community/CommunityPageHeader";
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
      <CommunityPageHeader
        title="Câu hỏi của tuần"
        subtitle="Đội ngũ HDDhistory đặt một câu hỏi mỗi tuần; user trả lời như bình luận. Câu hỏi hiện cho mọi ngôn ngữ, nên cần dịch đủ 5 thứ tiếng."
      >
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
      </CommunityPageHeader>

      {error && (
        <div className="rounded-md bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      <div className="space-y-3">
        {loading &&
          Array.from({ length: 3 }).map((_, index) => (
            <Skeleton key={index} variant="rounded" height={116} />
          ))}

        {!loading && !questions.length && (
          <CommunityEmpty>
            Chưa có câu hỏi nào. Không có câu hỏi đang mở thì app ẩn card "Câu
            hỏi của tuần" ở đầu feed.
          </CommunityEmpty>
        )}

        {!loading &&
          questions.map((question) => {
            const questionState = state(question);
            const missing = missingLocales(question);
            const isOpen = questionState.label === "Đang mở";

            return (
              <article
                key={question.id}
                className={[
                  "rounded-[18px] border bg-white p-4",
                  // The open one is the only row that is live in the app right
                  // now, so it gets the ring: down a list of a dozen weeks, that
                  // is the single thing worth finding at a glance.
                  isOpen ? "border-emerald-300 ring-1 ring-emerald-100" : "border-gray-200",
                ].join(" ")}
              >
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="min-w-0">
                    <h3 className="text-base font-semibold leading-snug text-gray-900">
                      {getTranslationValue(question.title, lang) || "—"}
                    </h3>
                    {question.note && (
                      <p className="mt-0.5 text-sm text-gray-500">
                        {getTranslationValue(question.note, lang)}
                      </p>
                    )}
                  </div>
                  <Chip
                    size="small"
                    label={questionState.label}
                    color={questionState.color}
                  />
                </div>

                <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-500">
                  <span className="flex items-center gap-1.5">
                    <CalendarDaysIcon size={14} />
                    {question.weekly
                      ? `Tuần ${question.weekly.weekNumber}/${question.weekly.year}`
                      : "Chưa đặt lịch"}
                  </span>
                  <span>{windowLabel(question)}</span>
                  <span className="flex items-center gap-1.5">
                    <MessageCircleIcon size={14} /> {question.commentCount} trả
                    lời
                  </span>
                </div>

                {!!missing.length && (
                  // A question missing a locale is a question that simply does
                  // not appear for those readers — worth saying loudly, since
                  // nothing in the app reports it.
                  <div className="mt-2 text-xs text-amber-700">
                    Thiếu bản dịch: {missing.join(", ")}
                  </div>
                )}

                <div className="mt-3 flex justify-end border-t border-gray-100 pt-3">
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
                </div>
              </article>
            );
          })}
      </div>

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
