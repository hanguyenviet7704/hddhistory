import React, { useEffect, useMemo, useRef, useState } from "react";
import { Combobox } from "@headlessui/react";
import { useSelector } from "react-redux";
import {
  AcademicCapIcon,
  ArrowPathIcon,
  SparklesIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";
import { CheckCircleIcon, XCircleIcon } from "@heroicons/react/24/solid";
import { RootState } from "../../store";
import { ICourse } from "../../types/interface/cource.interface";
import { IUser } from "../../types/interface/user.interface";
import {
  IUserProgress,
  RemoveUserProgress,
  UserProgressListQuery,
} from "../../types/interface/user-progress.interface";
import { GradeResultType } from "../../types/enum/user-progress.enum";
import { courseService } from "../../services/courseService";
import { userService } from "../../services/userService";
import { userProgressService } from "../../services/userProgressService";
import { lessonService } from "../../services/lessonService";
import { keypointService } from "../../services/keypointService";
import { getTranslationValue } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";

const StatusBadge: React.FC<{ passed?: boolean }> = ({ passed }) => (
  <span
    className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium ${
      passed ? "bg-green-100 text-green-700" : "bg-amber-100 text-amber-700"
    }`}
  >
    {passed ? (
      <CheckCircleIcon className="h-4 w-4" />
    ) : (
      <XCircleIcon className="h-4 w-4" />
    )}
    {passed ? "Passed" : "Not passed"}
  </span>
);

const StatPill: React.FC<{ label: string; value: string | number }> = ({
  label,
  value,
}) => (
  <div className="px-3 py-2 rounded-lg bg-gray-100 text-sm text-gray-700 flex items-center gap-2">
    <SparklesIcon className="h-4 w-4 text-indigo-500" />
    <div className="flex flex-col leading-tight">
      <span className="text-xs text-gray-500">{label}</span>
      <span className="font-semibold text-gray-900">{value}</span>
    </div>
  </div>
);

const formatDate = (value?: string | Date) => {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return date.toLocaleString();
};

const formatScore = (value?: number) => {
  if (typeof value !== "number") return "--";
  return value.toFixed(1);
};

const getUserId = (user?: Partial<IUser> | null) =>
  (user as any)?._id || (user as any)?.id || "";

const getUserLabel = (user?: Partial<IUser> | null) => {
  if (!user) return "";
  const name = (user as any).name || "";
  const email = (user as any).email || "";
  const phone = (user as any).phone || "";
  return name || email || phone || getUserId(user);
};

const getProgressUserId = (progress: IUserProgress | any) =>
  progress.userId ||
  progress.user_id ||
  progress.user?.id ||
  progress.user?._id ||
  "";

const getProgressUserLabel = (progress: IUserProgress | any) =>
  getUserLabel(progress.user);

export default function UserProgressList() {
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showError, showSuccess } = useNotification();

  const [courseQuery, setCourseQuery] = useState("");
  const [courses, setCourses] = useState<ICourse[]>([]);
  const [selectedCourse, setSelectedCourse] = useState<ICourse | null>(null);
  const [userQuery, setUserQuery] = useState("");
  const [users, setUsers] = useState<Partial<IUser>[]>([]);
  const [selectedUser, setSelectedUser] = useState<Partial<IUser> | null>(null);

  const [progressList, setProgressList] = useState<IUserProgress[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(false);
  const [removing, setRemoving] = useState<string | null>(null);
  const [courseTitles, setCourseTitles] = useState<Record<string, string>>({});
  const [lessonTitles, setLessonTitles] = useState<Record<string, string>>({});
  const [keypointTitles, setKeypointTitles] = useState<Record<string, string>>(
    {}
  );
  const [userNames, setUserNames] = useState<Record<string, string>>({});
  const [confirmState, setConfirmState] = useState<{
    open: boolean;
    type: GradeResultType;
    progress?: IUserProgress;
    ids?: { lessonId?: string; keypointId?: string; exerciseId?: string };
  }>({ open: false, type: GradeResultType.COURSE });

  const courseDebounceRef = useRef<number | undefined>(undefined);
  const userDebounceRef = useRef<number | undefined>(undefined);

  const normalizeCourseList = (payload: any): ICourse[] => {
    const data = payload?.data ?? payload ?? {};
    const list =
      data.list ??
      data.items ??
      data.data?.items ??
      data.data?.list ??
      (Array.isArray(data) ? data : []);
    return Array.isArray(list) ? list : [];
  };

  const normalizeProgressList = (payload: any): IUserProgress[] => {
    const asArray = (value: any): IUserProgress[] => {
      if (Array.isArray(value)) return value;
      if (value && typeof value === "object" && Object.keys(value).length > 0) {
        return [value as IUserProgress];
      }
      return [];
    };

    const data = payload?.data ?? payload ?? {};
    if (Array.isArray(data)) return data;

    const candidates = [
      data.items,
      data.list,
      data.users,
      data.data?.items,
      data.data?.list,
      data.data,
    ];

    for (const candidate of candidates) {
      const normalized = asArray(candidate);
      if (normalized.length) return normalized;
    }

    return asArray(data);
  };

  const normalizeUserList = (payload: any): Partial<IUser>[] => {
    const data = payload?.data ?? payload ?? {};
    const list =
      data.items ??
      data.list ??
      data.users ??
      data.data?.items ??
      data.data?.list ??
      (Array.isArray(data) ? data : []);
    return Array.isArray(list) ? list : [];
  };

  const normalizeUserDetail = (payload: any): Partial<IUser> => {
    const data = payload?.data ?? payload ?? {};
    return data;
  };

  const resolveHasMore = (
    payload: any,
    fetchedLength: number,
    pageNumber: number,
    take: number
  ) => {
    const data = payload?.data ?? payload ?? {};
    const pagination = data?.pagination ?? {};

    const totalPages =
      data?.totalPages ?? pagination?.totalPages ?? pagination?.total;
    const currentPage =
      data?.currentPage ?? data?.page ?? pagination?.page ?? pageNumber;
    const totalItems =
      data?.total ?? pagination?.totalItems ?? data?.data?.total;
    const itemsPerPage =
      data?.itemsPerPage ?? data?.take ?? pagination?.take ?? take;

    if (totalPages && currentPage) {
      return Number(currentPage) < Number(totalPages);
    }

    if (totalItems && itemsPerPage) {
      return Number(currentPage) * Number(itemsPerPage) < Number(totalItems);
    }

    return fetchedLength >= itemsPerPage;
  };

  const fetchCourses = async (query = "") => {
    try {
      const res = await courseService.getList({ search: query, isAll: true });
      const list = normalizeCourseList(res);
      setCourses(list);
      setSelectedCourse((current) => current ?? list[0] ?? null);
    } catch (err) {
      console.error("Failed to fetch courses", err);
      showError("Không tải được danh sách khoá học");
    }
  };

  const fetchUsers = async (query = "") => {
    try {
      const res = await userService.getList({ search: query });
      const list = normalizeUserList(res);
      setUsers(list);
    } catch (err) {
      console.error("Failed to fetch users", err);
      showError("Không tải được danh sách người dùng");
    }
  };

  const fetchProgress = async (pageNumber = 1, append = false) => {
    const userId = getUserId(selectedUser) || undefined;
    if (!selectedCourse?._id) {
      setProgressList([]);
      setHasMore(false);
      setPage(1);
      return;
    }

    const isAppend = append && pageNumber > 1;
    if (isAppend) {
      setLoadingMore(true);
    } else {
      setLoading(true);
      setHasMore(false);
    }

    try {
      const query = new UserProgressListQuery({
        courseId: selectedCourse._id,
        grade: GradeResultType.COURSE,
        userId,
        page: pageNumber,
        take: 12,
      });

      const res = await userProgressService.getList(query);
      const list = normalizeProgressList(res);
      setProgressList((prev) => {
        const merged = isAppend ? [...prev, ...list] : list;
        ensureTitles(merged);
        return merged;
      });

      setHasMore(resolveHasMore(res, list.length, pageNumber, 12));
      setPage(pageNumber);
    } catch (err) {
      console.error("Failed to fetch user progress", err);
      showError("Không tải được kết quả học tập");
    } finally {
      if (isAppend) {
        setLoadingMore(false);
      } else {
        setLoading(false);
      }
    }
  };

  const extractTitle = (payload: any) => {
    const data = payload?.data ?? payload ?? {};
    return data.title ?? data.data?.title ?? null;
  };

  const ensureTitles = async (listOverride?: IUserProgress[]) => {
    const courseIds = new Set<string>();
    const userIds = new Set<string>();
    const source = listOverride ?? progressList;
    source.forEach((p) => {
      if (p.courseId) courseIds.add(p.courseId);
      const uid = getProgressUserId(p);
      if (uid) userIds.add(uid);
    });
    if (selectedCourse?._id) courseIds.add(selectedCourse._id);
    const selectedUserId = getUserId(selectedUser);
    if (selectedUserId) userIds.add(selectedUserId);

    const lessonIds = new Set<string>();
    const keypointIds = new Set<string>();

    source.forEach((progress) => {
      progress.lessonsResult?.forEach((lesson) => {
        if (lesson.lessonId) lessonIds.add(lesson.lessonId);
        lesson.keypointsResult?.forEach((kp) => {
          if (kp.keypointId) keypointIds.add(kp.keypointId);
        });
      });
    });

    const courseUpdates: Record<string, string> = {};
    const missingCourseIds = Array.from(courseIds).filter(
      (id) => !courseTitles[id]
    );
    if (selectedCourse?._id && selectedCourse.title) {
      courseUpdates[selectedCourse._id] =
        getTranslationValue(selectedCourse.title, lang) || selectedCourse._id;
    }

    const missingLessonIds = Array.from(lessonIds).filter(
      (id) => !lessonTitles[id]
    );
    const missingKeypointIds = Array.from(keypointIds).filter(
      (id) => !keypointTitles[id]
    );
    const missingUserIds = Array.from(userIds).filter((id) => !userNames[id]);
    const preloadUserNames: Record<string, string> = {};
    source.forEach((p) => {
      const uid = getProgressUserId(p);
      const label = getProgressUserLabel(p);
      if (uid && label) preloadUserNames[uid] = label;
    });

    try {
      const [coursesRes, lessonsRes, keypointsRes, usersRes] =
        await Promise.all([
          Promise.all(
            missingCourseIds.map(async (id) => {
              const res = await courseService.getById(id);
              return { id, title: extractTitle(res) };
            })
          ),
          Promise.all(
            missingLessonIds.map(async (id) => {
              const res = await lessonService.getById(id);
              return { id, title: extractTitle(res) };
            })
          ),
          Promise.all(
            missingKeypointIds.map(async (id) => {
              const res = await keypointService.getById(id);
              return { id, title: extractTitle(res) };
            })
          ),
          Promise.all(
            missingUserIds.map(async (id) => {
              const res = await userService.getById(id);
              console.log(111, res);

              return { id, user: normalizeUserDetail(res) };
            })
          ),
        ]);

      const courseUpdate: Record<string, string> = {};
      coursesRes.forEach(({ id, title }) => {
        if (id) courseUpdate[id] = getTranslationValue(title, lang) || id;
      });

      const lessonUpdate: Record<string, string> = {};
      lessonsRes.forEach(({ id, title }) => {
        if (id) lessonUpdate[id] = getTranslationValue(title, lang) || id;
      });

      const keypointUpdate: Record<string, string> = {};
      keypointsRes.forEach(({ id, title }) => {
        if (id) keypointUpdate[id] = getTranslationValue(title, lang) || id;
      });

      const userUpdate: Record<string, string> = {};
      usersRes.forEach(({ id, user }) => {
        if (id && user) userUpdate[id] = getUserLabel(user);
      });

      if (Object.keys(courseUpdate).length || Object.keys(courseUpdates).length)
        setCourseTitles((prev) => ({
          ...prev,
          ...courseUpdates,
          ...courseUpdate,
        }));
      if (Object.keys(lessonUpdate).length)
        setLessonTitles((prev) => ({ ...prev, ...lessonUpdate }));
      if (Object.keys(keypointUpdate).length)
        setKeypointTitles((prev) => ({ ...prev, ...keypointUpdate }));
      if (
        Object.keys(userUpdate).length ||
        Object.keys(preloadUserNames).length
      )
        setUserNames((prev) => ({
          ...prev,
          ...preloadUserNames,
          ...userUpdate,
        }));
    } catch (err) {
      console.error("Failed to fetch titles", err);
    }
  };

  const renderConfirmModal = () => {
    const { open, type, progress, ids } = confirmState;
    if (!open || !progress) return null;
    const targetId =
      ids?.exerciseId || ids?.keypointId || ids?.lessonId || progress.courseId;

    const label =
      type === GradeResultType.EXERCISE
        ? "bài tập"
        : type === GradeResultType.KEYPOINT
        ? "keypoint"
        : type === GradeResultType.LESSON
        ? "bài học"
        : "khoá học";

    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4">
        <div className="bg-white rounded-xl shadow-2xl w-full max-w-md p-6">
          <div className="text-center">
            <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100 mb-4">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-6 w-6 text-red-600"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                />
              </svg>
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              Xoá kết quả {label}
            </h3>
            <p className="text-sm text-gray-500 mb-6">
              Bạn chắc chắn muốn xoá kết quả {label} với ID "
              <span className="font-medium">{targetId}</span>"?
            </p>

            <div className="flex justify-center gap-3">
              <button
                onClick={() =>
                  setConfirmState({ open: false, type: GradeResultType.COURSE })
                }
                disabled={removing !== null}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-70"
              >
                Huỷ
              </button>
              <button
                onClick={handleConfirmDelete}
                disabled={removing !== null}
                className="px-4 py-2 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg hover:from-red-700 hover:to-red-800 transition-all flex items-center gap-2 disabled:opacity-70"
              >
                {removing !== null ? (
                  <>
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      className="h-4 w-4 animate-spin"
                      fill="none"
                      viewBox="0 0 24 24"
                    >
                      <circle
                        className="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        strokeWidth="4"
                      ></circle>
                      <path
                        className="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      ></path>
                    </svg>
                    <span>Đang xoá...</span>
                  </>
                ) : (
                  <span>Xoá</span>
                )}
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  };

  const openConfirm = (
    type: GradeResultType,
    progress: IUserProgress,
    ids: { lessonId?: string; keypointId?: string; exerciseId?: string }
  ) => {
    setConfirmState({ open: true, type, progress, ids });
  };

  const handleConfirmDelete = async () => {
    const { progress, type, ids } = confirmState;
    if (!progress || !type) return;
    if (!progress.userId || !progress.courseId) {
      showError("Thiếu thông tin user hoặc course để xoá");
      return;
    }

    const targetId =
      ids?.exerciseId || ids?.keypointId || ids?.lessonId || progress.courseId;
    if (type !== GradeResultType.COURSE && !targetId) {
      showError("Thiếu ID để xoá kết quả");
      return;
    }

    setRemoving(`${type}-${targetId}`);
    try {
      const payload = new RemoveUserProgress({
        userId: progress.userId,
        courseId: progress.courseId,
        grade: type,
        lessonId: ids?.lessonId,
        keypointId: ids?.keypointId,
        exerciseId: ids?.exerciseId,
      });
      await userProgressService.remove(payload);
      showSuccess("Đã xoá kết quả");
      await fetchProgress();
      setConfirmState({ open: false, type: GradeResultType.COURSE });
    } catch (err) {
      console.error("Failed to delete user progress", err);
      showError("Không xoá được kết quả");
    } finally {
      setRemoving(null);
    }
  };

  useEffect(() => {
    fetchCourses();
    fetchUsers();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    window.clearTimeout(courseDebounceRef.current);
    courseDebounceRef.current = window.setTimeout(() => {
      fetchCourses(courseQuery.trim());
    }, 400);
    return () => window.clearTimeout(courseDebounceRef.current);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseQuery]);

  useEffect(() => {
    window.clearTimeout(userDebounceRef.current);
    userDebounceRef.current = window.setTimeout(() => {
      fetchUsers(userQuery.trim());
    }, 400);
    return () => window.clearTimeout(userDebounceRef.current);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userQuery]);

  useEffect(() => {
    fetchProgress();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedCourse?._id, selectedUser]);

  useEffect(() => {
    ensureTitles();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [progressList, selectedCourse?._id, lang]);

  const totals = useMemo(() => {
    return progressList.map((progress) => {
      const lessons = progress.lessonsResult ?? [];
      const keypoints = lessons.reduce(
        (sum, lesson) => sum + (lesson.keypointsResult?.length ?? 0),
        0
      );
      const exercises = lessons.reduce(
        (sum, lesson) =>
          sum +
          (lesson.keypointsResult ?? []).reduce(
            (kpSum, kp) => kpSum + (kp.exercisesResult?.length ?? 0),
            0
          ),
        0
      );
      const passedLessons = lessons.filter((l) => l.passed).length;
      const passedKeypoints = lessons.reduce(
        (sum, lesson) =>
          sum + (lesson.keypointsResult ?? []).filter((kp) => kp.passed).length,
        0
      );
      const passedExercises = lessons.reduce(
        (sum, lesson) =>
          sum +
          (lesson.keypointsResult ?? []).reduce(
            (kpSum, kp) =>
              kpSum +
              (kp.exercisesResult ?? []).filter((ex) => ex.passed).length,
            0
          ),
        0
      );

      return {
        key: `${progress.userId}-${progress.courseId}`,
        lessons,
        keypoints,
        exercises,
        passedLessons,
        passedKeypoints,
        passedExercises,
      };
    });
  }, [progressList]);

  const selectedCourseName = selectedCourse
    ? getTranslationValue(selectedCourse.title, lang)
    : "Chọn khoá học";
  const selectedUserLabel =
    userNames[getUserId(selectedUser)] || getUserLabel(selectedUser);
  const resolveCourseName = (id: string) =>
    courseTitles[id] || selectedCourseName || id;
  const resolveUserName = (id: string) => {
    if (!id) return "";
    if (userNames[id]) return userNames[id];
    if (getUserId(selectedUser) === id) return selectedUserLabel || id;
    return id;
  };

  return (
    <>
      <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-indigo-50 p-6">
        <div className="max-w-7xl mx-auto space-y-6">
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div>
              <p className="text-sm uppercase text-indigo-500 font-semibold tracking-wide flex items-center gap-2">
                <AcademicCapIcon className="h-5 w-5" />
                Progress Center
              </p>
              <h1 className="text-3xl font-bold text-slate-900 mt-1">
                Kết quả học tập
              </h1>
              <p className="text-slate-500 mt-1">
                Theo dõi tiến độ học của từng học viên theo khoá học, bài học,
                keypoint và bài tập.
              </p>
            </div>
            <div className="flex items-center gap-3 flex-wrap">
              <div className="w-64">
                <label className="text-xs text-gray-600 mb-1 block">
                  Chọn khoá học
                </label>
                <Combobox value={selectedCourse} onChange={setSelectedCourse}>
                  <div className="relative">
                    <Combobox.Input
                      className="w-full rounded-lg border-gray-200 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-200 px-3 py-2"
                      displayValue={(course: ICourse) =>
                        course ? getTranslationValue(course.title, lang) : ""
                      }
                      placeholder="Tìm khoá học..."
                      onChange={(event) => setCourseQuery(event.target.value)}
                    />
                    <Combobox.Options className="absolute z-20 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                      <Combobox.Option
                        value={null}
                        className="cursor-pointer px-3 py-2 hover:bg-gray-100 text-gray-500"
                      >
                        Không chọn
                      </Combobox.Option>
                      {courses.map((course) => (
                        <Combobox.Option
                          key={course._id}
                          value={course}
                          className="cursor-pointer px-3 py-2 hover:bg-gray-100"
                        >
                          {getTranslationValue(course.title, lang)}
                        </Combobox.Option>
                      ))}
                    </Combobox.Options>
                  </div>
                </Combobox>
              </div>
              <div className="w-64">
                <label className="text-xs text-gray-600 mb-1 block">
                  Chọn người học
                </label>
                <Combobox value={selectedUser} onChange={setSelectedUser}>
                  <div className="relative">
                    <Combobox.Input
                      className="w-full rounded-lg border-gray-200 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-200 px-3 py-2"
                      displayValue={(user: Partial<IUser>) =>
                        getUserLabel(user)
                      }
                      placeholder="Tìm người dùng..."
                      onChange={(event) => setUserQuery(event.target.value)}
                    />
                    <Combobox.Options className="absolute z-20 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                      <Combobox.Option
                        value={null}
                        className="cursor-pointer px-3 py-2 hover:bg-gray-100 text-gray-500"
                      >
                        Không chọn
                      </Combobox.Option>
                      {users.map((user, idx) => (
                        <Combobox.Option
                          key={`${getUserId(user)}-${idx}`}
                          value={user}
                          className="cursor-pointer px-3 py-2 hover:bg-gray-100"
                        >
                          {getUserLabel(user)}
                        </Combobox.Option>
                      ))}
                    </Combobox.Options>
                  </div>
                </Combobox>
              </div>
              <button
                onClick={() => fetchProgress()}
                className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg shadow-sm transition"
                disabled={loading || !selectedCourse}
              >
                <ArrowPathIcon
                  className={`h-5 w-5 ${loading ? "animate-spin" : ""}`}
                />
                Làm mới
              </button>
            </div>
          </div>

          {!selectedCourse ? (
            <div className="bg-white border border-dashed border-gray-200 rounded-2xl p-10 text-center text-gray-500">
              Chọn khoá học để xem kết quả học tập.
            </div>
          ) : loading ? (
            <div className="bg-white rounded-2xl p-10 flex flex-col items-center justify-center text-indigo-600">
              <ArrowPathIcon className="h-8 w-8 animate-spin mb-3" />
              <p>Đang tải kết quả cho {selectedCourseName}...</p>
            </div>
          ) : progressList.length === 0 ? (
            <div className="bg-white rounded-2xl p-10 text-center text-gray-500 border border-dashed border-gray-200">
              Không có dữ liệu cho lựa chọn hiện tại.
            </div>
          ) : (
            <div className="space-y-6">
              {progressList.map((progress, index) => {
                const summary = totals[index];
                const lessons = progress.lessonsResult ?? [];

                return (
                  <div
                    key={`${progress.userId}-${progress.courseId}-${index}`}
                    className="bg-white rounded-2xl border border-slate-100 shadow-sm p-6 space-y-4"
                  >
                    <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                      <div>
                        <p className="text-xs uppercase text-indigo-500 font-semibold">
                          Người học
                        </p>
                        <h3 className="text-xl font-bold text-slate-900">
                          {resolveUserName(progress.userId) || "N/A"}
                        </h3>
                        <p className="text-sm text-slate-500 mt-1">
                          Khoá:{" "}
                          <span className="font-medium text-slate-800">
                            {resolveCourseName(progress.courseId)}
                          </span>
                        </p>
                      </div>
                      <div className="flex flex-wrap gap-2 items-center">
                        <StatPill
                          label="Lessons"
                          value={`${summary?.passedLessons ?? 0}/${
                            summary?.lessons.length ?? 0
                          }`}
                        />
                        <StatPill
                          label="Keypoints"
                          value={`${summary?.passedKeypoints ?? 0}/${
                            summary?.keypoints ?? 0
                          }`}
                        />
                        <StatPill
                          label="Exercises"
                          value={`${summary?.passedExercises ?? 0}/${
                            summary?.exercises ?? 0
                          }`}
                        />
                        <button
                          onClick={() =>
                            openConfirm(GradeResultType.COURSE, progress, {})
                          }
                          className="inline-flex items-center gap-1 text-sm px-3 py-2 rounded-lg border border-red-200 text-red-700 hover:bg-red-50 transition disabled:opacity-60"
                          disabled={
                            removing ===
                            `${GradeResultType.COURSE}-${progress.courseId}`
                          }
                        >
                          <TrashIcon className="h-4 w-4" />
                          {removing ===
                          `${GradeResultType.COURSE}-${progress.courseId}`
                            ? "Đang xoá..."
                            : "Xoá khoá học"}
                        </button>
                      </div>
                    </div>

                    <div className="space-y-4">
                      {lessons.map((lesson) => (
                        <div
                          key={lesson.lessonId}
                          className="border border-slate-100 rounded-xl p-4 bg-slate-50/60"
                        >
                          <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
                            <div>
                              <p className="text-xs uppercase text-slate-500">
                                Lesson
                              </p>
                              <h4 className="text-lg font-semibold text-slate-900">
                                {lessonTitles[lesson.lessonId] ||
                                  lesson.lessonId}
                              </h4>
                              <div className="flex items-center gap-3 text-sm text-slate-600 mt-1">
                                <span>
                                  Avg: {formatScore(lesson.averageScore)}
                                </span>
                                <StatusBadge passed={lesson.passed} />
                                {lesson.submittedAt && (
                                  <span className="text-xs text-slate-500">
                                    Nộp: {formatDate(lesson.submittedAt)}
                                  </span>
                                )}
                              </div>
                              {lesson.reviews && (
                                <p className="text-sm text-slate-600 mt-2 whitespace-pre-line">
                                  Nhận xét: {lesson.reviews}
                                </p>
                              )}
                            </div>
                            <button
                              onClick={() =>
                                openConfirm(GradeResultType.LESSON, progress, {
                                  lessonId: lesson.lessonId,
                                })
                              }
                              className="inline-flex items-center gap-1 text-sm px-3 py-2 rounded-lg border border-red-200 text-red-700 hover:bg-red-50 transition disabled:opacity-60"
                              disabled={
                                removing ===
                                `${GradeResultType.LESSON}-${lesson.lessonId}`
                              }
                            >
                              <TrashIcon className="h-4 w-4" />
                              {removing ===
                              `${GradeResultType.LESSON}-${lesson.lessonId}`
                                ? "Đang xoá..."
                                : "Xoá lesson"}
                            </button>
                          </div>

                          <div className="mt-3 space-y-3">
                            {(lesson.keypointsResult ?? []).map((kp) => (
                              <div
                                key={kp.keypointId}
                                className="border border-slate-100 rounded-lg p-3 bg-white"
                              >
                                <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
                                  <div>
                                    <p className="text-xs uppercase text-slate-500">
                                      Keypoint
                                    </p>
                                    <h5 className="text-base font-semibold text-slate-900">
                                      {keypointTitles[kp.keypointId] ||
                                        kp.keypointId}
                                    </h5>
                                    <div className="flex items-center gap-3 text-sm text-slate-600 mt-1">
                                      <span>
                                        Avg: {formatScore(kp.averageScore)}
                                      </span>
                                      <StatusBadge passed={kp.passed} />
                                      {kp.submittedAt && (
                                        <span className="text-xs text-slate-500">
                                          Nộp: {formatDate(kp.submittedAt)}
                                        </span>
                                      )}
                                    </div>
                                    {kp.reviews && (
                                      <p className="text-sm text-slate-600 mt-2 whitespace-pre-line">
                                        Nhận xét: {kp.reviews}
                                      </p>
                                    )}
                                  </div>
                                  <button
                                    onClick={() =>
                                      openConfirm(
                                        GradeResultType.KEYPOINT,
                                        progress,
                                        {
                                          lessonId: lesson.lessonId,
                                          keypointId: kp.keypointId,
                                        }
                                      )
                                    }
                                    className="inline-flex items-center gap-1 text-sm px-3 py-2 rounded-lg border border-red-200 text-red-700 hover:bg-red-50 transition disabled:opacity-60"
                                    disabled={
                                      removing ===
                                      `${GradeResultType.KEYPOINT}-${kp.keypointId}`
                                    }
                                  >
                                    <TrashIcon className="h-4 w-4" />
                                    {removing ===
                                    `${GradeResultType.KEYPOINT}-${kp.keypointId}`
                                      ? "Đang xoá..."
                                      : "Xoá keypoint"}
                                  </button>
                                </div>

                                <div className="mt-3 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2">
                                  {(kp.exercisesResult ?? []).map((ex) => (
                                    <div
                                      key={ex.exerciseId}
                                      className="border border-slate-100 rounded-lg p-3 bg-slate-50"
                                    >
                                      <div className="flex items-start justify-between gap-2">
                                        <div>
                                          <p className="text-xs uppercase text-slate-500">
                                            Exercise
                                          </p>
                                          <p className="font-semibold text-slate-900">
                                            {ex.exerciseId}
                                          </p>
                                          <div className="text-xs text-slate-600 mt-1 space-y-0.5">
                                            <p>
                                              Score: {formatScore(ex.score)}
                                            </p>
                                            <p>
                                              Đúng/Sai: {ex.numberOfCorrect}/
                                              {ex.numberOfIncorrect}
                                            </p>
                                            {ex.submittedAt && (
                                              <p className="text-slate-500">
                                                Nộp:{" "}
                                                {formatDate(ex.submittedAt)}
                                              </p>
                                            )}
                                          </div>
                                          <div className="mt-2">
                                            <StatusBadge passed={ex.passed} />
                                          </div>
                                          {ex.reviews && (
                                            <p className="text-xs text-slate-600 mt-2 whitespace-pre-line">
                                              Nhận xét: {ex.reviews}
                                            </p>
                                          )}
                                        </div>
                                        <button
                                          onClick={() =>
                                            openConfirm(
                                              GradeResultType.EXERCISE,
                                              progress,
                                              {
                                                lessonId: lesson.lessonId,
                                                keypointId: kp.keypointId,
                                                exerciseId: ex.exerciseId,
                                              }
                                            )
                                          }
                                          className="text-red-600 hover:text-red-700 disabled:opacity-60 text-sm"
                                          title="Xoá kết quả exercise"
                                          disabled={
                                            removing ===
                                            `${GradeResultType.EXERCISE}-${ex.exerciseId}`
                                          }
                                        >
                                          {removing ===
                                          `${GradeResultType.EXERCISE}-${ex.exerciseId}`
                                            ? "Đang xoá..."
                                            : "Xoá"}
                                        </button>
                                      </div>
                                    </div>
                                  ))}
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                );
              })}
              {(hasMore || loadingMore) && (
                <div className="flex justify-center">
                  <button
                    onClick={() => fetchProgress(page + 1, true)}
                    disabled={loadingMore}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-indigo-200 text-indigo-700 hover:bg-indigo-50 transition disabled:opacity-60"
                  >
                    {loadingMore ? (
                      <>
                        <ArrowPathIcon className="h-5 w-5 animate-spin" />
                        <span>Đang tải thêm...</span>
                      </>
                    ) : (
                      "Tải thêm kết quả"
                    )}
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
      {renderConfirmModal()}
    </>
  );
}
