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
  Divider,
  IconButton,
  Paper,
  Skeleton,
  TextField,
  Typography,
} from "@mui/material";
import { Add, Delete, ExpandMore } from "@mui/icons-material";
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
import type {
  OnboardingAgeConfig,
  OnboardingBrainConfig,
  OnboardingConfig,
  OnboardingConfigPayload,
  OnboardingHabitConfig,
  OnboardingMultilang,
  OnboardingNameConfig,
  OnboardingNotifConfig,
  OnboardingPathsConfig,
  OnboardingPickConfig,
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
  notif: OnboardingNotifConfig;
  pick: OnboardingPickConfig;
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
    heading: ml(config?.pick?.heading),
    headingHighlight: ml(config?.pick?.headingHighlight),
    label: ml(config?.pick?.label),
    primaryCta: ml(config?.pick?.primaryCta),
    secondaryCta: ml(config?.pick?.secondaryCta),
    iconUrl: config?.pick?.iconUrl || "",
  },
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
  notif: draft.notif,
  pick: draft.pick,
});

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
  // Symptom add/update/remove/reorder are scoped to this path item only —
  // they thread through the path item's own `onChange`, mirroring how the
  // page-level `makeListHelpers` reaches into ConfigDraft one level up.
  const updateSymptoms = (
    updater: (list: SymptomDraft[]) => SymptomDraft[]
  ) =>
    onChange((prev) => ({ ...prev, symptoms: updater(prev.symptoms) }));

  const addSymptom = () =>
    updateSymptoms((list) => [
      ...list,
      { _localId: nextLocalId(), key: "", label: {} },
    ]);
  const updateSymptomItem = (
    localId: string,
    updater: (item: SymptomDraft) => SymptomDraft
  ) =>
    updateSymptoms((list) =>
      list.map((s) => (s._localId === localId ? updater(s) : s))
    );
  const removeSymptom = (localId: string) =>
    updateSymptoms((list) => list.filter((s) => s._localId !== localId));
  const reorderSymptoms = (event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;
    updateSymptoms((list) => {
      const oldIndex = list.findIndex((s) => s._localId === active.id);
      const newIndex = list.findIndex((s) => s._localId === over.id);
      if (oldIndex === -1 || newIndex === -1) return list;
      return arrayMove(list, oldIndex, newIndex);
    });
  };

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
        <Box className="flex items-center justify-between mb-1.5">
          <Typography variant="subtitle2">Symptoms</Typography>
          <Typography variant="caption" color="text.secondary">
            Drag to reorder
          </Typography>
        </Box>

        {item.symptoms.length === 0 ? (
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
              items={item.symptoms.map((s) => s._localId)}
              strategy={verticalListSortingStrategy}
            >
              {item.symptoms.map((symptom, symptomIndex) => (
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
  const updateNotif = (
    updater: (n: OnboardingNotifConfig) => OnboardingNotifConfig
  ) => setDraft((prev) => (prev ? { ...prev, notif: updater(prev.notif) } : prev));
  const updatePick = (
    updater: (p: OnboardingPickConfig) => OnboardingPickConfig
  ) => setDraft((prev) => (prev ? { ...prev, pick: updater(prev.pick) } : prev));

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

          {/* Paths */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Paths
              </Typography>
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

          {/* Brain science */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Brain science
              </Typography>
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

          {/* Habit */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Habit
              </Typography>
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
              </Box>
            </AccordionDetails>
          </Accordion>

          {/* Notifications */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Notifications
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

          {/* Pick course */}
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Pick course
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
        </>
      )}
    </Box>
  );
}
