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
import { LessonType } from "../../types/enum/lesson.enum";
import { lessonService } from "../../services/lessonService";
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
  icon?: string;
  skillsetId?: string;
  order?: string;
}

interface LessonMeta {
  title: string;
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
  const [icon, setIcon] = useState("");
  const [skillsetId, setSkillsetId] = useState("");
  const [status, setStatus] = useState<HabitStatus>(HabitStatus.DRAFT);
  const [defaultReminderTime, setDefaultReminderTime] = useState("");
  const [orderValue, setOrderValue] = useState("0");
  const [errors, setErrors] = useState<FormErrors>({});
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  // ---------- Suggested-in-lessons picker ----------
  // Pragmatic UX: pick a course to narrow the list, then multi-select which
  // of that course's lessons should suggest this habit. Selections accumulate
  // across courses (a habit can be suggested from lessons in several
  // courses), so we cache resolved titles per lesson id independently of
  // which course is currently being browsed.
  const [lessonBrowseCourseId, setLessonBrowseCourseId] = useState("");
  const [courseLessons, setCourseLessons] = useState<ILesson[]>([]);
  const [lessonsLoading, setLessonsLoading] = useState(false);
  const [lessonSearch, setLessonSearch] = useState("");
  const [selectedLessonIds, setSelectedLessonIds] = useState<string[]>([]);
  const [lessonMetaById, setLessonMetaById] = useState<
    Record<string, LessonMeta>
  >({});
  const [resolvingLessons, setResolvingLessons] = useState(false);

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
    setLessonBrowseCourseId("");
    setLessonSearch("");

    if (initial) {
      setTitle(initial.title ?? {});
      setIcon(initial.icon ?? "");
      setSkillsetId(initial.skillsetId ?? "");
      setStatus(initial.status ?? HabitStatus.DRAFT);
      setDefaultReminderTime(initial.defaultReminderTime ?? "");
      setOrderValue(
        initial.order !== undefined && initial.order !== null
          ? String(initial.order)
          : "0"
      );
      setSelectedLessonIds(initial.lessonIds ?? []);
    } else {
      setTitle({});
      setIcon("");
      setSkillsetId("");
      setStatus(HabitStatus.DRAFT);
      setDefaultReminderTime("");
      setOrderValue("0");
      setSelectedLessonIds([]);
    }
  }, [initial, isOpen]);

  // Resolve display titles for lessons preselected on an existing habit
  // (they may belong to courses the admin hasn't browsed to yet).
  useEffect(() => {
    if (!isOpen || selectedLessonIds.length === 0) return;

    const idsToResolve = selectedLessonIds.filter((id) => !lessonMetaById[id]);
    if (idsToResolve.length === 0) return;

    let cancelled = false;
    setResolvingLessons(true);

    Promise.allSettled(idsToResolve.map((id) => lessonService.getById(id)))
      .then((results) => {
        if (cancelled) return;
        const next: Record<string, LessonMeta> = {};
        results.forEach((result, index) => {
          if (result.status !== "fulfilled") return;
          const envelope: any = result.value;
          const lesson: ILesson | undefined =
            envelope?.data?.data ?? envelope?.data;
          if (!lesson) return;
          next[idsToResolve[index]] = {
            title: getTranslationValue(lesson.title, lang) || "Untitled lesson",
            courseId: lesson.courseId,
          };
        });
        if (Object.keys(next).length > 0) {
          setLessonMetaById((prev) => ({ ...prev, ...next }));
        }
      })
      .catch((err) => console.error("Failed to resolve lesson titles", err))
      .finally(() => {
        if (!cancelled) setResolvingLessons(false);
      });

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isOpen, selectedLessonIds]);

  // Load the browsed course's lessons whenever the course selector changes.
  useEffect(() => {
    if (!lessonBrowseCourseId) {
      setCourseLessons([]);
      return;
    }

    let cancelled = false;
    setLessonsLoading(true);

    lessonService
      .getList({
        courseId: lessonBrowseCourseId,
        type: LessonType.LESSON,
        page: 1,
        take: 500,
      })
      .then((res: any) => {
        if (cancelled) return;
        const items: ILesson[] = res?.data?.items ?? [];
        setCourseLessons(items);
        setLessonMetaById((prev) => {
          const next = { ...prev };
          items.forEach((lesson) => {
            next[lesson._id] = {
              title: getTranslationValue(lesson.title, lang) || "Untitled lesson",
              courseId: lesson.courseId,
            };
          });
          return next;
        });
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
  }, [lessonBrowseCourseId]);

  const filteredCourseLessons = useMemo(() => {
    const term = lessonSearch.trim().toLowerCase();
    if (!term) return courseLessons;
    return courseLessons.filter((lesson) =>
      getTranslationValue(lesson.title, lang).toLowerCase().includes(term)
    );
  }, [courseLessons, lessonSearch, lang]);

  const toggleLesson = (lessonId: string) => {
    setSelectedLessonIds((prev) =>
      prev.includes(lessonId)
        ? prev.filter((id) => id !== lessonId)
        : [...prev, lessonId]
    );
  };

  const lessonChipLabel = (lessonId: string) => {
    const meta = lessonMetaById[lessonId];
    if (!meta) return "Loading…";
    const courseName = courseNameById.get(meta.courseId);
    return courseName ? `${courseName} · ${meta.title}` : meta.title;
  };

  const validate = (): FormErrors => {
    const nextErrors: FormErrors = {};

    if (!cleanTranslation(title)) {
      nextErrors.title = "Title is required in at least one language";
    }
    if (!icon.trim()) {
      nextErrors.icon = "Icon is required";
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
      icon: icon.trim(),
      skillsetId,
      status,
      lessonIds: selectedLessonIds,
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
              label="Icon"
              value={icon}
              onChange={(e) => {
                setIcon(e.target.value);
                if (errors.icon) setErrors((prev) => ({ ...prev, icon: undefined }));
              }}
              error={!!errors.icon}
              helperText={errors.icon ?? "Single emoji, e.g. \u{1F375}"}
              placeholder="\u{1F375}"
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
                Suggested in lessons
              </Typography>
              <Typography variant="body2" color="text.secondary" className="mb-3">
                Choose a course to browse its lessons, then select which ones
                should suggest this habit. Optional — leave empty if this
                habit is not tied to specific lessons.
              </Typography>

              <TextField
                select
                label="Browse lessons in course"
                value={lessonBrowseCourseId}
                onChange={(e) => {
                  setLessonBrowseCourseId(e.target.value);
                  setLessonSearch("");
                }}
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

              {!lessonBrowseCourseId ? (
                <Typography variant="body2" color="text.secondary">
                  Select a course above to see its lessons.
                </Typography>
              ) : (
                <>
                  <TextField
                    size="small"
                    label="Filter lessons"
                    value={lessonSearch}
                    onChange={(e) => setLessonSearch(e.target.value)}
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
                    {lessonsLoading ? (
                      <Box className="p-3 flex items-center justify-center">
                        <CircularProgress size={20} />
                      </Box>
                    ) : filteredCourseLessons.length === 0 ? (
                      <Typography
                        variant="body2"
                        color="text.secondary"
                        className="p-3"
                      >
                        {courseLessons.length === 0
                          ? "No lessons in this course yet."
                          : "No lessons match your filter."}
                      </Typography>
                    ) : (
                      <List dense disablePadding>
                        {filteredCourseLessons.map((lesson) => {
                          const checked = selectedLessonIds.includes(lesson._id);
                          return (
                            <ListItemButton
                              key={lesson._id}
                              onClick={() => toggleLesson(lesson._id)}
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
                                  getTranslationValue(lesson.title, lang) ||
                                  "Untitled lesson"
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
                  Selected lessons ({selectedLessonIds.length})
                </Typography>
                {resolvingLessons && <CircularProgress size={14} />}
              </Box>

              {selectedLessonIds.length === 0 ? (
                <Typography variant="body2" color="text.secondary">
                  No lessons selected — this habit will not be suggested from
                  any lesson.
                </Typography>
              ) : (
                <Box className="mt-1 flex flex-wrap gap-1">
                  {selectedLessonIds.map((lessonId) => (
                    <Chip
                      key={lessonId}
                      size="small"
                      label={lessonChipLabel(lessonId)}
                      onDelete={() => toggleLesson(lessonId)}
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
