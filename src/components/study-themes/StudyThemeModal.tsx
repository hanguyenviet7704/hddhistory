// src/components/study-themes/StudyThemeModal.tsx
import React, { useEffect, useState } from "react";
import {
  Alert,
  Autocomplete,
  Box,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  FormControlLabel,
  MenuItem,
  Slider,
  Stack,
  Switch,
  TextField,
  Typography,
} from "@mui/material";
import {
  IStudyTheme,
  StudyThemePayload,
} from "../../types/interface/study-theme.interface";
import { StudyThemeMode } from "../../types/enum/study-theme.enum";
import CloudflareFileUpload from "../files/CloudflareFileUpload";
import GradientColorListEditor from "./GradientColorListEditor";

const KEY_REGEX = /^[a-z0-9]+(?:[-_][a-z0-9]+)*$/i;

// The overlay is a black readability scrim. It's STORED as an 8-digit hex
// (#RRGGBBAA, unchanged for the app/API), but EDITED as a simple darkness
// percentage the admin drags on a slider — the alpha of black.
const overlayHexToPercent = (hex?: string): number => {
  const match = /^#(?:[0-9a-f]{6})([0-9a-f]{2})$/i.exec((hex ?? "").trim());
  if (!match) return 0;
  return Math.round((parseInt(match[1], 16) / 255) * 100);
};
const percentToOverlayHex = (pct: number): string | undefined => {
  const clamped = Math.max(0, Math.min(100, Math.round(pct)));
  if (clamped <= 0) return undefined; // 0% = no overlay
  const alpha = Math.round((clamped / 100) * 255)
    .toString(16)
    .padStart(2, "0");
  return `#000000${alpha}`;
};

const modeOptions: { value: StudyThemeMode; label: string; hint: string }[] = [
  {
    value: StudyThemeMode.DEFAULT,
    label: "Default",
    hint: "Uses the app's built-in background — no colour or media required.",
  },
  {
    value: StudyThemeMode.COLOR,
    label: "Color",
    hint: "A solid colour or gradient built from hex colours below.",
  },
  {
    value: StudyThemeMode.IMAGE,
    label: "Image",
    hint: "A still background image.",
  },
  {
    value: StudyThemeMode.VIDEO,
    label: "Video",
    hint: "A looping background video, optionally with ambient audio.",
  },
];

interface FormErrors {
  key?: string;
  name?: string;
  category?: string;
  gradient?: string;
  imageUrl?: string;
  videoUrl?: string;
  order?: string;
}

interface Props {
  open: boolean;
  initial?: IStudyTheme | null;
  existingCategories: string[];
  onClose: () => void;
  onSubmit: (payload: StudyThemePayload, key?: string) => Promise<void>;
}

export default function StudyThemeModal({
  open,
  initial = null,
  existingCategories,
  onClose,
  onSubmit,
}: Props) {
  const isEdit = !!initial?.key;

  const [key, setKey] = useState("");
  const [name, setName] = useState("");
  const [mode, setMode] = useState<StudyThemeMode>(StudyThemeMode.COLOR);
  const [category, setCategory] = useState("");
  const [gradient, setGradient] = useState<string[]>(["#FFFFFF"]);
  const [imageUrl, setImageUrl] = useState("");
  const [videoUrl, setVideoUrl] = useState("");
  const [audioUrl, setAudioUrl] = useState("");
  const [thumbUrl, setThumbUrl] = useState("");
  const [overlayPercent, setOverlayPercent] = useState(0);
  const [isDark, setIsDark] = useState(false);
  const [isActive, setIsActive] = useState(true);
  const [isPremium, setIsPremium] = useState(false);
  const [orderValue, setOrderValue] = useState("0");

  const [errors, setErrors] = useState<FormErrors>({});
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;

    setErrors({});
    setSubmitError(null);

    if (initial) {
      setKey(initial.key);
      setName(initial.name ?? "");
      setMode(initial.mode ?? StudyThemeMode.COLOR);
      setCategory(initial.category ?? "");
      setGradient(initial.gradient?.length ? initial.gradient : ["#FFFFFF"]);
      setImageUrl(initial.imageUrl ?? "");
      setVideoUrl(initial.videoUrl ?? "");
      setAudioUrl(initial.audioUrl ?? "");
      setThumbUrl(initial.thumbUrl ?? "");
      setOverlayPercent(overlayHexToPercent(initial.overlay));
      setIsDark(!!initial.isDark);
      setIsActive(initial.isActive ?? true);
      setIsPremium(initial.isPremium ?? false);
      setOrderValue(
        initial.order !== undefined && initial.order !== null
          ? String(initial.order)
          : "0"
      );
    } else {
      setKey("");
      setName("");
      setMode(StudyThemeMode.COLOR);
      setCategory("");
      setGradient(["#FFFFFF"]);
      setImageUrl("");
      setVideoUrl("");
      setAudioUrl("");
      setThumbUrl("");
      setOverlayPercent(0);
      setIsDark(false);
      setIsActive(true);
      setIsPremium(false);
      setOrderValue("0");
    }
  }, [initial, open]);

  const clearFieldError = (field: keyof FormErrors) => {
    setErrors((prev) => (prev[field] ? { ...prev, [field]: undefined } : prev));
  };

  const validate = (): FormErrors => {
    const next: FormErrors = {};
    const trimmedKey = key.trim();

    if (!isEdit) {
      if (!trimmedKey) {
        next.key = "Key is required";
      } else if (!KEY_REGEX.test(trimmedKey)) {
        next.key = "Use letters, numbers, hyphens or underscores only";
      }
    }

    if (!name.trim()) next.name = "Name is required";
    if (!category.trim()) next.category = "Category is required";

    if (mode === StudyThemeMode.COLOR) {
      const hasValidColor = gradient.some((c) =>
        /^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(c.trim())
      );
      if (!hasValidColor) {
        next.gradient = "Add at least one valid hex colour";
      }
    }

    if (mode === StudyThemeMode.IMAGE && !imageUrl.trim()) {
      next.imageUrl = "Upload or provide an image for image mode";
    }

    if (mode === StudyThemeMode.VIDEO && !videoUrl.trim()) {
      next.videoUrl = "Upload or provide a video for video mode";
    }

    if (orderValue.trim() !== "" && Number.isNaN(Number(orderValue))) {
      next.order = "Order must be a number";
    }

    return next;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const nextErrors = validate();
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) return;

    const trimmedOrder = orderValue.trim();
    const payload: StudyThemePayload = {
      key: key.trim(),
      name: name.trim(),
      mode,
      category: category.trim(),
      gradient:
        mode === StudyThemeMode.COLOR
          ? gradient.map((c) => c.trim()).filter(Boolean)
          : [],
      imageUrl: mode === StudyThemeMode.IMAGE ? imageUrl.trim() : imageUrl.trim() || undefined,
      videoUrl: mode === StudyThemeMode.VIDEO ? videoUrl.trim() : videoUrl.trim() || undefined,
      audioUrl: audioUrl.trim() || undefined,
      thumbUrl: thumbUrl.trim() || undefined,
      overlay: percentToOverlayHex(overlayPercent),
      isDark,
      isActive,
      isPremium,
      order: trimmedOrder === "" ? 0 : Number(trimmedOrder),
    };

    setSubmitting(true);
    setSubmitError(null);
    try {
      await onSubmit(payload, initial?.key);
    } catch (err: any) {
      if (err?.response?.status === 409) {
        setSubmitError("A theme with this key already exists — choose another slug");
      } else {
        setSubmitError(
          err?.response?.data?.message ??
            `Failed to ${isEdit ? "update" : "create"} study theme`
        );
      }
    } finally {
      setSubmitting(false);
    }
  };

  const overlayPreviewColor = percentToOverlayHex(overlayPercent) ?? "transparent";

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>
        {isEdit ? `Edit study theme — ${initial?.name}` : "Create study theme"}
      </DialogTitle>
      <form onSubmit={handleSubmit}>
        <DialogContent dividers>
          <Stack spacing={2.5}>
            {submitError && <Alert severity="error">{submitError}</Alert>}

            <TextField
              label="Key"
              value={key}
              onChange={(e) => {
                setKey(e.target.value);
                clearFieldError("key");
              }}
              error={!!errors.key}
              helperText={
                errors.key ??
                (isEdit
                  ? "Immutable slug used by the mobile app — cannot be changed"
                  : "Unique slug, e.g. ocean-sunset. Cannot be changed after creation")
              }
              disabled={isEdit}
              fullWidth
              size="small"
              required
            />

            <TextField
              label="Name"
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                clearFieldError("name");
              }}
              error={!!errors.name}
              helperText={errors.name}
              fullWidth
              size="small"
              required
            />

            <TextField
              select
              label="Mode"
              value={mode}
              onChange={(e) => setMode(e.target.value as StudyThemeMode)}
              fullWidth
              size="small"
              required
              helperText={modeOptions.find((m) => m.value === mode)?.hint}
            >
              {modeOptions.map((option) => (
                <MenuItem key={option.value} value={option.value}>
                  {option.label}
                </MenuItem>
              ))}
            </TextField>

            <Autocomplete
              freeSolo
              options={existingCategories}
              inputValue={category}
              onInputChange={(_e, value) => {
                setCategory(value);
                clearFieldError("category");
              }}
              renderInput={(params) => (
                <TextField
                  {...params}
                  label="Category"
                  size="small"
                  error={!!errors.category}
                  helperText={
                    errors.category ??
                    "Group heading shown in the app's picker, e.g. \"Nature\", \"Live\""
                  }
                  required
                />
              )}
            />

            {mode === StudyThemeMode.COLOR && (
              <GradientColorListEditor
                value={gradient}
                onChange={setGradient}
                error={errors.gradient}
              />
            )}

            {mode === StudyThemeMode.IMAGE && (
              <CloudflareFileUpload
                label="Background image"
                accept="image/*"
                initialUrl={imageUrl}
                onUrlChange={(url) => {
                  setImageUrl(url);
                  clearFieldError("imageUrl");
                }}
                uploadPayload={{ prefix: "", folder: "study-themes" }}
              />
            )}
            {errors.imageUrl && (
              <Typography variant="caption" color="error" sx={{ mt: -2 }}>
                {errors.imageUrl}
              </Typography>
            )}

            {mode === StudyThemeMode.VIDEO && (
              <>
                <CloudflareFileUpload
                  label="Background video"
                  accept="video/*"
                  initialUrl={videoUrl}
                  onUrlChange={(url) => {
                    setVideoUrl(url);
                    clearFieldError("videoUrl");
                  }}
                  uploadPayload={{ prefix: "", folder: "study-themes" }}
                />
                {errors.videoUrl && (
                  <Typography variant="caption" color="error" sx={{ mt: -2 }}>
                    {errors.videoUrl}
                  </Typography>
                )}
              </>
            )}

            <Divider />

            <CloudflareFileUpload
              label="Ambient audio (optional)"
              accept="audio/*"
              initialUrl={audioUrl}
              onUrlChange={setAudioUrl}
              uploadPayload={{ prefix: "", folder: "study-themes" }}
            />

            <CloudflareFileUpload
              label="Picker thumbnail (optional)"
              accept="image/*"
              initialUrl={thumbUrl}
              onUrlChange={setThumbUrl}
              uploadPayload={{ prefix: "", folder: "study-themes" }}
            />
            <Typography variant="caption" color="text.secondary" sx={{ mt: -2 }}>
              Shown in the app's theme picker and this admin table; falls back to a
              live preview when empty.
            </Typography>

            <Box>
              <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
                <Box sx={{ flex: 1 }}>
                  <Box
                    sx={{
                      display: "flex",
                      justifyContent: "space-between",
                      alignItems: "baseline",
                    }}
                  >
                    <Typography variant="body2">Overlay darkness</Typography>
                    <Typography variant="body2" color="text.secondary">
                      {overlayPercent}%
                    </Typography>
                  </Box>
                  <Slider
                    aria-label="Overlay darkness"
                    value={overlayPercent}
                    onChange={(_, v) =>
                      setOverlayPercent(Array.isArray(v) ? v[0] : v)
                    }
                    min={0}
                    max={100}
                    step={1}
                    valueLabelDisplay="auto"
                    valueLabelFormat={(v) => `${v}%`}
                  />
                </Box>
                {/* Swatch: black scrim at the chosen darkness, over a checkerboard. */}
                <Box
                  aria-hidden
                  sx={{
                    width: 40,
                    height: 40,
                    flexShrink: 0,
                    borderRadius: 1,
                    border: "1px solid",
                    borderColor: "divider",
                    backgroundImage:
                      "linear-gradient(45deg, #ccc 25%, transparent 25%), linear-gradient(-45deg, #ccc 25%, transparent 25%), linear-gradient(45deg, transparent 75%, #ccc 75%), linear-gradient(-45deg, transparent 75%, #ccc 75%)",
                    backgroundSize: "8px 8px",
                    backgroundPosition: "0 0, 0 4px, 4px -4px, -4px 0px",
                    position: "relative",
                    overflow: "hidden",
                  }}
                >
                  <Box
                    sx={{
                      position: "absolute",
                      inset: 0,
                      backgroundColor: overlayPreviewColor,
                    }}
                  />
                </Box>
              </Box>
              <Typography variant="caption" color="text.secondary">
                Darkens the background for readability (0% = none). A black scrim
                at the chosen opacity.
              </Typography>
            </Box>

            <Box sx={{ display: "flex", flexWrap: "wrap", gap: 3 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={isDark}
                    onChange={(e) => setIsDark(e.target.checked)}
                  />
                }
                label="Dark background (use light text)"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={isActive}
                    onChange={(e) => setIsActive(e.target.checked)}
                  />
                }
                label="Active (visible in the app)"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={isPremium}
                    onChange={(e) => setIsPremium(e.target.checked)}
                  />
                }
                label="Premium"
              />
            </Box>
            <Typography variant="caption" color="text.secondary" sx={{ mt: -2 }}>
              Locked behind the paywall in-app; hidden in onboarding.
            </Typography>

            <TextField
              label="Order"
              type="number"
              value={orderValue}
              onChange={(e) => setOrderValue(e.target.value)}
              error={!!errors.order}
              helperText={errors.order ?? "Lower numbers sort first in the picker"}
              size="small"
              sx={{ maxWidth: 200 }}
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
            startIcon={submitting ? <CircularProgress size={16} color="inherit" /> : undefined}
          >
            {isEdit ? "Save changes" : "Create theme"}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
}
