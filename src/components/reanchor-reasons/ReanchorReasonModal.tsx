// src/components/reanchor-reasons/ReanchorReasonModal.tsx
import React, { useEffect, useState } from "react";
import {
  Alert,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  MenuItem,
  Stack,
  TextField,
} from "@mui/material";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import {
  IReanchorReason,
  ReanchorReasonPayload,
} from "../../types/interface/reanchor-reason.interface";
import { ReanchorReasonStatus } from "../../types/enum/reanchor-reason.enum";
import { ICourse } from "../../types/interface/course.interface";
import { ITranslation } from "../../utils/translate";
import {
  cleanTranslation,
  getTranslationValue,
  updateTranslationValue,
} from "../../utils/translation";

interface Props {
  isOpen: boolean;
  initial?: IReanchorReason | null;
  courses: ICourse[];
  onClose: () => void;
  onSubmit: (payload: ReanchorReasonPayload, id?: string) => Promise<void>;
}

interface FormErrors {
  courseId?: string;
  reason?: string;
  order?: string;
}

export default function ReanchorReasonModal({
  isOpen,
  initial = null,
  courses,
  onClose,
  onSubmit,
}: Props) {
  // Multi-language handled like the rest of the admin: a single field bound to
  // the current UI language (header toggle -> state.lang.code); the reason
  // object accumulates all locales (en/vi/zh/ja/ko) as the language is
  // switched.
  const lang = useSelector((state: RootState) => state.lang.code);

  const [courseId, setCourseId] = useState("");
  const [reason, setReason] = useState<ITranslation>({});
  const [status, setStatus] = useState<ReanchorReasonStatus>(
    ReanchorReasonStatus.DRAFT
  );
  const [orderValue, setOrderValue] = useState("0");
  const [errors, setErrors] = useState<FormErrors>({});
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const isEdit = !!initial?._id;

  useEffect(() => {
    if (!isOpen) return;

    setErrors({});
    setSubmitError(null);

    if (initial) {
      setCourseId(initial.courseId ?? "");
      setReason(initial.reason ?? {});
      setStatus(initial.status ?? ReanchorReasonStatus.DRAFT);
      setOrderValue(
        initial.order !== undefined && initial.order !== null
          ? String(initial.order)
          : "0"
      );
    } else {
      setCourseId("");
      setReason({});
      setStatus(ReanchorReasonStatus.DRAFT);
      setOrderValue("0");
    }
  }, [initial, isOpen]);

  const validate = (): FormErrors => {
    const nextErrors: FormErrors = {};

    if (!courseId) {
      nextErrors.courseId = "Course is required";
    }
    if (!cleanTranslation(reason)) {
      nextErrors.reason = "Reason is required in at least one language";
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

    const cleanedReason = cleanTranslation(reason) ?? {};
    const trimmedOrder = orderValue.trim();

    const payload: ReanchorReasonPayload = {
      courseId,
      reason: cleanedReason,
      status,
      ...(trimmedOrder !== "" && { order: Number(trimmedOrder) }),
    };

    setSubmitting(true);
    setSubmitError(null);
    try {
      await onSubmit(payload, initial?._id);
    } catch (err: any) {
      setSubmitError(
        err?.response?.data?.message ??
          `Failed to ${isEdit ? "update" : "create"} re-anchor reason`
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Dialog open={isOpen} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>
        {isEdit ? "Edit re-anchor reason" : "Create re-anchor reason"}
      </DialogTitle>
      <form onSubmit={handleSubmit}>
        <DialogContent dividers>
          <Stack spacing={2.5}>
            {submitError && <Alert severity="error">{submitError}</Alert>}

            <TextField
              select
              label="Course"
              value={courseId}
              onChange={(e) => {
                setCourseId(e.target.value);
                if (errors.courseId)
                  setErrors((prev) => ({ ...prev, courseId: undefined }));
              }}
              error={!!errors.courseId}
              helperText={errors.courseId}
              fullWidth
              size="small"
              required
            >
              {courses.length === 0 && (
                <MenuItem value="" disabled>
                  No courses available
                </MenuItem>
              )}
              {courses.map((course) => (
                <MenuItem key={course._id} value={course._id}>
                  {getTranslationValue(course.title, lang)}
                </MenuItem>
              ))}
            </TextField>

            <TextField
              label={`Reason (${lang.toUpperCase()})`}
              value={reason[lang] ?? ""}
              onChange={(e) => {
                setReason((prev) =>
                  updateTranslationValue(prev, lang, e.target.value)
                );
                if (errors.reason)
                  setErrors((prev) => ({ ...prev, reason: undefined }));
              }}
              error={!!errors.reason}
              helperText={
                errors.reason ??
                "Switch the language in the top bar to add other locales"
              }
              fullWidth
              size="small"
              multiline
              minRows={2}
              required
            />

            <TextField
              select
              label="Status"
              value={status}
              onChange={(e) =>
                setStatus(e.target.value as ReanchorReasonStatus)
              }
              fullWidth
              size="small"
              required
            >
              <MenuItem value={ReanchorReasonStatus.DRAFT}>Draft</MenuItem>
              <MenuItem value={ReanchorReasonStatus.PUBLISHED}>
                Published
              </MenuItem>
            </TextField>

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
            {isEdit ? "Save changes" : "Create reason"}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
}
