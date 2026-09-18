// src/pages/onboarding-config/OnboardingConfigPage.tsx
//
// Admin editor for the admin-editable onboarding config — one singleton
// document that drives copy/images/ordering for the app's 8 editable
// onboarding screens (splash + course-pick are out of scope; course-pick's
// list is dynamic). See meup-api/plans/260721-onboarding-redesign/plan.md §5.
//
// Job: an operator loads the current config, edits copy/images/order for any
// screen, and saves the whole document back in one PUT. There is no list to
// filter — this page always edits the single config.
import { useMemo, useState, useEffect } from "react";
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Alert,
  Box,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Divider,
  FormControlLabel,
  IconButton,
  Paper,
  Skeleton,
  Switch,
  TextField,
  Typography,
} from "@mui/material";
import { Add, Delete, Download, ExpandMore, Upload } from "@mui/icons-material";
import {
  DndContext,
  DragEndEvent,
  KeyboardSensor,
  PointerSensor,
  closestCenter,
  useSensor,
  useSensors,
} from "@dnd-kit/core";
import {
  SortableContext,
  arrayMove,
  sortableKeyboardCoordinates,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import SortableItem from "../../components/common/SortableItem";
import CloudflareFileUpload from "../../components/files/CloudflareFileUpload";
import { onboardingConfigService } from "../../services/onboardingConfigService";
import { useNotification } from "../../utils/hooks/useNotification";
import { downloadJson, pickJsonFile } from "../../utils/jsonTransfer";
import type {
  OnboardingAgeConfig,
  OnboardingBrainConfig,
  OnboardingConfig,
  OnboardingConfigPayload,
  OnboardingDesireConfig,
  OnboardingHabitConfig,
  OnboardingHowConfig,
  OnboardingLoadingConfig,
  OnboardingMultilang,
  OnboardingNameConfig,
  OnboardingNotifConfig,
  OnboardingPathsConfig,
  OnboardingPickConfig,
  OnboardingReminderConfig,
  OnboardingThemeConfig,
  OnboardingWelcomeConfig,
} from "../../types/interface/onboarding-config.interface";

// ---- Client-only drafts ----------------------------------------------
// Array items carry a stable `_localId` for React keys / drag identity
// (mirrors the existing Learning Paths pattern in OnboardingManagemant.tsx).
// The business `key` field stays editable and is only required to be
// non-empty/unique at save time — it is never guaranteed unique mid-edit.
let localIdCounter = 0;
const nextLocalId = () => `local-${++localIdCounter}`;

interface DeckItemDraft {
  _localId: string;
  key: string;
  label: OnboardingMultilang;
  imageUrl: string;
}

interface AgeOptionDraft {
  _localId: string;
  key: string;
  label: OnboardingMultilang;
}

interface SymptomDraft {
  _localId: string;
  key: string;
  label: OnboardingMultilang;
}

interface PathItemDraft {
  _localId: string;
  key: string;
  label: OnboardingMultilang;
  iconKey: string;
  iconUrl: string;
  symptoms: SymptomDraft[];
}

interface ConfigDraft {
  welcome: Omit<OnboardingWelcomeConfig, "deck"> & { deck: DeckItemDraft[] };
  name: OnboardingNameConfig;
  age: Omit<OnboardingAgeConfig, "options"> & { options: AgeOptionDraft[] };
  paths: Omit<OnboardingPathsConfig, "items"> & { items: PathItemDraft[] };
  brain: OnboardingBrainConfig;
  habit: OnboardingHabitConfig;
  desire: OnboardingDesireConfig;
  how: OnboardingHowConfig;
  reminder: OnboardingReminderConfig;
  loading: OnboardingLoadingConfig;
  notif: OnboardingNotifConfig;
  pick: OnboardingPickConfig;
  theme: OnboardingThemeConfig;
  showPaywallAfterOnboarding: boolean;
}

const ml = (value?: OnboardingMultilang): OnboardingMultilang => ({
  en: value?.en || "",
  vi: value?.vi || "",
});

// Fetched config (or nothing, on first run) → editable draft. Every nested
// object is defaulted so controlled inputs never render `value=undefined`.
const toDraft = (config: OnboardingConfig | null): ConfigDraft => ({
  welcome: {
    titlePrefix: ml(config?.welcome?.titlePrefix),
    titleBrand: config?.welcome?.titleBrand || "",
    subtitle: ml(config?.welcome?.subtitle),
    ctaLabel: ml(config?.welcome?.ctaLabel),
    deck: (config?.welcome?.deck || [])
      .slice()
      .sort((a, b) => (a.order ?? 0) - (b.order ?? 0))
      .map((item) => ({
        _localId: nextLocalId(),
        key: item.key || "",
        label: ml(item.label),
        imageUrl: item.imageUrl || "",
      })),
  },
  name: {
    heading: ml(config?.name?.heading),
    headingHighlight: ml(config?.name?.headingHighlight),
    helper: ml(config?.name?.helper),
    inputHint: ml(config?.name?.inputHint),
    ctaLabel: ml(config?.name?.ctaLabel),
    iconUrl: config?.name?.iconUrl || "",
  },
  age: {
    headingTemplate: ml(config?.age?.headingTemplate),
    headingHighlight: ml(config?.age?.headingHighlight),
    ctaLabel: ml(config?.age?.ctaLabel),
    options: (config?.age?.options || [])
      .slice()
      .sort((a, b) => (a.order ?? 0) - (b.order ?? 0))
      .map((item) => ({
        _localId: nextLocalId(),
        key: item.key || "",
        label: ml(item.label),
      })),
    iconUrl: config?.age?.iconUrl || "",
  },
  paths: {
    heading: ml(config?.paths?.heading),
    headingHighlight: ml(config?.paths?.headingHighlight),
    helper: ml(config?.paths?.helper),
    maxSelect: config?.paths?.maxSelect ?? 2,
    items: (config?.paths?.items || [])
      .slice()
      .sort((a, b) => (a.order ?? 0) - (b.order ?? 0))
      .map((item) => ({
        _localId: nextLocalId(),
        key: item.key || "",
        label: ml(item.label),
        iconKey: item.iconKey || "",
        iconUrl: item.iconUrl || "",
        symptoms: (item.symptoms || [])
          .slice()
          .sort((a, b) => (a.order ?? 0) - (b.order ?? 0))
          .map((symptom) => ({
            _localId: nextLocalId(),
            key: symptom.key || "",
            label: ml(symptom.label),
          })),
      })),
  },
  brain: {
    heading: ml(config?.brain?.heading),
    headingHighlight: ml(config?.brain?.headingHighlight),
    headingSuffix: ml(config?.brain?.headingSuffix),
    unlockedPillTemplate: ml(config?.brain?.unlockedPillTemplate),
    moreTemplate: ml(config?.brain?.moreTemplate),
    imageUrl: config?.brain?.imageUrl || "",
  },
  habit: {
    heading: ml(config?.habit?.heading),
    headingHighlight: ml(config?.habit?.headingHighlight),
    subtitle: ml(config?.habit?.subtitle),
    ctaLabel: ml(config?.habit?.ctaLabel),
    iconUrl: config?.habit?.iconUrl || "",
  },
  desire: {
    heading: ml(config?.desire?.heading),
    headingHighlight: ml(config?.desire?.headingHighlight),
    helper: ml(config?.desire?.helper),
  },
  how: {
    eyebrow: ml(config?.how?.eyebrow),
    heading: ml(config?.how?.heading),
    headingHighlight: ml(config?.how?.headingHighlight),
    steps: (config?.how?.steps ?? []).map((s) => ({
      title: ml(s?.title),
      body: ml(s?.body),
    })),
    footer: ml(config?.how?.footer),
    ctaLabel: ml(config?.how?.ctaLabel),
  },
  reminder: {
    heading: ml(config?.reminder?.heading),
    headingHighlight: ml(config?.reminder?.headingHighlight),
    subtitle: ml(config?.reminder?.subtitle),
    timeSectionLabel: ml(config?.reminder?.timeSectionLabel),
    presets: (config?.reminder?.presets ?? []).map((p) => ({
      label: ml(p?.label),
      time: p?.time || "",
    })),
    ctaLabel: ml(config?.reminder?.ctaLabel),
    secondaryCtaLabel: ml(config?.reminder?.secondaryCtaLabel),
  },
  loading: {
    heading: ml(config?.loading?.heading),
    headingHighlight: ml(config?.loading?.headingHighlight),
    lines: (config?.loading?.lines ?? []).map((l) => ml(l)),
  },
  notif: {
    heading: ml(config?.notif?.heading),
    headingHighlight: ml(config?.notif?.headingHighlight),
    subtitle: ml(config?.notif?.subtitle),
    cardTitle: ml(config?.notif?.cardTitle),
    cardBody: ml(config?.notif?.cardBody),
    cardTimestamp: ml(config?.notif?.cardTimestamp),
    ctaLabel: ml(config?.notif?.ctaLabel),
    iconUrl: config?.notif?.iconUrl || "",
  },
  pick: {
    eyebrow: ml(config?.pick?.eyebrow),
    heading: ml(config?.pick?.heading),
    headingHighlight: ml(config?.pick?.headingHighlight),
    label: ml(config?.pick?.label),
    primaryCta: ml(config?.pick?.primaryCta),
    secondaryCta: ml(config?.pick?.secondaryCta),
    iconUrl: config?.pick?.iconUrl || "",
  },
  theme: {
    titlePrefix: ml(config?.theme?.titlePrefix),
    titleHighlight: ml(config?.theme?.titleHighlight),
    subtitle: ml(config?.theme?.subtitle),
    ctaLabel: ml(config?.theme?.ctaLabel),
    helper: ml(config?.theme?.helper),
  },
  showPaywallAfterOnboarding: config?.showPaywallAfterOnboarding ?? false,
});

// Draft → save payload. `order` is derived from list position here, not
// tracked while editing.
const buildPayload = (draft: ConfigDraft): OnboardingConfigPayload => ({
  welcome: {
    titlePrefix: draft.welcome.titlePrefix,
    titleBrand: draft.welcome.titleBrand,
    subtitle: draft.welcome.subtitle,
    ctaLabel: draft.welcome.ctaLabel,
    deck: draft.welcome.deck.map((item, index) => ({
      key: item.key.trim(),
      label: item.label,
      imageUrl: item.imageUrl,
      order: index,
    })),
  },
  name: draft.name,
  age: {
    headingTemplate: draft.age.headingTemplate,
    headingHighlight: draft.age.headingHighlight,
    ctaLabel: draft.age.ctaLabel,
    options: draft.age.options.map((item, index) => ({
      key: item.key.trim(),
      label: item.label,
      order: index,
    })),
    iconUrl: draft.age.iconUrl,
  },
  paths: {
    heading: draft.paths.heading,
    headingHighlight: draft.paths.headingHighlight,
    helper: draft.paths.helper,
    maxSelect: draft.paths.maxSelect,
    items: draft.paths.items.map((item, index) => ({
      key: item.key.trim(),
      label: item.label,
      iconKey: item.iconKey,
      iconUrl: item.iconUrl,
      order: index,
      symptoms: item.symptoms.map((symptom, symptomIndex) => ({
        key: symptom.key.trim(),
        label: symptom.label,
        order: symptomIndex,
      })),
    })),
  },
  brain: draft.brain,
  habit: draft.habit,
  desire: draft.desire,
  how: draft.how,
  reminder: draft.reminder,
  loading: draft.loading,
  notif: draft.notif,
  pick: draft.pick,
  theme: draft.theme,
  showPaywallAfterOnboarding: draft.showPaywallAfterOnboarding,
});

// Minimal shape guard for an imported onboarding-config.json — the file only
// needs to look like a config (at least one of the known top-level screen
// keys) so a completely unrelated JSON file doesn't silently wipe the draft.
const CONFIG_SCREEN_KEYS = [
  "welcome",
  "name",
  "age",
  "paths",
  "brain",
  "habit",
  "desire",
  "how",
  "reminder",
  "loading",
  "notif",
  "pick",
  "theme",
] as const;

const isPlausibleConfig = (value: unknown): value is Partial<OnboardingConfig> => {
  if (!value || typeof value !== "object" || Array.isArray(value)) return false;
  return CONFIG_SCREEN_KEYS.some((k) => k in (value as Record<string, unknown>));
};

// Generic add/update/remove/reorder for the 3 reorderable lists (welcome
// deck, age options, path items) — they all share the "keyed, orderable
// draft item" shape, so one factory replaces 4 near-identical handlers x 3.
function makeListHelpers<T extends { _localId: string }>(
  getList: (draft: ConfigDraft) => T[],
  setList: (draft: ConfigDraft, list: T[]) => ConfigDraft,
  setDraft: React.Dispatch<React.SetStateAction<ConfigDraft | null>>
) {
  const update = (updater: (list: T[]) => T[]) =>
    setDraft((prev) => (prev ? setList(prev, updater(getList(prev))) : prev));

  return {
    add: (item: T) => update((list) => [...list, item]),
    updateItem: (localId: string, updater: (item: T) => T) =>
      update((list) =>
        list.map((i) => (i._localId === localId ? updater(i) : i))
      ),
    remove: (localId: string) =>
      update((list) => list.filter((i) => i._localId !== localId)),
    reorder: (event: DragEndEvent) => {
      const { active, over } = event;
      if (!over || active.id === over.id) return;
      update((list) => {
        const oldIndex = list.findIndex((i) => i._localId === active.id);
        const newIndex = list.findIndex((i) => i._localId === over.id);
        if (oldIndex === -1 || newIndex === -1) return list;
        return arrayMove(list, oldIndex, newIndex);
      });
    },
  };
}

// Every key/label list needs a non-empty, unique `key` before saving — it
// drives lookups on the app side (icon assets, path matching).
function useKeyErrors(
  items: { _localId: string; key: string }[]
): Record<string, string> {
  return useMemo(() => {
    const errors: Record<string, string> = {};
    const seen = new Map<string, string>();
    items.forEach((item) => {
      const normalized = item.key.trim();
      if (!normalized) {
        errors[item._localId] = "Key is required";
        return;
      }
      const existing = seen.get(normalized);
      if (existing) {
        errors[item._localId] = "Key must be unique";
        errors[existing] = "Key must be unique";
      } else {
        seen.set(normalized, item._localId);
      }
    });
    return errors;
  }, [items]);
}

// ---- Shared field ------------------------------------------------------
function MultilangField({
  label,
  value,
  onChange,
  helperText,
  multiline,
}: {
  label: string;
  value: OnboardingMultilang;
  onChange: (value: OnboardingMultilang) => void;
  helperText?: string;
  multiline?: boolean;
}) {
  return (
    <Box>
      <Box className="flex flex-wrap gap-3">
        <TextField
          label={`${label} (en)`}
          value={value?.en || ""}
          onChange={(e) => onChange({ ...value, en: e.target.value })}
          size="small"
          multiline={multiline}
          minRows={multiline ? 2 : undefined}
          sx={{ flex: 1, minWidth: 220 }}
        />
        <TextField
          label={`${label} (vi)`}
          value={value?.vi || ""}
          onChange={(e) => onChange({ ...value, vi: e.target.value })}
          size="small"
          multiline={multiline}
          minRows={multiline ? 2 : undefined}
          sx={{ flex: 1, minWidth: 220 }}
        />
      </Box>
      {helperText && (
        <Typography
          variant="caption"
          color="text.secondary"
          sx={{ display: "block", mt: 0.5 }}
        >
          {helperText}
        </Typography>
      )}
    </Box>
  );
}

const rowSx = {
  p: 2,
  mb: 1.5,
  borderRadius: 1,
  bgcolor: "grey.50",
  border: "1px solid",
  borderColor: "divider",
} as const;

function DeckItemRow({
  item,
  index,
  error,
  onChange,
  onRemove,
}: {
  item: DeckItemDraft;
  index: number;
  error?: string;
  onChange: (updater: (item: DeckItemDraft) => DeckItemDraft) => void;
  onRemove: () => void;
}) {
  return (
    <SortableItem id={item._localId}>
      <Box sx={rowSx}>
        <Box className="flex items-center justify-between mb-2">
          <Typography variant="subtitle2" color="text.secondary">
            Card {index + 1}
          </Typography>
          <IconButton
            size="small"
            color="error"
            aria-label={`Delete deck card ${index + 1}`}
            onClick={onRemove}
          >
            <Delete fontSize="small" />
          </IconButton>
        </Box>
        <TextField
          label="Key"
          value={item.key}
          onChange={(e) =>
            onChange((prev) => ({ ...prev, key: e.target.value }))
          }
          error={Boolean(error)}
          helperText={error || "Stable id for this card"}
          size="small"
          sx={{ minWidth: 200, mb: 1.5 }}
        />
        {/* No label field: the deck cards show no text caption in-app — the
            card artwork already carries its "… better" caption baked in. */}
        <Box sx={{ maxWidth: 280 }}>
          <CloudflareFileUpload
            initialUrl={item.imageUrl}
            onUrlChange={(imageUrl) =>
              onChange((prev) => ({ ...prev, imageUrl }))
            }
            label="Card image"
            uploadPayload={{ prefix: "welcome-deck", folder: "onboarding" }}
          />
        </Box>
      </Box>
    </SortableItem>
  );
}

function AgeOptionRow({
  item,
  index,
  error,
  onChange,
  onRemove,
}: {
  item: AgeOptionDraft;
  index: number;
  error?: string;
  onChange: (updater: (item: AgeOptionDraft) => AgeOptionDraft) => void;
  onRemove: () => void;
}) {
  return (
    <SortableItem id={item._localId}>
      <Box sx={rowSx}>
        <Box className="flex items-center justify-between mb-2">
          <Typography variant="subtitle2" color="text.secondary">
            Option {index + 1}
          </Typography>
          <IconButton
            size="small"
            color="error"
            aria-label={`Delete option ${index + 1}`}
            onClick={onRemove}
          >
            <Delete fontSize="small" />
          </IconButton>
        </Box>
        <TextField
          label="Key"
          value={item.key}
          onChange={(e) =>
            onChange((prev) => ({ ...prev, key: e.target.value }))
          }
          error={Boolean(error)}
          helperText={error || "Stable id, e.g. TEEN, ADULT"}
          size="small"
          sx={{ minWidth: 200, mb: 1.5 }}
        />
        <MultilangField
          label="Label"
          value={item.label}
          onChange={(label) => onChange((prev) => ({ ...prev, label }))}
        />
      </Box>
    </SortableItem>
  );
}

function SymptomRow({
  item,
  index,
  error,
  onChange,
  onRemove,
}: {
  item: SymptomDraft;
  index: number;
  error?: string;
  onChange: (updater: (item: SymptomDraft) => SymptomDraft) => void;
  onRemove: () => void;
}) {
  return (
    <SortableItem id={item._localId}>
      <Box sx={{ ...rowSx, bgcolor: "background.paper" }}>
        <Box className="flex items-center justify-between mb-2">
          <Typography variant="subtitle2" color="text.secondary">
            Symptom {index + 1}
          </Typography>
          <IconButton
            size="small"
            color="error"
            aria-label={`Delete symptom ${index + 1}`}
            onClick={onRemove}
          >
            <Delete fontSize="small" />
          </IconButton>
        </Box>
        <TextField
          label="Key"
          value={item.key}
          onChange={(e) =>
            onChange((prev) => ({ ...prev, key: e.target.value }))
          }
          error={Boolean(error)}
          helperText={error || "Stable id, e.g. MOTIVATION_DISAPPEARS"}
          size="small"
          sx={{ minWidth: 260, mb: 1.5 }}
        />
        <MultilangField
          label="Label"
          value={item.label}
          onChange={(label) => onChange((prev) => ({ ...prev, label }))}
        />
      </Box>
    </SortableItem>
  );
}

// Reusable symptom list editor (key + en/vi label, add / remove / drag-reorder)
// bound to ONE path item's `symptoms`. Used both inside PathItemRow (the Paths
// section) and in the Symptoms (screen 7) section's grouped-by-path view — both
// edit the SAME `paths.items[].symptoms` data, so they stay in sync.
function SymptomListEditor({
  symptoms,
  symptomErrors,
  dndSensors,
  onChange,
}: {
  symptoms: SymptomDraft[];
  symptomErrors: Record<string, string>;
  dndSensors: ReturnType<typeof useSensors>;
  onChange: (updater: (list: SymptomDraft[]) => SymptomDraft[]) => void;
}) {
  const addSymptom = () =>
    onChange((list) => [
      ...list,
      { _localId: nextLocalId(), key: "", label: {} },
    ]);
  const updateSymptomItem = (
    localId: string,
    updater: (item: SymptomDraft) => SymptomDraft
  ) =>
    onChange((list) =>
      list.map((s) => (s._localId === localId ? updater(s) : s))
    );
  const removeSymptom = (localId: string) =>
    onChange((list) => list.filter((s) => s._localId !== localId));
  const reorderSymptoms = (event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;
    onChange((list) => {
      const oldIndex = list.findIndex((s) => s._localId === active.id);
      const newIndex = list.findIndex((s) => s._localId === over.id);
      if (oldIndex === -1 || newIndex === -1) return list;
      return arrayMove(list, oldIndex, newIndex);
    });
  };

  return (
    <>
      <Box className="flex items-center justify-between mb-1.5">
        <Typography variant="subtitle2">Symptoms</Typography>
        <Typography variant="caption" color="text.secondary">
          Drag to reorder
        </Typography>
      </Box>

      {symptoms.length === 0 ? (
        <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
          No symptoms yet.
        </Typography>
      ) : (
        <DndContext
          sensors={dndSensors}
          collisionDetection={closestCenter}
          onDragEnd={reorderSymptoms}
        >
          <SortableContext
            items={symptoms.map((s) => s._localId)}
            strategy={verticalListSortingStrategy}
          >
            {symptoms.map((symptom, symptomIndex) => (
              <SymptomRow
                key={symptom._localId}
                item={symptom}
                index={symptomIndex}
                error={symptomErrors[symptom._localId]}
                onChange={(updater) =>
                  updateSymptomItem(symptom._localId, updater)
                }
                onRemove={() => removeSymptom(symptom._localId)}
              />
            ))}
          </SortableContext>
        </DndContext>
      )}

      <Button
        onClick={addSymptom}
        variant="outlined"
        size="small"
        startIcon={<Add />}
      >
        Add symptom
      </Button>
    </>
  );
}

function PathItemRow({
  item,
  index,
  error,
  symptomErrors,
  dndSensors,
  onChange,
  onRemove,
}: {
  item: PathItemDraft;
  index: number;
  error?: string;
  symptomErrors: Record<string, string>;
  dndSensors: ReturnType<typeof useSensors>;
  onChange: (updater: (item: PathItemDraft) => PathItemDraft) => void;
  onRemove: () => void;
}) {
  return (
    <SortableItem id={item._localId}>
      <Box sx={rowSx}>
        <Box className="flex items-center justify-between mb-2">
          <Typography variant="subtitle2" color="text.secondary">
            Path {index + 1}
          </Typography>
          <IconButton
            size="small"
            color="error"
            aria-label={`Delete path ${index + 1}`}
            onClick={onRemove}
          >
            <Delete fontSize="small" />
          </IconButton>
        </Box>
        <Box className="flex flex-wrap gap-3 mb-1.5">
          <TextField
            label="Key"
            value={item.key}
            onChange={(e) =>
              onChange((prev) => ({ ...prev, key: e.target.value }))
            }
            error={Boolean(error)}
            helperText={error || "Stable id, e.g. FEEL_BETTER"}
            size="small"
            sx={{ minWidth: 200 }}
          />
          <TextField
            label="Icon key"
            value={item.iconKey}
            onChange={(e) =>
              onChange((prev) => ({ ...prev, iconKey: e.target.value }))
            }
            helperText="Bundled asset key, e.g. cat-heart"
            size="small"
            sx={{ minWidth: 200 }}
          />
        </Box>
        <Box sx={{ mb: 1.5 }}>
          <MultilangField
            label="Label"
            value={item.label}
            onChange={(label) => onChange((prev) => ({ ...prev, label }))}
          />
        </Box>
        <Box sx={{ maxWidth: 280, mb: 1.5 }}>
          <CloudflareFileUpload
            initialUrl={item.iconUrl}
            onUrlChange={(iconUrl) =>
              onChange((prev) => ({ ...prev, iconUrl }))
            }
            label="Icon URL override (optional)"
            uploadPayload={{ prefix: "paths-icon", folder: "onboarding" }}
          />
        </Box>

        <Divider sx={{ my: 1.5 }} />
        <SymptomListEditor
          symptoms={item.symptoms}
          symptomErrors={symptomErrors}
          dndSensors={dndSensors}
          onChange={(updater) =>
            onChange((prev) => ({ ...prev, symptoms: updater(prev.symptoms) }))
          }
        />
      </Box>
    </SortableItem>
  );
}

export default function OnboardingConfigPage() {
  const { showSuccess, showError } = useNotification();

  const [draft, setDraft] = useState<ConfigDraft | null>(null);
  const [hasSavedConfig, setHasSavedConfig] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [importPreview, setImportPreview] = useState<Partial<OnboardingConfig> | null>(
    null
  );

  const dndSensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates })
  );

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const config = await onboardingConfigService.getConfig();
      setDraft(toDraft(config));
      setHasSavedConfig(Boolean(config));
    } catch (err: any) {
      const message =
        err?.response?.data?.message || "Failed to load onboarding config";
      setError(message);
      showError(message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const deckHelpers = makeListHelpers<DeckItemDraft>(
    (d) => d.welcome.deck,
    (d, list) => ({ ...d, welcome: { ...d.welcome, deck: list } }),
    setDraft
  );
  const ageOptionHelpers = makeListHelpers<AgeOptionDraft>(
    (d) => d.age.options,
    (d, list) => ({ ...d, age: { ...d.age, options: list } }),
    setDraft
  );
  const pathItemHelpers = makeListHelpers<PathItemDraft>(
    (d) => d.paths.items,
    (d, list) => ({ ...d, paths: { ...d.paths, items: list } }),
    setDraft
  );

  const deckErrors = useKeyErrors(draft?.welcome.deck || []);
  const ageOptionErrors = useKeyErrors(draft?.age.options || []);
  const pathItemErrors = useKeyErrors(draft?.paths.items || []);
  // Symptom keys drive the mobile app's tracking lookup across all paths, so
  // uniqueness is validated globally (flattened across every path item), not
  // just within one path's own symptom list.
  const symptomErrors = useKeyErrors(
    draft?.paths.items.flatMap((item) => item.symptoms) || []
  );
  const hasErrors =
    Object.keys(deckErrors).length > 0 ||
    Object.keys(ageOptionErrors).length > 0 ||
    Object.keys(pathItemErrors).length > 0 ||
    Object.keys(symptomErrors).length > 0;

  const updateWelcome = (
    updater: (w: ConfigDraft["welcome"]) => ConfigDraft["welcome"]
  ) => setDraft((prev) => (prev ? { ...prev, welcome: updater(prev.welcome) } : prev));
  const updateName = (
    updater: (n: OnboardingNameConfig) => OnboardingNameConfig
  ) => setDraft((prev) => (prev ? { ...prev, name: updater(prev.name) } : prev));
  const updateAge = (
    updater: (a: ConfigDraft["age"]) => ConfigDraft["age"]
  ) => setDraft((prev) => (prev ? { ...prev, age: updater(prev.age) } : prev));
  const updatePaths = (
    updater: (p: ConfigDraft["paths"]) => ConfigDraft["paths"]
  ) => setDraft((prev) => (prev ? { ...prev, paths: updater(prev.paths) } : prev));
  const updateBrain = (
    updater: (b: OnboardingBrainConfig) => OnboardingBrainConfig
  ) => setDraft((prev) => (prev ? { ...prev, brain: updater(prev.brain) } : prev));
  const updateHabit = (
    updater: (h: OnboardingHabitConfig) => OnboardingHabitConfig
  ) => setDraft((prev) => (prev ? { ...prev, habit: updater(prev.habit) } : prev));
  const updateDesire = (
    updater: (d: OnboardingDesireConfig) => OnboardingDesireConfig
  ) => setDraft((prev) => (prev ? { ...prev, desire: updater(prev.desire) } : prev));
  const updateHow = (
    updater: (h: OnboardingHowConfig) => OnboardingHowConfig
  ) => setDraft((prev) => (prev ? { ...prev, how: updater(prev.how) } : prev));
  const updateReminder = (
    updater: (r: OnboardingReminderConfig) => OnboardingReminderConfig
  ) =>
    setDraft((prev) =>
      prev ? { ...prev, reminder: updater(prev.reminder) } : prev
    );
  const updateLoading = (
    updater: (l: OnboardingLoadingConfig) => OnboardingLoadingConfig
  ) =>
    setDraft((prev) =>
      prev ? { ...prev, loading: updater(prev.loading) } : prev
    );
  const updateNotif = (
    updater: (n: OnboardingNotifConfig) => OnboardingNotifConfig
  ) => setDraft((prev) => (prev ? { ...prev, notif: updater(prev.notif) } : prev));
  const updatePick = (
    updater: (p: OnboardingPickConfig) => OnboardingPickConfig
  ) => setDraft((prev) => (prev ? { ...prev, pick: updater(prev.pick) } : prev));
  const updateTheme = (
    updater: (t: OnboardingThemeConfig) => OnboardingThemeConfig
  ) => setDraft((prev) => (prev ? { ...prev, theme: updater(prev.theme) } : prev));

  const handleSave = async () => {
    if (!draft) return;
    if (hasErrors) {
      showError("Fix empty or duplicate keys before saving.");
      return;
    }
    setSaving(true);
    try {
      const updated = await onboardingConfigService.updateConfig(
        buildPayload(draft)
      );
      setDraft(toDraft(updated));
      setHasSavedConfig(true);
      showSuccess("Onboarding config saved");
    } catch (err: any) {
      showError(
        err?.response?.data?.message || "Failed to save onboarding config"
      );
    } finally {
      setSaving(false);
    }
  };

  // Exports exactly what a Save would send (buildPayload already excludes
  // _id/createdAt/updatedAt — they live outside ConfigDraft).
  const handleExport = () => {
    if (!draft) return;
    downloadJson("onboarding-config.json", buildPayload(draft));
    showSuccess("Onboarding config exported");
  };

  const handleImportClick = async () => {
    try {
      const parsed = await pickJsonFile();
      if (!isPlausibleConfig(parsed)) {
        showError("Import file must contain an onboarding config object.");
        return;
      }
      setImportPreview(parsed);
    } catch (err: any) {
      // A cancelled file picker isn't a real error — nothing to surface.
      if (err?.message !== "No file selected") {
        showError(err?.message ?? "Could not read that file.");
      }
    }
  };

  // Loads the file into the draft only — nothing is sent to the server until
  // the operator reviews it and presses "Save changes" (or discards it).
  const handleConfirmImport = () => {
    if (!importPreview) return;
    setDraft(toDraft(importPreview as OnboardingConfig));
    setImportPreview(null);
    showSuccess(
      'Onboarding config loaded into the draft — review it, then press "Save changes" to persist it.'
    );
  };

  return (
    <Box className="p-6">
      <Box
        sx={{
          position: "sticky",
          top: 0,
          zIndex: 10,
          bgcolor: "grey.100",
          pb: 2,
        }}
      >
        <Box className="flex items-center justify-between gap-3 flex-wrap">
          <Box>
            <Typography variant="h5">Onboarding config</Typography>
            <Typography variant="body2" color="text.secondary">
              Copy, images and ordering for the app's onboarding screens.
            </Typography>
          </Box>
          <Box className="flex items-center gap-2">
            <Button
              variant="outlined"
              startIcon={<Download fontSize="small" />}
              onClick={handleExport}
              disabled={loading || saving || !draft}
            >
              Export
            </Button>
            <Button
              variant="outlined"
              startIcon={<Upload fontSize="small" />}
              onClick={handleImportClick}
              disabled={loading || saving}
            >
              Import
            </Button>
            <Button
              variant="outlined"
              onClick={load}
              disabled={loading || saving}
            >
              Discard changes
            </Button>
            <Button
              variant="contained"
              onClick={handleSave}
              disabled={loading || saving || !draft}
              sx={{ minWidth: 148 }}
            >
              {saving ? (
                <CircularProgress size={18} color="inherit" sx={{ mr: 1 }} />
              ) : null}
              Save changes
            </Button>
          </Box>
        </Box>
      </Box>

      {loading ? (
        <Box>
          {Array.from({ length: 8 }).map((_, i) => (
            <Skeleton
              key={i}
              variant="rectangular"
              height={56}
              sx={{ mb: 1.5, borderRadius: 1 }}
            />
          ))}
        </Box>
      ) : error ? (
        <Paper className="p-8 text-center">
          <Typography color="error" className="mb-3">
            {error}
          </Typography>
          <Button variant="outlined" onClick={load}>
            Retry
          </Button>
        </Paper>
      ) : !draft ? null : (
        <>
          {!hasSavedConfig && (
            <Alert severity="info" sx={{ mb: 2 }}>
              No onboarding config saved yet — fill in the fields below and
              save to create it.
            </Alert>
          )}

          {/* Welcome */}
          <Accordion defaultExpanded>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Welcome
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <Box className="flex flex-col gap-3">
                <MultilangField
                  label="Title prefix"
                  value={draft.welcome.titlePrefix}
                  onChange={(v) =>
                    updateWelcome((w) => ({ ...w, titlePrefix: v }))
                  }
                />
                <TextField
                  label="Title brand"
                  value={draft.welcome.titleBrand}
                  onChange={(e) =>
                    updateWelcome((w) => ({
                      ...w,
                      titleBrand: e.target.value,
                    }))
                  }
                  helperText="Brand word rendered in the gradient H1, e.g. MeUp"
                  size="small"
                  sx={{ maxWidth: 320 }}
                />
                <MultilangField
                  label="Subtitle"
                  value={draft.welcome.subtitle}
                  onChange={(v) =>
                    updateWelcome((w) => ({ ...w, subtitle: v }))
                  }
                />
                <MultilangField
                  label="CTA label"
                  value={draft.welcome.ctaLabel}
                  onChange={(v) =>
                    updateWelcome((w) => ({ ...w, ctaLabel: v }))
                  }
                />

                <Divider sx={{ my: 1 }} />

                <Box className="flex items-center justify-between">
                  <Typography variant="subtitle2">Deck cards</Typography>
                  <Typography variant="caption" color="text.secondary">
                    Drag to reorder
                  </Typography>
                </Box>

                {draft.welcome.deck.length === 0 ? (
                  <Typography variant="body2" color="text.secondary">
                    No deck cards yet.
                  </Typography>
                ) : (
                  <DndContext
                    sensors={dndSensors}
                    collisionDetection={closestCenter}
                    onDragEnd={deckHelpers.reorder}
                  >
                    <SortableContext
                      items={draft.welcome.deck.map((d) => d._localId)}
                      strategy={verticalListSortingStrategy}
                    >
                      {draft.welcome.deck.map((item, index) => (
                        <DeckItemRow
                          key={item._localId}
                          item={item}
                          index={index}
                          error={deckErrors[item._localId]}
                          onChange={(updater) =>
                            deckHelpers.updateItem(item._localId, updater)
                          }
                          onRemove={() => deckHelpers.remove(item._localId)}
                        />
                      ))}
                    </SortableContext>
                  </DndContext>
                )}

                <Button
                  onClick={() =>
                    deckHelpers.add({
                      _localId: nextLocalId(),
                      key: "",
                      label: {},
                      imageUrl: "",
                    })
                  }
                  variant="outlined"
                  size="small"
                  startIcon={<Add />}
                  sx={{ alignSelf: "flex-start" }}
                >
                  Add deck card
                </Button>
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* Name */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Name
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <Box className="flex flex-col gap-3">
                <MultilangField
                  label="Heading"
                  value={draft.name.heading}
                  onChange={(v) => updateName((n) => ({ ...n, heading: v }))}
                />
                <MultilangField
                  label="Heading highlight"
                  value={draft.name.headingHighlight || {}}
                  onChange={(v) =>
                    updateName((n) => ({ ...n, headingHighlight: v }))
                  }
                  helperText="Gradient-highlighted trailing part of the title, e.g. we call you?"
                />
                <MultilangField
                  label="Helper"
                  value={draft.name.helper}
                  onChange={(v) => updateName((n) => ({ ...n, helper: v }))}
                />
                <MultilangField
                  label="Input hint"
                  value={draft.name.inputHint}
                  onChange={(v) =>
                    updateName((n) => ({ ...n, inputHint: v }))
                  }
                />
                <MultilangField
                  label="CTA label"
                  value={draft.name.ctaLabel}
                  onChange={(v) => updateName((n) => ({ ...n, ctaLabel: v }))}
                />

                <Divider sx={{ my: 1 }} />
                <Box sx={{ maxWidth: 280 }}>
                  <CloudflareFileUpload
                    initialUrl={draft.name.iconUrl}
                    onUrlChange={(iconUrl) =>
                      updateName((n) => ({ ...n, iconUrl }))
                    }
                    label="Icon"
                    uploadPayload={{ prefix: "name-icon", folder: "onboarding" }}
                  />
                  <Typography
                    variant="caption"
                    color="text.secondary"
                    sx={{ display: "block", mt: 0.5 }}
                  >
                    Leave empty for default.
                  </Typography>
                </Box>
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* Age */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Age
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <Box className="flex flex-col gap-3">
                <MultilangField
                  label="Heading template"
                  value={draft.age.headingTemplate}
                  onChange={(v) =>
                    updateAge((a) => ({ ...a, headingTemplate: v }))
                  }
                  helperText="Supports a {name} placeholder, e.g. Nice to meet you, {name}!"
                />
                <MultilangField
                  label="Heading highlight"
                  value={draft.age.headingHighlight || {}}
                  onChange={(v) =>
                    updateAge((a) => ({ ...a, headingHighlight: v }))
                  }
                  helperText="Gradient-highlighted trailing part of the title"
                />
                <MultilangField
                  label="CTA label"
                  value={draft.age.ctaLabel}
                  onChange={(v) => updateAge((a) => ({ ...a, ctaLabel: v }))}
                />

                <Divider sx={{ my: 1 }} />
                <Box sx={{ maxWidth: 280 }}>
                  <CloudflareFileUpload
                    initialUrl={draft.age.iconUrl}
                    onUrlChange={(iconUrl) =>
                      updateAge((a) => ({ ...a, iconUrl }))
                    }
                    label="Icon"
                    uploadPayload={{ prefix: "age-icon", folder: "onboarding" }}
                  />
                  <Typography
                    variant="caption"
                    color="text.secondary"
                    sx={{ display: "block", mt: 0.5 }}
                  >
                    Leave empty for default.
                  </Typography>
                </Box>

                <Divider sx={{ my: 1 }} />
                <Typography variant="subtitle2">
                  Life-stage options
                </Typography>

                {draft.age.options.length === 0 ? (
                  <Typography variant="body2" color="text.secondary">
                    No options yet.
                  </Typography>
                ) : (
                  <DndContext
                    sensors={dndSensors}
                    collisionDetection={closestCenter}
                    onDragEnd={ageOptionHelpers.reorder}
                  >
                    <SortableContext
                      items={draft.age.options.map((o) => o._localId)}
                      strategy={verticalListSortingStrategy}
                    >
                      {draft.age.options.map((item, index) => (
                        <AgeOptionRow
                          key={item._localId}
                          item={item}
                          index={index}
                          error={ageOptionErrors[item._localId]}
                          onChange={(updater) =>
                            ageOptionHelpers.updateItem(
                              item._localId,
                              updater
                            )
                          }
                          onRemove={() =>
                            ageOptionHelpers.remove(item._localId)
                          }
                        />
                      ))}
                    </SortableContext>
                  </DndContext>
                )}

                <Button
                  onClick={() =>
                    ageOptionHelpers.add({
                      _localId: nextLocalId(),
                      key: "",
                      label: {},
                    })
                  }
                  variant="outlined"
                  size="small"
                  startIcon={<Add />}
                  sx={{ alignSelf: "flex-start" }}
                >
                  Add option
                </Button>
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* Paths (screen 4) */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Box>
                <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                  Câu 1 — Lĩnh vực (S4)
                </Typography>
                <Typography
                  variant="caption"
                  color="text.secondary"
                  sx={{ display: "block" }}
                >
                  heading/helper; danh sách path items là LEGACY cho app cũ,
                  app mới đọc Onboarding Taxonomy
                </Typography>
              </Box>
            </AccordionSummary>
            <AccordionDetails>
              <Box className="flex flex-col gap-3">
                <MultilangField
                  label="Heading"
                  value={draft.paths.heading}
                  onChange={(v) => updatePaths((p) => ({ ...p, heading: v }))}
                />
                <MultilangField
                  label="Heading highlight"
                  value={draft.paths.headingHighlight || {}}
                  onChange={(v) =>
                    updatePaths((p) => ({ ...p, headingHighlight: v }))
                  }
                  helperText="Gradient-highlighted trailing part of the title"
                />
                <MultilangField
                  label="Helper"
                  value={draft.paths.helper}
                  onChange={(v) => updatePaths((p) => ({ ...p, helper: v }))}
                />
                <TextField
                  label="Max selectable paths"
                  type="number"
                  value={draft.paths.maxSelect}
                  onChange={(e) =>
                    updatePaths((p) => ({
                      ...p,
                      maxSelect: Math.max(1, Number(e.target.value) || 1),
                    }))
                  }
                  size="small"
                  sx={{ maxWidth: 200 }}
                  inputProps={{ min: 1 }}
                />

                <Divider sx={{ my: 1 }} />
                <Box className="flex items-center justify-between">
                  <Typography variant="subtitle2">Paths</Typography>
                  <Typography variant="caption" color="text.secondary">
                    Drag to reorder
                  </Typography>
                </Box>

                {draft.paths.items.length === 0 ? (
                  <Typography variant="body2" color="text.secondary">
                    No paths yet.
                  </Typography>
                ) : (
                  <DndContext
                    sensors={dndSensors}
                    collisionDetection={closestCenter}
                    onDragEnd={pathItemHelpers.reorder}
                  >
                    <SortableContext
                      items={draft.paths.items.map((i) => i._localId)}
                      strategy={verticalListSortingStrategy}
                    >
                      {draft.paths.items.map((item, index) => (
                        <PathItemRow
                          key={item._localId}
                          item={item}
                          index={index}
                          error={pathItemErrors[item._localId]}
                          symptomErrors={symptomErrors}
                          dndSensors={dndSensors}
                          onChange={(updater) =>
                            pathItemHelpers.updateItem(item._localId, updater)
                          }
                          onRemove={() =>
                            pathItemHelpers.remove(item._localId)
                          }
                        />
                      ))}
                    </SortableContext>
                  </DndContext>
                )}

                <Button
                  onClick={() =>
                    pathItemHelpers.add({
                      _localId: nextLocalId(),
                      key: "",
                      label: {},
                      iconKey: "",
                      iconUrl: "",
                      symptoms: [],
                    })
                  }
                  variant="outlined"
                  size="small"
                  startIcon={<Add />}
                  sx={{ alignSelf: "flex-start" }}
                >
                  Add path
                </Button>
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* Path map (screen 6) — data key stays `brain` */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Box>
                <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                  Path map (screen 6)
                </Typography>
                <Typography
                  variant="caption"
                  color="text.secondary"
                  sx={{ display: "block" }}
                >
                  Heading shown on the path-map screen after path selection.
                </Typography>
              </Box>
            </AccordionSummary>
            <AccordionDetails>
              <Box className="flex flex-col gap-3">
                <MultilangField
                  label="Heading"
                  value={draft.brain.heading}
                  onChange={(v) => updateBrain((b) => ({ ...b, heading: v }))}
                />
                <MultilangField
                  label="Heading highlight"
                  value={draft.brain.headingHighlight || {}}
                  onChange={(v) =>
                    updateBrain((b) => ({ ...b, headingHighlight: v }))
                  }
                  helperText="Gradient-highlighted trailing part of the title"
                />
                <MultilangField
                  label="Heading suffix"
                  value={draft.brain.headingSuffix || {}}
                  onChange={(v) =>
                    updateBrain((b) => ({ ...b, headingSuffix: v }))
                  }
                  helperText="Plain-text closing part of the title, rendered after the highlight"
                />
                <MultilangField
                  label="Unlocked pill template"
                  value={draft.brain.unlockedPillTemplate}
                  onChange={(v) =>
                    updateBrain((b) => ({ ...b, unlockedPillTemplate: v }))
                  }
                  helperText="Copy for the pill listing unlocked paths"
                />
                <MultilangField
                  label="More template"
                  value={draft.brain.moreTemplate}
                  onChange={(v) =>
                    updateBrain((b) => ({ ...b, moreTemplate: v }))
                  }
                  helperText="e.g. {count} more waiting"
                />

                <Divider sx={{ my: 1 }} />
                <Box sx={{ maxWidth: 280 }}>
                  <CloudflareFileUpload
                    initialUrl={draft.brain.imageUrl}
                    onUrlChange={(imageUrl) =>
                      updateBrain((b) => ({ ...b, imageUrl }))
                    }
                    label="Hero image (optional)"
                    uploadPayload={{ prefix: "brain-image", folder: "onboarding" }}
                  />
                  <Typography
                    variant="caption"
                    color="text.secondary"
                    sx={{ display: "block", mt: 0.5 }}
                  >
                    Leave empty to use the app's default hexagon graphic.
                  </Typography>
                </Box>
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* Symptoms (screen 7) — data key stays `habit` */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Box>
                <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                  Câu 2 — Vấn đề (S5) — data key `habit`
                </Typography>
                <Typography
                  variant="caption"
                  color="text.secondary"
                  sx={{ display: "block" }}
                >
                  Heading + subtitle for the "which speaks to you"
                  symptom-selection screen.
                </Typography>
              </Box>
            </AccordionSummary>
            <AccordionDetails>
              <Box className="flex flex-col gap-3">
                <MultilangField
                  label="Heading"
                  value={draft.habit.heading}
                  onChange={(v) => updateHabit((h) => ({ ...h, heading: v }))}
                />
                <MultilangField
                  label="Heading highlight"
                  value={draft.habit.headingHighlight || {}}
                  onChange={(v) =>
                    updateHabit((h) => ({ ...h, headingHighlight: v }))
                  }
                  helperText="Gradient-highlighted trailing part of the title"
                />
                <MultilangField
                  label="Subtitle"
                  value={draft.habit.subtitle}
                  onChange={(v) =>
                    updateHabit((h) => ({ ...h, subtitle: v }))
                  }
                />
                <MultilangField
                  label="CTA label"
                  value={draft.habit.ctaLabel}
                  onChange={(v) =>
                    updateHabit((h) => ({ ...h, ctaLabel: v }))
                  }
                />

                <Divider sx={{ my: 1 }} />
                <Box sx={{ maxWidth: 280 }}>
                  <CloudflareFileUpload
                    initialUrl={draft.habit.iconUrl}
                    onUrlChange={(iconUrl) =>
                      updateHabit((h) => ({ ...h, iconUrl }))
                    }
                    label="Icon"
                    uploadPayload={{ prefix: "habit-icon", folder: "onboarding" }}
                  />
                  <Typography
                    variant="caption"
                    color="text.secondary"
                    sx={{ display: "block", mt: 0.5 }}
                  >
                    Leave empty for default.
                  </Typography>
                </Box>

                <Divider sx={{ my: 1 }} />
                <Box className="flex items-center justify-between">
                  <Typography variant="subtitle2">
                    Symptom items (grouped by path)
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Same data as the Paths section — edits here sync both ways.
                  </Typography>
                </Box>
                {draft.paths.items.length === 0 ? (
                  <Typography variant="body2" color="text.secondary">
                    No paths yet — add paths in the Paths section first.
                  </Typography>
                ) : (
                  draft.paths.items.map((pathItem) => (
                    <Box
                      key={pathItem._localId}
                      sx={{ ...rowSx, bgcolor: "background.paper" }}
                    >
                      <Typography
                        variant="subtitle2"
                        color="text.secondary"
                        sx={{ mb: 1 }}
                      >
                        {pathItem.label.en || pathItem.key || "Path"}
                      </Typography>
                      <SymptomListEditor
                        symptoms={pathItem.symptoms}
                        symptomErrors={symptomErrors}
                        dndSensors={dndSensors}
                        onChange={(updater) =>
                          pathItemHelpers.updateItem(
                            pathItem._localId,
                            (prev) => ({
                              ...prev,
                              symptoms: updater(prev.symptoms),
                            })
                          )
                        }
                      />
                    </Box>
                  ))
                )}
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* Desire (screen 6) */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Câu 3 — Mong muốn (S6)
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <Box className="flex flex-col gap-3">
                <MultilangField
                  label="Heading"
                  value={draft.desire.heading}
                  onChange={(v) =>
                    updateDesire((d) => ({ ...d, heading: v }))
                  }
                />
                <MultilangField
                  label="Heading highlight"
                  value={draft.desire.headingHighlight || {}}
                  onChange={(v) =>
                    updateDesire((d) => ({ ...d, headingHighlight: v }))
                  }
                  helperText="Gradient-highlighted trailing part of the title"
                />
                <MultilangField
                  label="Helper"
                  value={draft.desire.helper}
                  onChange={(v) => updateDesire((d) => ({ ...d, helper: v }))}
                />
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* How MeUp teaches (screen 7) */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                MeUp dạy thế nào (S7)
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <Box className="flex flex-col gap-3">
                <MultilangField
                  label="Eyebrow"
                  value={draft.how.eyebrow}
                  onChange={(v) => updateHow((h) => ({ ...h, eyebrow: v }))}
                />
                <MultilangField
                  label="Heading"
                  value={draft.how.heading}
                  onChange={(v) => updateHow((h) => ({ ...h, heading: v }))}
                />
                <MultilangField
                  label="Heading highlight"
                  value={draft.how.headingHighlight || {}}
                  onChange={(v) =>
                    updateHow((h) => ({ ...h, headingHighlight: v }))
                  }
                  helperText="Gradient-highlighted trailing part of the title"
                />

                <Divider sx={{ my: 1 }} />
                <Typography variant="subtitle2">Steps</Typography>

                {draft.how.steps.length === 0 ? (
                  <Typography variant="body2" color="text.secondary">
                    No steps yet.
                  </Typography>
                ) : (
                  draft.how.steps.map((step, index) => (
                    <Box key={index} sx={rowSx}>
                      <Box className="flex items-center justify-between mb-2">
                        <Typography variant="subtitle2">
                          Step {index + 1}
                        </Typography>
                        <IconButton
                          size="small"
                          onClick={() =>
                            updateHow((h) => ({
                              ...h,
                              steps: h.steps.filter((_, i) => i !== index),
                            }))
                          }
                        >
                          <Delete fontSize="small" />
                        </IconButton>
                      </Box>
                      <Box className="flex flex-col gap-3">
                        <MultilangField
                          label="Title"
                          value={step.title}
                          onChange={(v) =>
                            updateHow((h) => ({
                              ...h,
                              steps: h.steps.map((s, i) =>
                                i === index ? { ...s, title: v } : s
                              ),
                            }))
                          }
                        />
                        <MultilangField
                          label="Body"
                          value={step.body}
                          onChange={(v) =>
                            updateHow((h) => ({
                              ...h,
                              steps: h.steps.map((s, i) =>
                                i === index ? { ...s, body: v } : s
                              ),
                            }))
                          }
                          multiline
                        />
                      </Box>
                    </Box>
                  ))
                )}

                <Button
                  onClick={() =>
                    updateHow((h) => ({
                      ...h,
                      steps: [
                        ...h.steps,
                        { title: { en: "", vi: "" }, body: { en: "", vi: "" } },
                      ],
                    }))
                  }
                  variant="outlined"
                  size="small"
                  startIcon={<Add />}
                  sx={{ alignSelf: "flex-start" }}
                >
                  Thêm bước
                </Button>

                <Divider sx={{ my: 1 }} />
                <MultilangField
                  label="Footer"
                  value={draft.how.footer}
                  onChange={(v) => updateHow((h) => ({ ...h, footer: v }))}
                  multiline
                />
                <MultilangField
                  label="CTA label"
                  value={draft.how.ctaLabel}
                  onChange={(v) => updateHow((h) => ({ ...h, ctaLabel: v }))}
                />
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* Reminder (screen 8) */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Nhắc nhở học (S8)
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <Box className="flex flex-col gap-3">
                <Typography variant="caption" color="text.secondary">
                  Thẻ preview dùng copy của accordion Notifications bên dưới.
                </Typography>
                <MultilangField
                  label="Heading"
                  value={draft.reminder.heading}
                  onChange={(v) =>
                    updateReminder((r) => ({ ...r, heading: v }))
                  }
                />
                <MultilangField
                  label="Heading highlight"
                  value={draft.reminder.headingHighlight || {}}
                  onChange={(v) =>
                    updateReminder((r) => ({ ...r, headingHighlight: v }))
                  }
                  helperText="Gradient-highlighted trailing part of the title"
                />
                <MultilangField
                  label="Subtitle"
                  value={draft.reminder.subtitle}
                  onChange={(v) =>
                    updateReminder((r) => ({ ...r, subtitle: v }))
                  }
                />
                <MultilangField
                  label="Time section label"
                  value={draft.reminder.timeSectionLabel}
                  onChange={(v) =>
                    updateReminder((r) => ({ ...r, timeSectionLabel: v }))
                  }
                />

                <Divider sx={{ my: 1 }} />
                <Typography variant="subtitle2">Presets</Typography>

                {draft.reminder.presets.length === 0 ? (
                  <Typography variant="body2" color="text.secondary">
                    No presets yet.
                  </Typography>
                ) : (
                  draft.reminder.presets.map((preset, index) => (
                    <Box key={index} sx={rowSx}>
                      <Box className="flex items-center justify-between mb-2">
                        <Typography variant="subtitle2">
                          Preset {index + 1}
                        </Typography>
                        <IconButton
                          size="small"
                          onClick={() =>
                            updateReminder((r) => ({
                              ...r,
                              presets: r.presets.filter(
                                (_, i) => i !== index
                              ),
                            }))
                          }
                        >
                          <Delete fontSize="small" />
                        </IconButton>
                      </Box>
                      <Box className="flex flex-wrap items-start gap-3">
                        <Box sx={{ flex: 1, minWidth: 220 }}>
                          <MultilangField
                            label="Label"
                            value={preset.label}
                            onChange={(v) =>
                              updateReminder((r) => ({
                                ...r,
                                presets: r.presets.map((p, i) =>
                                  i === index ? { ...p, label: v } : p
                                ),
                              }))
                            }
                          />
                        </Box>
                        <TextField
                          label="Time"
                          type="time"
                          value={preset.time}
                          onChange={(e) =>
                            updateReminder((r) => ({
                              ...r,
                              presets: r.presets.map((p, i) =>
                                i === index
                                  ? { ...p, time: e.target.value }
                                  : p
                              ),
                            }))
                          }
                          size="small"
                          InputLabelProps={{ shrink: true }}
                          inputProps={{ step: 900 }}
                          sx={{ minWidth: 150 }}
                        />
                      </Box>
                    </Box>
                  ))
                )}

                <Button
                  onClick={() =>
                    updateReminder((r) => ({
                      ...r,
                      presets: [
                        ...r.presets,
                        { label: { en: "", vi: "" }, time: "" },
                      ],
                    }))
                  }
                  variant="outlined"
                  size="small"
                  startIcon={<Add />}
                  sx={{ alignSelf: "flex-start" }}
                >
                  Thêm preset
                </Button>

                <Divider sx={{ my: 1 }} />
                <MultilangField
                  label="CTA label"
                  value={draft.reminder.ctaLabel}
                  onChange={(v) =>
                    updateReminder((r) => ({ ...r, ctaLabel: v }))
                  }
                />
                <MultilangField
                  label="Secondary CTA label"
                  value={draft.reminder.secondaryCtaLabel}
                  onChange={(v) =>
                    updateReminder((r) => ({ ...r, secondaryCtaLabel: v }))
                  }
                />
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* Loading (screen 9) */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Đang tạo lộ trình (S9)
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <Box className="flex flex-col gap-3">
                <MultilangField
                  label="Heading"
                  value={draft.loading.heading}
                  onChange={(v) =>
                    updateLoading((l) => ({ ...l, heading: v }))
                  }
                />
                <MultilangField
                  label="Heading highlight"
                  value={draft.loading.headingHighlight || {}}
                  onChange={(v) =>
                    updateLoading((l) => ({ ...l, headingHighlight: v }))
                  }
                  helperText="Gradient-highlighted trailing part of the title"
                />

                <Divider sx={{ my: 1 }} />
                <Typography variant="subtitle2">Lines</Typography>

                {draft.loading.lines.length === 0 ? (
                  <Typography variant="body2" color="text.secondary">
                    No lines yet.
                  </Typography>
                ) : (
                  draft.loading.lines.map((line, index) => (
                    <Box key={index} sx={rowSx}>
                      <Box className="flex items-center justify-between mb-2">
                        <Typography variant="subtitle2">
                          Line {index + 1}
                        </Typography>
                        <IconButton
                          size="small"
                          onClick={() =>
                            updateLoading((l) => ({
                              ...l,
                              lines: l.lines.filter((_, i) => i !== index),
                            }))
                          }
                        >
                          <Delete fontSize="small" />
                        </IconButton>
                      </Box>
                      <MultilangField
                        label="Line"
                        value={line}
                        onChange={(v) =>
                          updateLoading((l) => ({
                            ...l,
                            lines: l.lines.map((ln, i) =>
                              i === index ? v : ln
                            ),
                          }))
                        }
                      />
                    </Box>
                  ))
                )}

                <Button
                  onClick={() =>
                    updateLoading((l) => ({
                      ...l,
                      lines: [...l.lines, { en: "", vi: "" }],
                    }))
                  }
                  variant="outlined"
                  size="small"
                  startIcon={<Add />}
                  sx={{ alignSelf: "flex-start" }}
                >
                  Thêm dòng
                </Button>
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* Notifications (S8 preview card) */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Nhắc nhở (S8) — thẻ preview + CTA
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <Box className="flex flex-col gap-3">
                <MultilangField
                  label="Heading"
                  value={draft.notif.heading}
                  onChange={(v) => updateNotif((n) => ({ ...n, heading: v }))}
                />
                <MultilangField
                  label="Heading highlight"
                  value={draft.notif.headingHighlight || {}}
                  onChange={(v) =>
                    updateNotif((n) => ({ ...n, headingHighlight: v }))
                  }
                  helperText="Gradient-highlighted trailing part of the title"
                />
                <MultilangField
                  label="Subtitle"
                  value={draft.notif.subtitle}
                  onChange={(v) =>
                    updateNotif((n) => ({ ...n, subtitle: v }))
                  }
                />
                <Divider sx={{ my: 1 }} />
                <Typography variant="subtitle2">Preview card</Typography>
                <MultilangField
                  label="Card title"
                  value={draft.notif.cardTitle}
                  onChange={(v) =>
                    updateNotif((n) => ({ ...n, cardTitle: v }))
                  }
                />
                <MultilangField
                  label="Card body"
                  value={draft.notif.cardBody}
                  onChange={(v) =>
                    updateNotif((n) => ({ ...n, cardBody: v }))
                  }
                  multiline
                />
                <MultilangField
                  label="Card timestamp"
                  value={draft.notif.cardTimestamp}
                  onChange={(v) =>
                    updateNotif((n) => ({ ...n, cardTimestamp: v }))
                  }
                />
                <Divider sx={{ my: 1 }} />
                <MultilangField
                  label="CTA label"
                  value={draft.notif.ctaLabel}
                  onChange={(v) =>
                    updateNotif((n) => ({ ...n, ctaLabel: v }))
                  }
                />

                <Divider sx={{ my: 1 }} />
                <Box sx={{ maxWidth: 280 }}>
                  <CloudflareFileUpload
                    initialUrl={draft.notif.iconUrl}
                    onUrlChange={(iconUrl) =>
                      updateNotif((n) => ({ ...n, iconUrl }))
                    }
                    label="Icon"
                    uploadPayload={{ prefix: "notif-icon", folder: "onboarding" }}
                  />
                  <Typography
                    variant="caption"
                    color="text.secondary"
                    sx={{ display: "block", mt: 0.5 }}
                  >
                    Leave empty for default.
                  </Typography>
                </Box>
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* Pick course (S10) */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Kết quả (S10) — data key `pick`
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <Box className="flex flex-col gap-3">
                <Alert severity="info">
                  The course list on this screen is dynamic (real courses,
                  recommended by picked paths) — only the surrounding copy is
                  editable here.
                </Alert>
                <MultilangField
                  label="Eyebrow"
                  value={draft.pick.eyebrow || {}}
                  onChange={(v) => updatePick((p) => ({ ...p, eyebrow: v }))}
                  helperText="Small label rendered above the heading"
                />
                <MultilangField
                  label="Heading"
                  value={draft.pick.heading}
                  onChange={(v) => updatePick((p) => ({ ...p, heading: v }))}
                />
                <MultilangField
                  label="Heading highlight"
                  value={draft.pick.headingHighlight || {}}
                  onChange={(v) =>
                    updatePick((p) => ({ ...p, headingHighlight: v }))
                  }
                  helperText="Gradient-highlighted trailing part of the title"
                />
                <MultilangField
                  label="Label"
                  value={draft.pick.label}
                  onChange={(v) => updatePick((p) => ({ ...p, label: v }))}
                />
                <MultilangField
                  label="Primary CTA"
                  value={draft.pick.primaryCta}
                  onChange={(v) =>
                    updatePick((p) => ({ ...p, primaryCta: v }))
                  }
                />
                <MultilangField
                  label="Secondary CTA"
                  value={draft.pick.secondaryCta}
                  onChange={(v) =>
                    updatePick((p) => ({ ...p, secondaryCta: v }))
                  }
                />

                <Divider sx={{ my: 1 }} />
                <Box sx={{ maxWidth: 280 }}>
                  <CloudflareFileUpload
                    initialUrl={draft.pick.iconUrl}
                    onUrlChange={(iconUrl) =>
                      updatePick((p) => ({ ...p, iconUrl }))
                    }
                    label="Icon"
                    uploadPayload={{ prefix: "pick-icon", folder: "onboarding" }}
                  />
                  <Typography
                    variant="caption"
                    color="text.secondary"
                    sx={{ display: "block", mt: 0.5 }}
                  >
                    Leave empty for default.
                  </Typography>
                </Box>
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* Theme (screen 9) */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Box>
                <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                  Theme (screen 9)
                </Typography>
                <Typography
                  variant="caption"
                  color="text.secondary"
                  sx={{ display: "block" }}
                >
                  The "Make it yours" theme-picker screen shown last, before
                  entering the app.
                </Typography>
              </Box>
            </AccordionSummary>
            <AccordionDetails>
              <Box className="flex flex-col gap-3">
                <MultilangField
                  label="Title prefix"
                  value={draft.theme.titlePrefix}
                  onChange={(v) =>
                    updateTheme((t) => ({ ...t, titlePrefix: v }))
                  }
                />
                <MultilangField
                  label="Title highlight"
                  value={draft.theme.titleHighlight}
                  onChange={(v) =>
                    updateTheme((t) => ({ ...t, titleHighlight: v }))
                  }
                  helperText="Gradient-highlighted trailing part of the title"
                />
                <MultilangField
                  label="Subtitle"
                  value={draft.theme.subtitle}
                  onChange={(v) =>
                    updateTheme((t) => ({ ...t, subtitle: v }))
                  }
                />
                <MultilangField
                  label="CTA label"
                  value={draft.theme.ctaLabel}
                  onChange={(v) =>
                    updateTheme((t) => ({ ...t, ctaLabel: v }))
                  }
                />
                <MultilangField
                  label="Helper"
                  value={draft.theme.helper}
                  onChange={(v) => updateTheme((t) => ({ ...t, helper: v }))}
                />
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* Paywall (after onboarding) */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Box>
                <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                  Paywall
                </Typography>
                <Typography
                  variant="caption"
                  color="text.secondary"
                  sx={{ display: "block" }}
                >
                  Show the full paywall right after onboarding completes.
                </Typography>
              </Box>
            </AccordionSummary>
            <AccordionDetails>
              <FormControlLabel
                control={
                  <Switch
                    checked={draft.showPaywallAfterOnboarding}
                    onChange={(e) =>
                      setDraft((prev) =>
                        prev
                          ? {
                              ...prev,
                              showPaywallAfterOnboarding: e.target.checked,
                            }
                          : prev
                      )
                    }
                  />
                }
                label="Show paywall after onboarding"
              />
              <Typography
                variant="caption"
                color="text.secondary"
                sx={{ display: "block", mt: 0.5 }}
              >
                Opens on top of the screen onboarding hands off to. Premium
                accounts never see it.
              </Typography>
            </AccordionDetails>
          </Accordion>
        </>
      )}

      <Dialog
        open={!!importPreview}
        onClose={() => setImportPreview(null)}
        maxWidth="xs"
        fullWidth
      >
        <DialogTitle>Import onboarding config</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Load this file into the draft below? This overwrites all unsaved
            edits. Nothing is sent to the server until you press "Save
            changes".
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ px: 3, py: 2 }}>
          <Button onClick={() => setImportPreview(null)}>Cancel</Button>
          <Button variant="contained" onClick={handleConfirmImport}>
            Load into draft
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
