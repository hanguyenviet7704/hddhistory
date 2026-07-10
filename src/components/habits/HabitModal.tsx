// src/components/habits/HabitModal.tsx
import React, { useEffect, useMemo, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Checkbox,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  MenuItem,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { IHabit, HabitPayload } from "../../types/interface/habit.interface";
import { HabitStatus } from "../../types/enum/habit.enum";
import { ISkillset } from "../../types/interface/skillset.interface";
import { ICourse } from "../../types/interface/course.interface";
import { ILesson } from "../../types/interface/lesson.interface";
import { IKeypoint } from "../../types/interface/keypoint.interface";
import { LessonType } from "../../types/enum/lesson.enum";
import { lessonService } from "../../services/lessonService";
import { keypointService } from "../../services/keypointService";
import { ITranslation } from "../../utils/translate";
import {
  cleanTranslation,
  getTranslationValue,
  updateTranslationValue,
} from "../../utils/translation";

interface Props {
  isOpen: boolean;
  initial?: IHabit | null;
  skillsets: ISkillset[];
  courses: ICourse[];
  onClose: () => void;
  onSubmit: (payload: HabitPayload, id?: string) => Promise<void>;
}

interface FormErrors {
  title?: string;
  skillsetId?: string;
  order?: string;
}

interface KeypointMeta {
  title: string;
  lessonId: string;
  lessonTitle: string;
  courseId: string;
}

export default function HabitModal({
  isOpen,
  initial = null,
  skillsets,
  courses,
  onClose,
  onSubmit,
}: Props) {
  // Multi-language handled like the rest of the admin: a single field bound to
  // the current UI language (header toggle → state.lang.code); the title object
  // accumulates all locales (en/vi/zh/ja/ko) as the language is switched.
  const lang = useSelector((state: RootState) => state.lang.code);

  const [title, setTitle] = useState<ITranslation>({});
  const [skillsetId, setSkillsetId] = useState("");
  const [status, setStatus] = useState<HabitStatus>(HabitStatus.DRAFT);
  const [defaultReminderTime, setDefaultReminderTime] = useState("");
  const [orderValue, setOrderValue] = useState("0");
  const [errors, setErrors] = useState<FormErrors>({});
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  // ---------- Suggested-in-keypoints picker ----------
  // Pragmatic UX: pick a course, then a lesson within it, then multi-select
  // which of that lesson's keypoints should suggest this habit. Selections
  // accumulate across lessons/courses (a habit can be suggested from
  // keypoints in several lessons), so we cache resolved titles per keypoint
  // id independently of which lesson is currently being browsed.
  const [keypointBrowseCourseId, setKeypointBrowseCourseId] = useState("");
  const [courseLessons, setCourseLessons] = useState<ILesson[]>([]);
  const [lessonsLoading, setLessonsLoading] = useState(false);
  const [keypointBrowseLessonId, setKeypointBrowseLessonId] = useState("");
  const [lessonKeypoints, setLessonKeypoints] = useState<IKeypoint[]>([]);
  const [keypointsLoading, setKeypointsLoading] = useState(false);
  const [keypointSearch, setKeypointSearch] = useState("");
  const [selectedKeypointIds, setSelectedKeypointIds] = useState<string[]>([]);
  const [keypointMetaById, setKeypointMetaById] = useState<
    Record<string, KeypointMeta>
  >({});
  const [resolvingKeypoints, setResolvingKeypoints] = useState(false);

  const isEdit = !!initial?._id;

  const courseNameById = useMemo(() => {
    const map = new Map<string, string>();
    courses.forEach((course) => {
      map.set(course._id, getTranslationValue(course.title, lang));
    });
    return map;
  }, [courses, lang]);

  useEffect(() => {
    if (!isOpen) return;

    setErrors({});
    setSubmitError(null);
    setKeypointBrowseCourseId("");
    setKeypointBrowseLessonId("");
    setKeypointSearch("");

    if (initial) {
      setTitle(initial.title ?? {});
      setSkillsetId(initial.skillsetId ?? "");
      setStatus(initial.status ?? HabitStatus.DRAFT);
      setDefaultReminderTime(initial.defaultReminderTime ?? "");
      setOrderValue(
        initial.order !== undefined && initial.order !== null
          ? String(initial.order)
          : "0"
      );
      setSelectedKeypointIds(initial.keypointIds ?? []);
    } else {
      setTitle({});
      setSkillsetId("");
      setStatus(HabitStatus.DRAFT);
      setDefaultReminderTime("");
      setOrderValue("0");
      setSelectedKeypointIds([]);
    }
  }, [initial, isOpen]);

  // Resolve display titles for keypoints preselected on an existing habit
  // (they may belong to lessons the admin hasn't browsed to yet). Keypoints
  // don't carry their own lesson/course ref, so these resolve to a bare
  // title — no "Course · Lesson" breadcrumb — unlike ones picked by browsing.
  useEffect(() => {
    if (!isOpen || selectedKeypointIds.length === 0) return;

    const idsToResolve = selectedKeypointIds.filter((id) => !keypointMetaById[id]);
    if (idsToResolve.length === 0) return;

    let cancelled = false;
    setResolvingKeypoints(true);

    Promise.allSettled(idsToResolve.map((id) => keypointService.getById(id)))
      .then((results) => {
        if (cancelled) return;
        const next: Record<string, KeypointMeta> = {};
        results.forEach((result, index) => {
          if (result.status !== "fulfilled") return;
          const envelope: any = result.value;
          const keypoint: IKeypoint | undefined =
            envelope?.data?.data ?? envelope?.data;
          if (!keypoint) return;
          next[idsToResolve[index]] = {
            title: getTranslationValue(keypoint.title, lang) || "Untitled keypoint",
            lessonId: "",
            lessonTitle: "",
            courseId: "",
          };
        });
        if (Object.keys(next).length > 0) {
          setKeypointMetaById((prev) => ({ ...prev, ...next }));
        }
      })
      .catch((err) => console.error("Failed to resolve keypoint titles", err))
      .finally(() => {
        if (!cancelled) setResolvingKeypoints(false);
      });

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isOpen, selectedKeypointIds]);

  // Load the browsed course's lessons whenever the course selector changes.
  useEffect(() => {
    setKeypointBrowseLessonId("");
    setLessonKeypoints([]);

    if (!keypointBrowseCourseId) {
      setCourseLessons([]);
      return;
    }

    let cancelled = false;
    setLessonsLoading(true);

    lessonService
      .getList({
        courseId: keypointBrowseCourseId,
        type: LessonType.LESSON,
        page: 1,
        take: 500,
      })
      .then((res: any) => {
        if (cancelled) return;
        const items: ILesson[] = res?.data?.items ?? [];
        setCourseLessons(items);
      })
      .catch((err) => {
        console.error("Failed to load lessons for course", err);
        if (!cancelled) setCourseLessons([]);
      })
      .finally(() => {
        if (!cancelled) setLessonsLoading(false);
      });

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [keypointBrowseCourseId]);

  // Load the browsed lesson's keypoints (embedded on the full lesson detail,
  // unlike the lightweight list response) whenever the lesson selector changes.
  useEffect(() => {
    if (!keypointBrowseLessonId) {
      setLessonKeypoints([]);
      return;
    }

    let cancelled = false;
    setKeypointsLoading(true);
    const lessonTitle =
      getTranslationValue(
        courseLessons.find((l) => l._id === keypointBrowseLessonId)?.title,
        lang
      ) || "Untitled lesson";

    lessonService
      .getById(keypointBrowseLessonId)
      .then((res: any) => {
        if (cancelled) return;
        const lesson: ILesson | undefined = res?.data?.data ?? res?.data;
        const keypoints = lesson?.keypoints ?? [];
        setLessonKeypoints(keypoints);
        setKeypointMetaById((prev) => {
          const next = { ...prev };
          keypoints.forEach((keypoint) => {
            next[keypoint._id] = {
              title: getTranslationValue(keypoint.title, lang) || "Untitled keypoint",
              lessonId: keypointBrowseLessonId,
              lessonTitle,
              courseId: keypointBrowseCourseId,
            };
          });
          return next;
        });
      })
      .catch((err) => {
        console.error("Failed to load keypoints for lesson", err);
        if (!cancelled) setLessonKeypoints([]);
      })
      .finally(() => {
        if (!cancelled) setKeypointsLoading(false);
      });

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [keypointBrowseLessonId]);

  const filteredLessonKeypoints = useMemo(() => {
    const term = keypointSearch.trim().toLowerCase();
    if (!term) return lessonKeypoints;
    return lessonKeypoints.filter((keypoint) =>
      getTranslationValue(keypoint.title, lang).toLowerCase().includes(term)
    );
  }, [lessonKeypoints, keypointSearch, lang]);

  const toggleKeypoint = (keypointId: string) => {
    setSelectedKeypointIds((prev) =>
      prev.includes(keypointId)
        ? prev.filter((id) => id !== keypointId)
        : [...prev, keypointId]
    );
  };

  const keypointChipLabel = (keypointId: string) => {
    const meta = keypointMetaById[keypointId];
    if (!meta) return "Loading…";
    const courseName = meta.courseId ? courseNameById.get(meta.courseId) : undefined;
    const prefix = [courseName, meta.lessonTitle || undefined].filter(Boolean).join(" · ");
    return prefix ? `${prefix} · ${meta.title}` : meta.title;
  };

  const validate = (): FormErrors => {
    const nextErrors: FormErrors = {};

    if (!cleanTranslation(title)) {
      nextErrors.title = "Title is required in at least one language";
    }
    if (!skillsetId) {
      nextErrors.skillsetId = "Skillset is required";
    }
    if (orderValue.trim() !== "" && Number.isNaN(Number(orderValue))) {
      nextErrors.order = "Order must be a number";
    }

    return nextErrors;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const nextErrors = validate();
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) return;

    const cleanedTitle = cleanTranslation(title) ?? {};
    const trimmedOrder = orderValue.trim();

    const payload: HabitPayload = {
      title: cleanedTitle,
      skillsetId,
      status,
      keypointIds: selectedKeypointIds,
      ...(defaultReminderTime && { defaultReminderTime }),
      ...(trimmedOrder !== "" && { order: Number(trimmedOrder) }),
    };

    setSubmitting(true);
    setSubmitError(null);
    try {
      await onSubmit(payload, initial?._id);
    } catch (err: any) {
      setSubmitError(
        err?.response?.data?.message ??
        `Failed to ${isEdit ? "update" : "create"} habit`
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Dialog open={isOpen} onClose={onClose} fullWidth maxWidth="md">
      <DialogTitle>{isEdit ? "Edit habit" : "Create habit"}</DialogTitle>
      <form onSubmit={handleSubmit}>
        <DialogContent dividers>
          <Stack spacing={2.5}>
            {submitError && <Alert severity="error">{submitError}</Alert>}

            <TextField
              label={`Title (${lang.toUpperCase()})`}
              value={title[lang] ?? ""}
              onChange={(e) => {
                setTitle((prev) => updateTranslationValue(prev, lang, e.target.value));
                if (errors.title) setErrors((prev) => ({ ...prev, title: undefined }));
              }}
              error={!!errors.title}
              helperText={
                errors.title ??
                "Switch the language in the top bar to add other locales"
              }
              fullWidth
              size="small"
              required
            />

            <TextField
              select
              label="Skillset"
              value={skillsetId}
              onChange={(e) => {
                setSkillsetId(e.target.value);
                if (errors.skillsetId)
                  setErrors((prev) => ({ ...prev, skillsetId: undefined }));
              }}
              error={!!errors.skillsetId}
              helperText={errors.skillsetId}
              fullWidth
              size="small"
              required
            >
              {skillsets.length === 0 && (
                <MenuItem value="" disabled>
                  No skillsets available
                </MenuItem>
              )}
              {skillsets.map((skillset) => (
                <MenuItem key={skillset._id} value={skillset._id}>
                  {getTranslationValue(skillset.title, lang)}
                </MenuItem>
              ))}
            </TextField>

            <TextField
              select
              label="Status"
              value={status}
              onChange={(e) => setStatus(e.target.value as HabitStatus)}
              fullWidth
              size="small"
              required
            >
              <MenuItem value={HabitStatus.DRAFT}>Draft</MenuItem>
              <MenuItem value={HabitStatus.PUBLISHED}>Published</MenuItem>
            </TextField>

            <TextField
              label="Default reminder time"
              type="time"
              value={defaultReminderTime}
              onChange={(e) => setDefaultReminderTime(e.target.value)}
              InputLabelProps={{ shrink: true }}
              helperText="Optional, HH:mm"
              fullWidth
              size="small"
            />

            <TextField
              label="Order"
              type="number"
              value={orderValue}
              onChange={(e) => setOrderValue(e.target.value)}
              error={!!errors.order}
              helperText={errors.order ?? "Lower numbers sort first"}
              fullWidth
              size="small"
            />

            <Divider />

            <Box>
              <Typography variant="subtitle2" className="mb-1">
                Suggested in keypoints
              </Typography>
              <Typography variant="body2" color="text.secondary" className="mb-3">
                Choose a course, then a lesson within it, then select which of
                its keypoints should suggest this habit. Optional — leave
                empty if this habit is not tied to specific keypoints.
              </Typography>

              <TextField
                select
                label="Browse lessons in course"
                value={keypointBrowseCourseId}
                onChange={(e) => setKeypointBrowseCourseId(e.target.value)}
                fullWidth
                size="small"
                className="mb-2"
              >
                <MenuItem value="">Select a course</MenuItem>
                {courses.map((course) => (
                  <MenuItem key={course._id} value={course._id}>
                    {getTranslationValue(course.title, lang)}
                  </MenuItem>
                ))}
              </TextField>

              {!keypointBrowseCourseId ? (
                <Typography variant="body2" color="text.secondary">
                  Select a course above to see its lessons.
                </Typography>
              ) : (
                <TextField
                  select
                  label="Browse keypoints in lesson"
                  value={keypointBrowseLessonId}
                  onChange={(e) => {
                    setKeypointBrowseLessonId(e.target.value);
                    setKeypointSearch("");
                  }}
                  fullWidth
                  size="small"
                  className="mb-2"
                  disabled={lessonsLoading}
                  helperText={
                    lessonsLoading
                      ? "Loading lessons…"
                      : courseLessons.length === 0
                        ? "No lessons in this course yet."
                        : undefined
                  }
                >
                  <MenuItem value="">Select a lesson</MenuItem>
                  {courseLessons.map((lesson) => (
                    <MenuItem key={lesson._id} value={lesson._id}>
                      {getTranslationValue(lesson.title, lang) || "Untitled lesson"}
                    </MenuItem>
                  ))}
                </TextField>
              )}

              {keypointBrowseCourseId && keypointBrowseLessonId && (
                <>
                  <TextField
                    size="small"
                    label="Filter keypoints"
                    value={keypointSearch}
                    onChange={(e) => setKeypointSearch(e.target.value)}
                    fullWidth
                    className="mb-2"
                  />

                  <Box
                    sx={{
                      maxHeight: 220,
                      overflowY: "auto",
                      border: "1px solid",
                      borderColor: "divider",
                      borderRadius: 1,
                    }}
                  >
                    {keypointsLoading ? (
                      <Box className="p-3 flex items-center justify-center">
                        <CircularProgress size={20} />
                      </Box>
                    ) : filteredLessonKeypoints.length === 0 ? (
                      <Typography
                        variant="body2"
                        color="text.secondary"
                        className="p-3"
                      >
                        {lessonKeypoints.length === 0
                          ? "No keypoints in this lesson yet."
                          : "No keypoints match your filter."}
                      </Typography>
                    ) : (
                      <List dense disablePadding>
                        {filteredLessonKeypoints.map((keypoint) => {
                          const checked = selectedKeypointIds.includes(keypoint._id);
                          return (
                            <ListItemButton
                              key={keypoint._id}
                              onClick={() => toggleKeypoint(keypoint._id)}
                              dense
                            >
                              <ListItemIcon sx={{ minWidth: 36 }}>
                                <Checkbox
                                  edge="start"
                                  checked={checked}
                                  tabIndex={-1}
                                  disableRipple
                                  size="small"
                                />
                              </ListItemIcon>
                              <ListItemText
                                primary={
                                  getTranslationValue(keypoint.title, lang) ||
                                  "Untitled keypoint"
                                }
                              />
                            </ListItemButton>
                          );
                        })}
                      </List>
                    )}
                  </Box>
                </>
              )}

              <Box className="mt-3 flex items-center gap-2">
                <Typography variant="body2" fontWeight={500}>
                  Selected keypoints ({selectedKeypointIds.length})
                </Typography>
                {resolvingKeypoints && <CircularProgress size={14} />}
              </Box>

              {selectedKeypointIds.length === 0 ? (
                <Typography variant="body2" color="text.secondary">
                  No keypoints selected — this habit will not be suggested
                  from any keypoint.
                </Typography>
              ) : (
                <Box className="mt-1 flex flex-wrap gap-1">
                  {selectedKeypointIds.map((keypointId) => (
                    <Chip
                      key={keypointId}
                      size="small"
                      label={keypointChipLabel(keypointId)}
                      onDelete={() => toggleKeypoint(keypointId)}
                    />
                  ))}
                </Box>
              )}
            </Box>
          </Stack>
        </DialogContent>
        <DialogActions sx={{ px: 3, py: 2 }}>
          <Button onClick={onClose} disabled={submitting}>
            Cancel
          </Button>
          <Button
            type="submit"
            variant="contained"
            disabled={submitting}
            startIcon={submitting ? <CircularProgress size={16} /> : undefined}
          >
            {isEdit ? "Save changes" : "Create habit"}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
}
