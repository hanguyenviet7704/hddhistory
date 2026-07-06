// src/components/habits/HabitModal.tsx
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
import { IHabit, HabitPayload } from "../../types/interface/habit.interface";
import { HabitStatus } from "../../types/enum/habit.enum";
import { ISkillset } from "../../types/interface/skillset.interface";
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
  onClose: () => void;
  onSubmit: (payload: HabitPayload, id?: string) => Promise<void>;
}

interface FormErrors {
  title?: string;
  icon?: string;
  skillsetId?: string;
  order?: string;
}

export default function HabitModal({
  isOpen,
  initial = null,
  skillsets,
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

  const isEdit = !!initial?._id;

  useEffect(() => {
    if (!isOpen) return;

    setErrors({});
    setSubmitError(null);

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
    } else {
      setTitle({});
      setIcon("");
      setSkillsetId("");
      setStatus(HabitStatus.DRAFT);
      setDefaultReminderTime("");
      setOrderValue("0");
    }
  }, [initial, isOpen]);

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
    <Dialog open={isOpen} onClose={onClose} fullWidth maxWidth="sm">
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
