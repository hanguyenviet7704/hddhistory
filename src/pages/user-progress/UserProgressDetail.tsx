import React, { useCallback, useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowPathIcon, TrashIcon } from "@heroicons/react/24/outline";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { userProgressService } from "../../services/userProgressService";
import { courseService } from "../../services/courseService";
import { userService } from "../../services/userService";
import { IUserProgressDetail } from "../../types/interface/user-progress.interface";
import { GradeResultType } from "../../types/enum/user-progress.enum";
import { LangCode } from "../../types/enum/common.enum";
import { getTranslationValue } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";

const formatScore = (value?: number) => {
  if (typeof value !== "number") return "-";
  return value.toFixed(1);
};

const normalizeReview = (value?: string) => {
  if (typeof value !== "string") return "-";
  const normalized = value.replace(/\s+/g, " ").trim();
  return normalized || "-";
};

const ReviewText = ({ value }: { value?: string }) => {
  const display = normalizeReview(value);
  return (
    <span
      className="max-w-[280px] truncate align-middle"
      title={display !== "-" ? display : undefined}
    >
      {display}
    </span>
  );
};

const getExerciseScore = (exercise: any) =>
  typeof exercise?.score === "number"
    ? exercise.score
    : typeof exercise?.averageScore === "number"
    ? exercise.averageScore
    : undefined;

const StatusBadge = ({ passed }: { passed?: boolean }) => {
  if (passed === undefined) {
    return <span className="text-slate-400">-</span>;
  }
  return (
    <span
      className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold ${
        passed
          ? "bg-emerald-100 text-emerald-700"
          : "bg-rose-100 text-rose-700"
      }`}
    >
      {passed ? "Passed" : "Not passed"}
    </span>
  );
};

const ScoreBadge = ({ score }: { score?: number }) => (
  <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-slate-100 text-slate-700">
    {formatScore(score)}
  </span>
);

const normalizeResponse = (payload: any) =>
  payload?.data?.data ?? payload?.data ?? payload ?? null;

const getUserLabel = (payload: any) => {
  const data = normalizeResponse(payload) || {};
  return (
    data.name ||
    data.email ||
    data.phone ||
    data.username ||
    data.fullName ||
    ""
  );
};

const getCourseTitle = (payload: any, lang: LangCode) => {
  const data = normalizeResponse(payload) || {};
  return getTranslationValue(data.title, lang) || "";
};

export default function UserProgressDetail() {
  const { userId = "", courseId = "" } = useParams();
  const navigate = useNavigate();
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showError, showSuccess } = useNotification();

  const [detail, setDetail] = useState<IUserProgressDetail | null>(null);
  const [loading, setLoading] = useState(false);
  const [userLabel, setUserLabel] = useState("");
  const [courseTitle, setCourseTitle] = useState("");
  const [confirmState, setConfirmState] = useState<{
    open: boolean;
    type: GradeResultType;
    lessonId?: string;
    keypointId?: string;
  }>({ open: false, type: GradeResultType.COURSE });
  const [removing, setRemoving] = useState(false);

  const fetchDetail = useCallback(async () => {
    if (!userId || !courseId) {
      setDetail(null);
      return;
    }
    setLoading(true);
    try {
      const res = await userProgressService.getCourseProgressDetailOfUser(
        userId,
        courseId
      );
      setDetail(normalizeResponse(res));
    } catch (error) {
      console.error("Failed to fetch progress detail", error);
      showError("Không tải được chi tiết tiến độ");
    } finally {
      setLoading(false);
    }
  }, [courseId, showError, userId]);

  useEffect(() => {
    fetchDetail();
  }, [fetchDetail]);

  useEffect(() => {
    if (!userId || !courseId) {
      setUserLabel("");
      setCourseTitle("");
      return;
    }

    let mounted = true;
    const fetchMeta = async () => {
      try {
        const [userRes, courseRes] = await Promise.all([
          userService.getById(userId),
          courseService.getById(courseId),
        ]);
        if (!mounted) return;
        setUserLabel(getUserLabel(userRes));
        setCourseTitle(getCourseTitle(courseRes, lang));
      } catch (error) {
        console.error("Failed to fetch progress meta", error);
      }
    };

    fetchMeta();
    return () => {
      mounted = false;
    };
  }, [courseId, lang, userId]);

  const lessons = useMemo(() => detail?.lessonsResult ?? [], [detail]);
  const openConfirm = (payload: {
    type: GradeResultType;
    lessonId?: string;
    keypointId?: string;
  }) => {
    setConfirmState({ open: true, ...payload });
  };

  const handleRemove = async () => {
    if (!userId || !courseId) {
      showError("Thiếu thông tin user/course để xoá");
      return;
    }
    const { type, lessonId, keypointId } = confirmState;
    try {
      setRemoving(true);
      await userProgressService.remove({
        userId,
        courseId,
        grade: type,
        lessonId,
        keypointId,
      });
      showSuccess("Xoá tiến độ thành công");
      setConfirmState({ open: false, type: GradeResultType.COURSE });
      fetchDetail();
    } catch (error) {
      console.error("Failed to remove progress", error);
      showError("Xoá tiến độ thất bại");
    } finally {
      setRemoving(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-6xl mx-auto space-y-4">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
          <div>
            <h1 className="text-2xl font-semibold text-gray-900">
              User progress detail
            </h1>
            <p className="text-sm text-gray-500">
              User: {userLabel || "-"} · Course: {courseTitle || "-"}
            </p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={fetchDetail}
              disabled={loading}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-gray-200 text-gray-700 hover:bg-gray-50 text-sm shadow-sm disabled:opacity-70"
              title="Làm mới"
            >
              <ArrowPathIcon
                className={`h-4 w-4 ${loading ? "animate-spin" : ""}`}
              />
              Làm mới
            </button>
            <button
              onClick={() => navigate(-1)}
              className="px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 text-sm shadow-sm"
            >
              Quay lại
            </button>
          </div>
        </div>

        {loading ? (
          <div className="bg-white rounded-lg border border-gray-200 p-10 text-center text-gray-500">
            Đang tải dữ liệu...
          </div>
        ) : lessons.length === 0 ? (
          <div className="bg-white rounded-lg border border-gray-200 p-10 text-center text-gray-500">
            Chưa có dữ liệu chi tiết.
          </div>
        ) : (
          <div className="space-y-4">
            {lessons.map((lesson, lessonIndex) => {
              const lessonTitle = getTranslationValue(lesson.title, lang);
              const lessonLabel = lessonTitle || lesson.lessonId || "-";

              return (
                <div
                  key={lesson.lessonId || lessonTitle || lessonIndex}
                  className="bg-white rounded-lg border border-gray-200 p-4 space-y-3"
                >
                  <div className="hidden md:grid grid-cols-12 text-[11px] uppercase text-slate-500 px-3 py-2 bg-slate-100/70 rounded-md">
                    <div className="col-span-5">Item</div>
                    <div className="col-span-2">Passed</div>
                    <div className="col-span-2">Score</div>
                    <div className="col-span-2">Reviews</div>
                    <div className="col-span-1 text-right">Action</div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-12 items-center gap-2 px-3 py-2 rounded-lg border border-slate-200 bg-slate-50">
                    <div className="col-span-1 md:col-span-5 min-w-0">
                      {lesson.lessonType ? (
                        <div className="text-[11px] uppercase text-slate-400">
                          {lesson.lessonType}
                        </div>
                      ) : null}
                      <div
                        className="truncate font-semibold text-slate-900"
                        title={lessonLabel}
                      >
                        {lessonLabel}
                      </div>
                    </div>
                    <div className="col-span-1 md:col-span-2">
                      <StatusBadge passed={lesson.passed} />
                    </div>
                    <div className="col-span-1 md:col-span-2">
                      <ScoreBadge score={lesson.averageScore} />
                    </div>
                    <div className="col-span-1 md:col-span-2 min-w-0 text-slate-600">
                      <ReviewText value={lesson.reviews} />
                    </div>
                    <div className="col-span-1 md:col-span-1 flex justify-start md:justify-end">
                      <button
                        onClick={() =>
                          openConfirm({
                            type: GradeResultType.LESSON,
                            lessonId: lesson.lessonId,
                          })
                        }
                        className="text-rose-600 hover:text-rose-700"
                        title="Xoá tiến độ bài học"
                      >
                        <TrashIcon className="h-4 w-4" />
                      </button>
                    </div>
                  </div>

                  <div className="space-y-3">
                    {(lesson.keypointsResult ?? []).map(
                      (keypoint, keypointIndex) => {
                      const keypointTitle = getTranslationValue(
                        keypoint.title,
                        lang
                      );
                      const keypointLabel =
                        keypointTitle || keypoint.keypointId || "-";

                      return (
                        <div
                          key={keypoint.keypointId || keypointIndex}
                          className="space-y-2"
                        >
                          <div className="grid grid-cols-1 md:grid-cols-12 items-center gap-2 px-3 py-2 rounded-lg border border-slate-100 bg-white">
                            <div className="col-span-1 md:col-span-5 min-w-0 pl-4">
                              <div className="text-[11px] uppercase text-slate-400">
                                Keypoint
                              </div>
                              <div
                                className="truncate font-medium text-slate-800"
                                title={keypointLabel}
                              >
                                {keypointLabel}
                              </div>
                            </div>
                            <div className="col-span-1 md:col-span-2">
                              <StatusBadge passed={keypoint.passed} />
                            </div>
                            <div className="col-span-1 md:col-span-2">
                              <ScoreBadge score={keypoint.averageScore} />
                            </div>
                            <div className="col-span-1 md:col-span-2 min-w-0 text-slate-600">
                              <ReviewText value={keypoint.reviews} />
                            </div>
                            <div className="col-span-1 md:col-span-1 flex justify-start md:justify-end">
                              <button
                                onClick={() =>
                                  openConfirm({
                                    type: GradeResultType.KEYPOINT,
                                    lessonId: lesson.lessonId,
                                    keypointId: keypoint.keypointId,
                                  })
                                }
                                className="text-rose-600 hover:text-rose-700"
                                title="Xoá tiến độ keypoint"
                              >
                                <TrashIcon className="h-4 w-4" />
                              </button>
                            </div>
                          </div>

                          <div className="space-y-1">
                            {(keypoint.exercisesResult ?? []).map(
                              (exercise, index) => {
                                const labelIndex =
                                  exercise.index ?? index + 1;
                                const score = getExerciseScore(exercise);
                                return (
                                  <div
                                    key={exercise.exerciseId || labelIndex}
                                    className="grid grid-cols-1 md:grid-cols-12 items-center gap-2 px-3 py-2 rounded-lg border border-slate-100 bg-slate-50/60"
                                  >
                                    <div className="col-span-1 md:col-span-5 min-w-0 pl-8">
                                      <div className="text-[11px] uppercase text-slate-400">
                                        Exercise
                                      </div>
                                      <div className="truncate text-xs font-medium text-slate-700">
                                        Exercise {labelIndex}
                                      </div>
                                    </div>
                                    <div className="col-span-1 md:col-span-2">
                                      <StatusBadge passed={exercise.passed} />
                                    </div>
                                    <div className="col-span-1 md:col-span-2">
                                      <ScoreBadge score={score} />
                                    </div>
                                    <div className="col-span-1 md:col-span-2 min-w-0 text-slate-600 text-xs">
                                      <ReviewText
                                        value={(exercise as any).reviews}
                                      />
                                    </div>
                                    <div className="col-span-1 md:col-span-1 text-slate-400 text-xs">
                                      -
                                    </div>
                                  </div>
                                );
                              }
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {confirmState.open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md p-6 space-y-4">
            <h3 className="text-lg font-semibold text-gray-900">
              Xoá tiến độ?
            </h3>
            <p className="text-sm text-gray-600">
              Hành động này sẽ xoá tiến độ{" "}
              {confirmState.type === GradeResultType.KEYPOINT
                ? "keypoint"
                : "bài học"}
              .
            </p>
            <div className="flex justify-end gap-2">
              <button
                onClick={() =>
                  setConfirmState({ open: false, type: GradeResultType.COURSE })
                }
                disabled={removing}
                className="px-4 py-2 rounded-lg border border-gray-200 text-gray-700 hover:bg-gray-50"
              >
                Huỷ
              </button>
              <button
                onClick={handleRemove}
                disabled={removing}
                className="px-4 py-2 rounded-lg bg-rose-600 text-white hover:bg-rose-700 disabled:opacity-70"
              >
                {removing ? "Đang xoá..." : "Xoá"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
