import { useEffect, useMemo, useState } from "react";
import { useSelector } from "react-redux";
import {
  PlusIcon,
  TrashIcon,
  XMarkIcon,
  PencilSquareIcon,
} from "@heroicons/react/24/outline";
import { DndContext, closestCenter } from "@dnd-kit/core";
import {
  SortableContext,
  arrayMove,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { AnimatePresence, motion } from "framer-motion";
import { EditorContent, useEditor } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import Bold from "@tiptap/extension-bold";
import Italic from "@tiptap/extension-italic";
import { RootState } from "../../store";
import { onboardingService } from "../../services/onboardingService";
import { courseService } from "../../services/courseService";
import {
  IOnboardingScenarioBranch,
  IOnboardingScenarioActivation,
  IOnboardingScenarioBranchOption,
  IOnboardingScenarioBranching,
  IOnboardingScenarioContentItem,
  IOnboardingScenarioFixed,
  IOnboardingScenarioPersonAdmire,
  IOnboardingScenarioPersonAdmireOption,
  IOnboardingScenarioScene,
  OnboardingContentType,
} from "../../types/interface/onboarding-scenario-branching.interface";
import { ICourse } from "../../types/interface/course.interface";
import { ILablel, LangCode } from "../../types/enum/common.enum";
import {
  cleanTranslation,
  getCurrentTranslationValue,
  ITranslation,
  updateTranslationValue,
} from "../../utils/translation";
import CloudflareFileUpload from "../../components/files/CloudflareFileUpload";
import { useNotification } from "../../utils/hooks/useNotification";
import SortableItem from "../../components/common/SortableItem";

const emptyScenario: IOnboardingScenarioBranching = {
  entrySceneId: "",
  scenes: [],
};

const createTranslation = (): ITranslation => ({});

const cloneTranslationValue = (value?: ITranslation): ITranslation =>
  value ? { ...value } : createTranslation();

const normalizePersonTextValue = (
  value?: ITranslation | string,
): ITranslation => {
  if (typeof value === "string") {
    const trimmed = value.trim();
    return trimmed ? { [LangCode.EN]: trimmed } : createTranslation();
  }
  return cloneTranslationValue(value);
};

const createLabel = (id: number): ILablel => ({
  id,
  icon: "",
  title: createTranslation(),
  label: createTranslation(),
  trackingLabel: "",
});

const createActivation = (id: number) => ({
  id,
  title: createTranslation(),
  description: createTranslation(),
  content: {
    icon: "",
    labels: [createLabel(1)],
  },
});

const createBranch = (): IOnboardingScenarioBranch => ({
  subQuestion: createTranslation(),
  question: createTranslation(),
  options: [
    {
      id: 1,
      label: createTranslation(),
      icon: "",
      nextSceneId: "",
      courses: [],
    },
  ],
});

const ensureBranch = (branch?: IOnboardingScenarioBranch) =>
  branch ?? createBranch();

const createFixed = (): IOnboardingScenarioFixed => ({
  subQuestion: createTranslation(),
  question: createTranslation(),
  options: [createLabel(1)],
});

const ensureFixed = (fixed?: IOnboardingScenarioFixed) =>
  fixed ?? createFixed();

const createPersonAdmireOption = (
  overrides: Partial<IOnboardingScenarioPersonAdmireOption> = {},
): IOnboardingScenarioPersonAdmireOption => ({
  image: overrides.image || "",
  name: overrides.name || "",
  title: cloneTranslationValue(overrides.title),
  subTitle: cloneTranslationValue(overrides.subTitle),
});

const createPersonAdmire = (): IOnboardingScenarioPersonAdmire => ({
  subQuestion: createTranslation(),
  question: createTranslation(),
  options: [createPersonAdmireOption()],
});

const ensurePersonAdmire = (personAdmire?: IOnboardingScenarioPersonAdmire) =>
  personAdmire ?? createPersonAdmire();

const normalizeActivationContent = (
  content: IOnboardingScenarioContentItem,
): IOnboardingScenarioContentItem => {
  if (content.type !== OnboardingContentType.ACTIVATION) {
    return content;
  }
  const legacyActivations = (
    content as IOnboardingScenarioContentItem & {
      activations?: IOnboardingScenarioActivation[];
    }
  ).activations;
  const activation =
    content.activation || legacyActivations?.[0] || createActivation(1);
  const { activations: _legacy, ...rest } =
    content as IOnboardingScenarioContentItem & {
      activations?: IOnboardingScenarioActivation[];
    };
  return {
    ...rest,
    activation,
  };
};

const ensureScenarioActivation = (
  input: IOnboardingScenarioBranching,
): IOnboardingScenarioBranching => ({
  ...input,
  scenes: input.scenes.map((scene) => ({
    ...scene,
    contents: scene.contents.map((content) =>
      normalizeActivationContent(content),
    ),
  })),
});

const addLegacyActivations = (
  input: IOnboardingScenarioBranching,
): IOnboardingScenarioBranching =>
  ({
    ...input,
    scenes: input.scenes.map((scene) => ({
      ...scene,
      contents: scene.contents.map((content) => {
        if (content.type !== OnboardingContentType.ACTIVATION) {
          return content;
        }
        const activation = content.activation || createActivation(1);
        return {
          ...content,
          activation,
          activations: [activation],
        };
      }),
    })),
  }) as IOnboardingScenarioBranching;

const withBranch = (
  item: IOnboardingScenarioContentItem,
  updater: (branch: IOnboardingScenarioBranch) => IOnboardingScenarioBranch,
): IOnboardingScenarioContentItem => ({
  ...item,
  branch: updater(ensureBranch(item.branch)),
});

const withFixed = (
  item: IOnboardingScenarioContentItem,
  updater: (fixed: IOnboardingScenarioFixed) => IOnboardingScenarioFixed,
): IOnboardingScenarioContentItem => ({
  ...item,
  fixed: updater(ensureFixed(item.fixed)),
});

const withPersonAdmire = (
  item: IOnboardingScenarioContentItem,
  updater: (
    personAdmire: IOnboardingScenarioPersonAdmire,
  ) => IOnboardingScenarioPersonAdmire,
): IOnboardingScenarioContentItem => ({
  ...item,
  personAdmire: updater(ensurePersonAdmire(item.personAdmire)),
});

const createContent = (
  id: number,
  type: OnboardingContentType,
): IOnboardingScenarioContentItem => {
  if (type === OnboardingContentType.FACT) {
    return {
      id,
      type,
      fact: createLabel(id),
    };
  }

  if (type === OnboardingContentType.ACTIVATION) {
    return {
      id,
      type,
      activation: createActivation(1),
    };
  }

  if (type === OnboardingContentType.FIXED) {
    return {
      id,
      type,
      fixed: createFixed(),
    };
  }

  if (type === OnboardingContentType.PERSON_ADMIRE) {
    return {
      id,
      type,
      personAdmire: createPersonAdmire(),
    };
  }

  return {
    id,
    type,
    branch: createBranch(),
  };
};

const nextNumericId = <T extends { id: number }>(items: T[], fallback = 1) =>
  items.length ? Math.max(...items.map((item) => item.id)) + 1 : fallback;

const reindexLabels = (labels: ILablel[]) =>
  labels.map((label, index) => ({ ...label, id: index + 1 }));

const reindexOptions = (options: IOnboardingScenarioBranchOption[]) =>
  options.map((option, index) => ({ ...option, id: index + 1 }));

const createSceneId = (scenes: IOnboardingScenarioScene[]) => {
  const usedIds = new Set(scenes.map((scene) => scene.id));
  const numericIds = scenes
    .map((scene) => {
      const match = scene.id.match(/^scene_(\d+)$/);
      return match ? Number(match[1]) : null;
    })
    .filter((value): value is number => value !== null);
  let nextNumber = numericIds.length ? Math.max(...numericIds) + 1 : 1;
  let candidate = `scene_${nextNumber}`;
  while (usedIds.has(candidate)) {
    nextNumber += 1;
    candidate = `scene_${nextNumber}`;
  }
  return candidate;
};

const getSceneBranchOptions = (scene: IOnboardingScenarioScene) => {
  const branchContent = scene.contents.find(
    (content) =>
      content.type === OnboardingContentType.BRANCH && content.branch,
  );
  return branchContent?.branch?.options || [];
};

const getNextSceneIdForOption = (
  scenes: IOnboardingScenarioScene[],
  parentSceneId: string,
  optionId: number,
) => {
  const usedIds = new Set(scenes.map((scene) => scene.id));
  let candidateNumber = optionId;
  let candidate = `${parentSceneId}_${candidateNumber}`;
  while (usedIds.has(candidate)) {
    candidateNumber += 1;
    candidate = `${parentSceneId}_${candidateNumber}`;
  }
  return candidate;
};

const getDirectChildScenes = (
  scenes: IOnboardingScenarioScene[],
  parentSceneId: string,
) => {
  const parentSegments = parentSceneId.split("_").length;
  const childPrefix = `${parentSceneId}_`;

  return scenes.filter((scene) => {
    if (scene.id === parentSceneId) return false;
    if (!scene.id.startsWith(childPrefix)) return false;
    return scene.id.split("_").length === parentSegments + 1;
  });
};

const normalizeScenario = (
  input: IOnboardingScenarioBranching,
): IOnboardingScenarioBranching => ({
  entrySceneId: input.entrySceneId,
  scenes: input.scenes.map((scene) => ({
    ...scene,
    contents: scene.contents.map((content, contentIndex) => {
      const normalizedContent: IOnboardingScenarioContentItem =
        normalizeActivationContent({
          ...content,
          id: contentIndex + 1,
        });

      if (normalizedContent.type === OnboardingContentType.FACT) {
        if (normalizedContent.fact) {
          normalizedContent.fact = {
            ...normalizedContent.fact,
            id: contentIndex + 1,
          };
        }
      }

      if (
        normalizedContent.type === OnboardingContentType.ACTIVATION &&
        normalizedContent.activation
      ) {
        normalizedContent.activation = {
          ...normalizedContent.activation,
          content: {
            ...normalizedContent.activation.content,
            labels: (normalizedContent.activation.content.labels || []).map(
              (label, labelIndex) => ({
                ...label,
                id: labelIndex + 1,
              }),
            ),
          },
        };
      }

      if (normalizedContent.type === OnboardingContentType.BRANCH) {
        if (normalizedContent.branch) {
          normalizedContent.branch = {
            ...normalizedContent.branch,
            options: normalizedContent.branch.options.map(
              (option, optionIndex) => ({
                ...option,
                id: optionIndex + 1,
              }),
            ),
          };
        }
      }

      if (normalizedContent.type === OnboardingContentType.FIXED) {
        if (normalizedContent.fixed) {
          normalizedContent.fixed = {
            ...normalizedContent.fixed,
            options: normalizedContent.fixed.options.map(
              (option, optionIndex) => ({
                ...option,
                id: optionIndex + 1,
              }),
            ),
          };
        }
      }

      if (normalizedContent.type === OnboardingContentType.PERSON_ADMIRE) {
        const normalizedPersonAdmire = ensurePersonAdmire(
          normalizedContent.personAdmire,
        );
        normalizedContent.personAdmire = {
          ...normalizedPersonAdmire,
          subQuestion: normalizedPersonAdmire.subQuestion || createTranslation(),
          question: normalizedPersonAdmire.question || createTranslation(),
          options: (normalizedPersonAdmire.options || []).map((option) => ({
            image: option.image || "",
            name: option.name || "",
            title: normalizePersonTextValue(option.title),
            subTitle: normalizePersonTextValue(option.subTitle),
          })),
        };
      }

      return normalizedContent;
    }),
  })),
});

const sanitizeTranslationValue = (value?: ITranslation): ITranslation =>
  cleanTranslation(value) || {};

const sanitizeLabel = (label: ILablel): ILablel => ({
  ...label,
  title: sanitizeTranslationValue(label.title),
  label: sanitizeTranslationValue(label.label),
});

const sanitizeScenario = (
  input: IOnboardingScenarioBranching,
): IOnboardingScenarioBranching => ({
  entrySceneId: input.entrySceneId,
  scenes: input.scenes.map((scene) => ({
    ...scene,
    contents: scene.contents.map((content) => {
      if (content.type === OnboardingContentType.FACT && content.fact) {
        return {
          ...content,
          fact: sanitizeLabel(content.fact),
        };
      }

      if (content.type === OnboardingContentType.ACTIVATION) {
        const normalizedContent = normalizeActivationContent(content);
        if (!normalizedContent.activation) return normalizedContent;
        return {
          ...normalizedContent,
          activation: {
            ...normalizedContent.activation,
            title: sanitizeTranslationValue(normalizedContent.activation.title),
            description: sanitizeTranslationValue(
              normalizedContent.activation.description,
            ),
            content: {
              ...normalizedContent.activation.content,
              labels: (normalizedContent.activation.content.labels || []).map(
                (label) => sanitizeLabel(label),
              ),
            },
          },
        };
      }

      if (content.type === OnboardingContentType.BRANCH && content.branch) {
        return {
          ...content,
          branch: {
            ...content.branch,
            subQuestion: sanitizeTranslationValue(content.branch.subQuestion),
            question: sanitizeTranslationValue(content.branch.question),
            options: content.branch.options.map((option) => ({
              ...option,
              label: sanitizeTranslationValue(option.label),
            })),
          },
        };
      }

      if (content.type === OnboardingContentType.FIXED && content.fixed) {
        return {
          ...content,
          fixed: {
            ...content.fixed,
            subQuestion: sanitizeTranslationValue(content.fixed.subQuestion),
            question: sanitizeTranslationValue(content.fixed.question),
            options: content.fixed.options.map((option) =>
              sanitizeLabel(option),
            ),
          },
        };
      }

      if (
        content.type === OnboardingContentType.PERSON_ADMIRE &&
        content.personAdmire
      ) {
        return {
          ...content,
          personAdmire: {
            ...content.personAdmire,
            subQuestion: sanitizeTranslationValue(content.personAdmire.subQuestion),
            question: sanitizeTranslationValue(content.personAdmire.question),
            options: (content.personAdmire.options || []).map((option) => ({
              image: option.image || "",
              name: option.name || "",
              title: sanitizeTranslationValue(option.title),
              subTitle: sanitizeTranslationValue(option.subTitle),
            })),
          },
        };
      }

      return content;
    }),
  })),
});

const typeBadgeClasses: Record<OnboardingContentType, string> = {
  [OnboardingContentType.FACT]: "text-pink-500",
  [OnboardingContentType.ACTIVATION]: "text-pink-500",
  [OnboardingContentType.BRANCH]: "text-pink-500",
  [OnboardingContentType.FIXED]: "text-pink-500",
  [OnboardingContentType.PERSON_ADMIRE]: "text-pink-500",
};

const typeMeta: Record<
  OnboardingContentType,
  { label: string; description: string }
> = {
  [OnboardingContentType.FACT]: {
    label: "Fact",
    description: "Single label hint",
  },
  [OnboardingContentType.ACTIVATION]: {
    label: "Activation",
    description: "Actionable start cards",
  },
  [OnboardingContentType.BRANCH]: {
    label: "Branch",
    description: "Decision question",
  },
  [OnboardingContentType.FIXED]: {
    label: "Fixed",
    description: "Fixed options",
  },
  [OnboardingContentType.PERSON_ADMIRE]: {
    label: "Person Admire",
    description: "Person admire options",
  },
};

const textInputClass =
  "w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-800 shadow-sm focus:border-slate-400 focus:outline-none";

const labelTextClass =
  "text-[11px] font-bold uppercase tracking-[0.2em] text-slate-500";

const iconButtonClass =
  "inline-flex h-8 w-8 items-center justify-center rounded-full border border-slate-200 bg-white text-slate-600 shadow-sm transition hover:border-slate-300 hover:bg-slate-50";

const iconButtonAddClass =
  "inline-flex h-8 w-8 items-center justify-center rounded-full border border-blue-200 bg-blue-50 text-blue-600 shadow-sm transition hover:border-blue-300 hover:bg-blue-100";

const iconButtonDangerClass =
  "inline-flex h-8 w-8 items-center justify-center rounded-full border border-slate-200 bg-white text-rose-500 shadow-sm transition hover:border-rose-200 hover:bg-rose-50";

const toneClasses: Record<"blue" | "emerald" | "amber", string> = {
  blue: "text-blue-600",
  emerald: "text-emerald-600",
  amber: "text-amber-600",
};

const summaryLabelMainClass = "text-blue-500";
const summaryLabelSubClass = "text-green-500";

const TextWithTooltip = ({
  text = "",
  maxLength = 60,
  className = "text-slate-500",
}: {
  text?: string;
  maxLength?: number;
  className?: string;
}) => {
  if (!text) {
    return <span className={className}>—</span>;
  }

  return (
    <div className="relative group max-w-full">
      <span className={`inline-block max-w-full truncate ${className}`}>
        {text.length > maxLength ? `${text.substring(0, maxLength)}...` : text}
      </span>
      {text.length > maxLength ? (
        <div className="absolute bottom-full left-0 z-10 mb-2 hidden max-h-40 w-64 overflow-y-auto rounded bg-slate-800 px-3 py-2 text-xs text-white shadow-lg group-hover:block">
          {text}
        </div>
      ) : null}
    </div>
  );
};

const stripHtml = (value = "") =>
  value
    .replace(/<[^>]*>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ")
    .trim();

const getDisplayTranslationValue = (
  translation: ITranslation | string | undefined,
  currentLang: LangCode,
) => {
  if (!translation) return "";
  if (typeof translation === "string") return translation;

  const currentValue = translation[currentLang];
  if (currentValue?.trim()) return currentValue;

  const enValue = translation[LangCode.EN];
  if (enValue?.trim()) return enValue;

  const viValue = translation[LangCode.VI];
  if (viValue?.trim()) return viValue;

  return Object.values(translation).find((value) => value?.trim()) || "";
};

const ConfirmDialog = ({
  open,
  title,
  message,
  messageClassName,
  confirmLabel = "Confirm",
  confirmTone = "danger",
  onCancel,
  onConfirm,
}: {
  open: boolean;
  title: string;
  message: string;
  messageClassName?: string;
  confirmLabel?: string;
  confirmTone?: "danger" | "primary";
  onCancel: () => void;
  onConfirm: () => void;
}) => {
  if (!open) return null;
  const confirmClass =
    confirmTone === "primary"
      ? "bg-blue-600 hover:bg-blue-700"
      : "bg-red-600 hover:bg-red-700";
  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 px-4">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.9 }}
          className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl"
        >
          <h2 className="text-lg font-semibold text-slate-900">{title}</h2>
          <p
            className={`mt-2 text-sm text-slate-600 ${messageClassName || ""}`}
          >
            {message}
          </p>
          <div className="mt-6 flex justify-end gap-3">
            <button
              type="button"
              onClick={onCancel}
              className="rounded-lg bg-slate-200 px-4 py-2 text-sm text-slate-700 transition hover:bg-slate-300"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={onConfirm}
              className={`rounded-lg px-4 py-2 text-sm text-white transition ${confirmClass}`}
            >
              {confirmLabel}
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};

const TranslationInputs = ({
  label,
  value,
  lang,
  tone,
  onChange,
}: {
  label: string;
  value?: ITranslation;
  lang: LangCode;
  tone?: "blue" | "emerald" | "amber";
  onChange: (nextValue: ITranslation) => void;
}) => (
  <label className="space-y-1">
    <span className={`${labelTextClass} ${tone ? toneClasses[tone] : ""}`}>
      {label}
    </span>
    <textarea
      className={`${textInputClass} min-h-[64px] resize-y`}
      value={getCurrentTranslationValue(value, lang)}
      onChange={(event) =>
        onChange(
          cleanTranslation(
            updateTranslationValue(value, lang, event.target.value),
          ) || {},
        )
      }
      placeholder={`Enter ${lang} content`}
      rows={2}
    />
  </label>
);

const LabelTranslationInput = ({
  value,
  lang,
  tone,
  onChange,
}: {
  value?: ITranslation;
  lang: LangCode;
  tone?: "blue" | "emerald" | "amber";
  onChange: (nextValue: ITranslation) => void;
}) => {
  const currentValue = getCurrentTranslationValue(value, lang);
  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        bold: false,
        italic: false,
        heading: false,
        blockquote: false,
        codeBlock: false,
        horizontalRule: false,
        bulletList: false,
        orderedList: false,
        listItem: false,
      }),
      Bold,
      Italic,
    ],
    content: currentValue || "<p></p>",
    editorProps: {
      attributes: {
        class:
          "label-rich-editor-content min-h-[64px] rounded-b-xl border border-t-0 border-slate-200 bg-white px-3 py-2 text-sm font-normal text-slate-800 shadow-sm focus:outline-none",
      },
    },
    onUpdate: ({ editor: nextEditor }) => {
      const nextHtml = nextEditor.getText().trim()
        ? nextEditor.getHTML()
        : "";
      onChange(cleanTranslation(updateTranslationValue(value, lang, nextHtml)) || {});
    },
  }, ["label-editor-v2"]);

  useEffect(() => {
    if (!editor) return;
    const incoming = currentValue || "<p></p>";
    if (editor.getHTML() !== incoming) {
      editor.commands.setContent(incoming, false);
    }
  }, [currentValue, editor]);

  const toolbarBtn = (active: boolean) =>
    `inline-flex h-7 min-w-7 items-center justify-center rounded-md border px-2 text-xs font-semibold shadow-sm transition ${
      active
        ? "border-blue-300 bg-blue-100 text-blue-700"
        : "border-slate-200 bg-white text-slate-700 hover:bg-slate-50"
    }`;

  const toggleBold = () => {
    if (!editor) return;
    if (!editor.schema.marks.bold) return;
    const hasSelection = !editor.state.selection.empty;
    const selectionEnd = editor.state.selection.to;
    editor.chain().focus().toggleBold().run();
    if (hasSelection) {
      editor.chain().focus().setTextSelection(selectionEnd).unsetBold().run();
    }
  };

  const toggleItalic = () => {
    if (!editor) return;
    if (!editor.schema.marks.italic) return;
    const hasSelection = !editor.state.selection.empty;
    const selectionEnd = editor.state.selection.to;
    editor.chain().focus().toggleItalic().run();
    if (hasSelection) {
      editor.chain().focus().setTextSelection(selectionEnd).unsetItalic().run();
    }
  };

  return (
    <div className="space-y-1">
      <span className={`${labelTextClass} ${tone ? toneClasses[tone] : ""}`}>
        Label
      </span>
      <div className="flex items-center gap-2 rounded-t-xl border border-b-0 border-slate-200 bg-slate-50 p-2">
        <button
          type="button"
          onMouseDown={(event) => event.preventDefault()}
          onClick={toggleBold}
          className={toolbarBtn(Boolean(editor?.isActive("bold")))}
          title="Bold"
          aria-label="Bold selected text"
        >
          <span className="font-bold">B</span>
        </button>
        <button
          type="button"
          onMouseDown={(event) => event.preventDefault()}
          onClick={toggleItalic}
          className={toolbarBtn(Boolean(editor?.isActive("italic")))}
          title="Italic"
          aria-label="Italic selected text"
        >
          <span className="italic">I</span>
        </button>
      </div>
      <EditorContent editor={editor} />
    </div>
  );
};

const LabelEditor = ({
  label,
  title,
  lang,
  tone,
  showIconUpload = true,
  showTitleInput = true,
  onChange,
  onRemove,
}: {
  label: ILablel;
  title: string;
  lang: LangCode;
  tone?: "blue" | "emerald" | "amber";
  showIconUpload?: boolean;
  showTitleInput?: boolean;
  onChange: (nextLabel: ILablel) => void;
  onRemove?: () => void;
}) => (
  <div className="rounded-2xl border border-slate-200 bg-white p-4">
    <div className="flex flex-wrap items-center justify-between gap-3">
      <div className="flex items-center gap-2">
        <p className="text-sm font-semibold text-sky-400">{title}</p>
      </div>
      {onRemove ? (
        <button
          type="button"
          onClick={onRemove}
          className={iconButtonDangerClass}
          aria-label="Remove label"
          title="Remove label"
        >
          <TrashIcon className="h-4 w-4" />
        </button>
      ) : null}
    </div>
    {showIconUpload ? (
      <div className="mt-3 w-52">
        <CloudflareFileUpload
          initialUrl={label.icon}
          onUrlChange={(newUrl) =>
            onChange({
              ...label,
              icon: newUrl,
            })
          }
          label="Icon"
          uploadPayload={{
            prefix: "",
            folder: "onboarding",
          }}
        />
      </div>
    ) : null}
    {showTitleInput ? (
      <div className="mt-3">
        <TranslationInputs
          label="Title"
          value={label.title}
          lang={lang}
          tone={tone}
          onChange={(nextValue) =>
            onChange({
              ...label,
              title: nextValue,
            })
          }
        />
      </div>
    ) : null}
    <div className="mt-3">
      <LabelTranslationInput
        value={label.label}
        lang={lang}
        tone={tone}
        onChange={(nextValue) =>
          onChange({
            ...label,
            label: nextValue,
          })
        }
      />
    </div>
    <div className="mt-3">
      <label className="space-y-1">
        <span className={labelTextClass}>Tracking Label</span>
        <input
          className={textInputClass}
          value={label.trackingLabel}
          onChange={(event) =>
            onChange({
              ...label,
              trackingLabel: event.target.value,
            })
          }
        />
      </label>
    </div>
  </div>
);

export default function OnboardingManagemantScenarioBranching() {
  const lang = useSelector((state: RootState) => state.lang.code) as LangCode;
  const { showSuccess, showError } = useNotification();
  const [scenario, setScenario] =
    useState<IOnboardingScenarioBranching>(emptyScenario);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [scenarioId, setScenarioId] = useState<string>("");
  const [selectedSceneId, setSelectedSceneId] = useState<string>("");
  const [isTypeModalOpen, setIsTypeModalOpen] = useState(false);
  const [sceneLabelQuery, setSceneLabelQuery] = useState("");
  const [courseQuery, setCourseQuery] = useState("");
  const [courseQueryByOption, setCourseQueryByOption] = useState<
    Record<string, string>
  >({});
  const [activeCourseOptionKey, setActiveCourseOptionKey] = useState("");
  const [courses, setCourses] = useState<ICourse[]>([]);
  const [isCourseLoading, setIsCourseLoading] = useState(false);
  const [courseMap, setCourseMap] = useState<Record<string, ICourse>>({});
  const [confirmDialog, setConfirmDialog] = useState<{
    type: "deleteScene" | "setEntry";
    sceneId: string;
  } | null>(null);
  const [draftContent, setDraftContent] = useState<{
    sceneId: string;
    content: IOnboardingScenarioContentItem;
  } | null>(null);
  const [contentModal, setContentModal] = useState<{
    sceneId: string;
    contentId: number;
    mode: "create" | "edit";
  } | null>(null);

  const loadScenario = async () => {
    setIsLoading(true);
    try {
      const res = await onboardingService.findScenarioBranching();
      const payload =
        (res as { data?: IOnboardingScenarioBranching })?.data ?? res;
      const resolvedId =
        (payload as { _id?: string; id?: string })?._id ||
        (payload as { id?: string })?.id ||
        (res as { data?: { _id?: string; id?: string } })?.data?._id ||
        (res as { data?: { id?: string } })?.data?.id ||
        "";
      if (payload && Array.isArray(payload.scenes)) {
        setScenario(normalizeScenario(payload));
      } else {
        setScenario(normalizeScenario(emptyScenario));
      }
      setScenarioId(resolvedId);
    } catch (error) {
      setScenario(normalizeScenario(emptyScenario));
      showError("Không tải được dữ liệu, hãy tạo mới.");
      setScenarioId("");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadScenario();
  }, []);

  useEffect(() => {
    let active = true;
    const trimmedQuery = courseQuery.trim();
    if (!trimmedQuery) {
      setCourses([]);
      setIsCourseLoading(false);
      return () => {
        active = false;
      };
    }
    const fetchCourses = async () => {
      setIsCourseLoading(true);
      try {
        const res = await courseService.getList({
          page: 1,
          take: 20,
          search: trimmedQuery,
          isAll: true,
        });
        const list: ICourse[] = res?.data?.items ?? res?.items ?? [];
        if (active) {
          setCourses(list);
        }
      } catch (error) {
        console.error("fetchCourses", error);
      } finally {
        if (active) {
          setIsCourseLoading(false);
        }
      }
    };
    fetchCourses();
    return () => {
      active = false;
    };
  }, [courseQuery]);

  useEffect(() => {
    if (!scenario.scenes.length) {
      setSelectedSceneId("");
      return;
    }

    const nextId =
      scenario.scenes.find((scene) => scene.id === selectedSceneId)?.id ||
      scenario.entrySceneId ||
      scenario.scenes[0].id;

    setSelectedSceneId(nextId);
  }, [scenario.entrySceneId, scenario.scenes, selectedSceneId]);

  useEffect(() => {
    setIsTypeModalOpen(false);
    setDraftContent(null);
    setContentModal(null);
    setCourseQuery("");
    setCourseQueryByOption({});
    setActiveCourseOptionKey("");
  }, [selectedSceneId]);

  const selectedScene = useMemo(
    () => scenario.scenes.find((scene) => scene.id === selectedSceneId) || null,
    [scenario.scenes, selectedSceneId],
  );

  const selectedSceneIndex = useMemo(
    () => scenario.scenes.findIndex((scene) => scene.id === selectedSceneId),
    [scenario.scenes, selectedSceneId],
  );

  const rootSceneId = useMemo(() => {
    if (scenario.entrySceneId) return scenario.entrySceneId;
    return scenario.scenes[0]?.id || "";
  }, [scenario.entrySceneId, scenario.scenes]);

  const selectedSceneHasBranch = useMemo(
    () =>
      selectedScene?.contents.some(
        (content) => content.type === OnboardingContentType.BRANCH,
      ) || false,
    [selectedScene],
  );

  const activeContentData = useMemo(() => {
    if (!contentModal) return null;
    const sceneIndex = scenario.scenes.findIndex(
      (scene) => scene.id === contentModal.sceneId,
    );
    if (sceneIndex < 0) return null;
    if (contentModal.mode === "create") {
      if (!draftContent || draftContent.sceneId !== contentModal.sceneId) {
        return null;
      }
      return {
        sceneId: contentModal.sceneId,
        sceneIndex,
        contentIndex: -1,
        content: draftContent.content,
        mode: "create" as const,
      };
    }
    const scene = scenario.scenes[sceneIndex];
    const contentIndex = scene.contents.findIndex(
      (content) => content.id === contentModal.contentId,
    );
    if (contentIndex < 0) return null;
    return {
      sceneId: scene.id,
      sceneIndex,
      contentIndex,
      content: scene.contents[contentIndex],
      mode: "edit" as const,
    };
  }, [contentModal, draftContent, scenario.scenes]);

  useEffect(() => {
    if (!activeContentData) return;
    if (activeContentData.content.type !== OnboardingContentType.BRANCH) return;
    const courseIds = (
      activeContentData.content.branch?.options.flatMap(
        (option) => option.courses || [],
      ) || []
    ).filter(Boolean);
    const uniqueIds = Array.from(new Set(courseIds)).filter(
      (id) => !courseMap[id],
    );
    if (!uniqueIds.length) return;

    let active = true;
    const fetchCourseDetails = async () => {
      try {
        const results = await Promise.all(
          uniqueIds.map(async (id) => {
            try {
              const res = await courseService.getById(id);
              return { id, course: res?.data ?? res };
            } catch (error) {
              console.error("fetchCourseById", error);
              return null;
            }
          }),
        );
        if (!active) return;
        setCourseMap((prev) => {
          const next = { ...prev };
          results.forEach((item) => {
            if (item && item.course) {
              next[item.id] = item.course as ICourse;
            }
          });
          return next;
        });
      } catch (error) {
        console.error("fetchCourseDetails", error);
      }
    };
    fetchCourseDetails();
    return () => {
      active = false;
    };
  }, [activeContentData, courseMap]);

  useEffect(() => {
    if (contentModal && !activeContentData) {
      setContentModal(null);
      setDraftContent(null);
    }
  }, [contentModal, activeContentData]);

  const updateScenario = (
    updater: (
      current: IOnboardingScenarioBranching,
    ) => IOnboardingScenarioBranching,
  ) => setScenario((prev) => normalizeScenario(updater(prev)));

  const updateContent = (
    sceneIndex: number,
    contentIndex: number,
    updater: (
      content: IOnboardingScenarioContentItem,
    ) => IOnboardingScenarioContentItem,
  ) => {
    if (contentModal?.mode === "create") {
      setDraftContent((prev) =>
        prev ? { ...prev, content: updater(prev.content) } : prev,
      );
      return;
    }
    updateScenario((prev) => ({
      ...prev,
      scenes: prev.scenes.map((scene, sIndex) =>
        sIndex === sceneIndex
          ? {
              ...scene,
              contents: scene.contents.map((item, cIndex) =>
                cIndex === contentIndex ? updater(item) : item,
              ),
            }
          : scene,
      ),
    }));
  };

  const handleReorderContents = (
    sceneId: string,
    activeId: number,
    overId: number,
  ) => {
    updateScenario((prev) => {
      const sceneIndex = prev.scenes.findIndex((scene) => scene.id === sceneId);
      if (sceneIndex < 0) return prev;
      const contents = prev.scenes[sceneIndex].contents;
      const activeIndex = contents.findIndex((item) => item.id === activeId);
      const overIndex = contents.findIndex((item) => item.id === overId);

      if (activeIndex === -1 || overIndex === -1 || activeIndex === overIndex) {
        return prev;
      }

      const reordered = arrayMove(contents, activeIndex, overIndex);

      return {
        ...prev,
        scenes: prev.scenes.map((scene, sIndex) =>
          sIndex === sceneIndex ? { ...scene, contents: reordered } : scene,
        ),
      };
    });
  };

  const handleAddScene = () => {
    const nextId = createSceneId(scenario.scenes);
    updateScenario((prev) => {
      const nextScene: IOnboardingScenarioScene = {
        id: nextId,
        contents: [],
      };
      return {
        ...prev,
        entrySceneId: prev.entrySceneId || nextScene.id,
        scenes: [...prev.scenes, nextScene],
      };
    });
    setSelectedSceneId(nextId);
  };

  const handleRemoveScene = (sceneId: string) => {
    updateScenario((prev) => {
      const scenes = prev.scenes.filter((scene) => scene.id !== sceneId);
      let entrySceneId = prev.entrySceneId;
      if (entrySceneId === sceneId) {
        entrySceneId = scenes[0]?.id || "";
      }
      return { ...prev, scenes, entrySceneId };
    });
    if (selectedSceneId === sceneId) {
      setSelectedSceneId("");
    }
  };

  const handleSelectContentType = (type: OnboardingContentType) => {
    if (selectedSceneIndex < 0 || !selectedSceneId) {
      showError("Vui lòng chọn scene trước.");
      return;
    }
    if (
      type === OnboardingContentType.PERSON_ADMIRE &&
      selectedSceneId !== rootSceneId
    ) {
      showError("Person Admire chỉ được thêm ở scene Entry.");
      return;
    }
    if (type === OnboardingContentType.BRANCH && selectedSceneHasBranch) {
      showError("Mỗi scene chỉ được có 1 branch.");
      return;
    }
    const nextId = nextNumericId(
      scenario.scenes[selectedSceneIndex]?.contents || [],
    );
    const draft = normalizeActivationContent(createContent(nextId, type));
    setDraftContent({ sceneId: selectedSceneId, content: draft });
    setContentModal({
      sceneId: selectedSceneId,
      contentId: draft.id,
      mode: "create",
    });
    setIsTypeModalOpen(false);
  };

  const handleSetEntryScene = async (sceneId: string) => {
    const nextScenario = normalizeScenario({
      ...scenario,
      entrySceneId: sceneId,
    });
    setScenario(nextScenario);
    await handleSave(nextScenario);
  };

  const handleConfirmAction = async () => {
    if (!confirmDialog) return;
    if (confirmDialog.type === "deleteScene") {
      handleRemoveScene(confirmDialog.sceneId);
      setConfirmDialog(null);
      return;
    }
    if (confirmDialog.type === "setEntry") {
      await handleSetEntryScene(confirmDialog.sceneId);
      setConfirmDialog(null);
    }
  };

  const normalizedSceneLabelQuery = sceneLabelQuery.trim().toLowerCase();

  const getOptionLabelText = (option: IOnboardingScenarioBranchOption) =>
    getDisplayTranslationValue(option.label, lang) || `Option ${option.id}`;

  const matchesSceneLabelQuery = (value: string) =>
    !normalizedSceneLabelQuery ||
    value.toLowerCase().includes(normalizedSceneLabelQuery);

  const doesSceneMatchQuery = (
    sceneId: string,
    cache: Map<string, boolean>,
    visited = new Set<string>(),
  ) => {
    if (cache.has(sceneId)) {
      return cache.get(sceneId) as boolean;
    }
    if (visited.has(sceneId)) {
      return false;
    }
    const scene = scenario.scenes.find((item) => item.id === sceneId);
    if (!scene) {
      cache.set(sceneId, false);
      return false;
    }
    visited.add(sceneId);
    const branchOptions = getSceneBranchOptions(scene);
    const matched = branchOptions.some((option) => {
      const labelText = getOptionLabelText(option);
      if (matchesSceneLabelQuery(labelText)) {
        return true;
      }
      return option.nextSceneId
        ? doesSceneMatchQuery(option.nextSceneId, cache, visited)
        : false;
    });
    cache.set(sceneId, matched);
    return matched;
  };

  const getCourseTitle = (courseId: string) => {
    const course =
      courseMap[courseId] || courses.find((item) => item._id === courseId);
    return course ? getDisplayTranslationValue(course.title, lang) : courseId;
  };

  const renderSceneOptions = (
    sceneId: string,
    depth = 0,
    visited = new Set<string>(),
  ) => {
    const scene = scenario.scenes.find((item) => item.id === sceneId);
    if (!scene) return null;
    if (visited.has(scene.id)) {
      return (
        <div
          className="text-xs text-rose-500"
          style={{ marginLeft: depth * 16 }}
        >
          Loop detected
        </div>
      );
    }
    const nextVisited = new Set(visited);
    nextVisited.add(scene.id);
    const branchOptions = getSceneBranchOptions(scene);

    if (!branchOptions.length) return null;

    const searchCache = new Map<string, boolean>();
    const filteredOptions = branchOptions.filter((option) => {
      if (!normalizedSceneLabelQuery) return true;
      const labelText = getOptionLabelText(option);
      if (matchesSceneLabelQuery(labelText)) return true;
      return option.nextSceneId
        ? doesSceneMatchQuery(option.nextSceneId, searchCache)
        : false;
    });

    if (!filteredOptions.length) return null;

    return (
      <div className="space-y-2">
        {filteredOptions.map((option) => {
          const rawLabel = getOptionLabelText(option);
          const paddedLabel = rawLabel.padEnd(20, " ");
          return (
            <div
              key={`${scene.id}-option-${option.id}-${option.nextSceneId}`}
              className="space-y-2"
            >
              <div
                className="flex items-center gap-2 text-xs text-slate-500"
                style={{ marginLeft: depth * 16 }}
              >
                <span className="text-slate-400">({depth})</span>
                <TextWithTooltip
                  text={paddedLabel}
                  maxLength={20}
                  className="text-slate-600 w-[20ch] inline-block whitespace-pre"
                />
                <span className="text-slate-400">=&gt;</span>
                {option.nextSceneId ? (
                  <button
                    type="button"
                    onClick={(event) => {
                      event.stopPropagation();
                      if (option.nextSceneId) {
                        setSelectedSceneId(option.nextSceneId);
                      }
                    }}
                    className="text-blue-600 underline decoration-dashed underline-offset-2 hover:text-blue-700"
                    title={`Go to ${option.nextSceneId}`}
                  >
                    {option.nextSceneId}
                  </button>
                ) : (
                  <span className="text-slate-400">—</span>
                )}
              </div>
              {option.nextSceneId
                ? renderSceneOptions(option.nextSceneId, depth + 1, nextVisited)
                : null}
            </div>
          );
        })}
      </div>
    );
  };

  const renderRootScene = (sceneId: string) => {
    const scene = scenario.scenes.find((item) => item.id === sceneId);
    if (!scene) return null;
    const isActive = scene.id === selectedSceneId;
    const hasSearchMatch =
      !normalizedSceneLabelQuery ||
      doesSceneMatchQuery(scene.id, new Map<string, boolean>());

    return (
      <div className="space-y-3">
        <div
          role="button"
          tabIndex={0}
          onClick={() => setSelectedSceneId(scene.id)}
          onKeyDown={(event) => {
            if (event.key === "Enter") {
              setSelectedSceneId(scene.id);
            }
          }}
          className={`rounded-2xl border px-4 py-3 text-left transition-all duration-200 ${
            isActive
              ? "border-blue-300 bg-blue-50 text-slate-900 shadow-sm"
              : "border-slate-200 bg-white text-slate-800 hover:border-slate-300 hover:shadow-sm"
          }`}
        >
          <div className="flex items-center justify-between gap-3">
            <div>
              <p className="text-sm font-semibold">{scene.id}</p>
            </div>
            <div className="flex items-center gap-2">
              {scene.id === scenario.entrySceneId && (
                <span
                  className={`rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase ${
                    isActive
                      ? "bg-blue-200 text-blue-800"
                      : "bg-blue-50 text-blue-700"
                  }`}
                >
                  Entry
                </span>
              )}
            </div>
          </div>
        </div>
        {hasSearchMatch ? (
          renderSceneOptions(scene.id, 1)
        ) : (
          <div className="text-xs text-slate-400">Không tìm thấy kết quả.</div>
        )}
      </div>
    );
  };

  const handleAddSceneAndLinkOption = (
    sceneIndex: number,
    contentIndex: number,
    optionIndex: number,
  ) => {
    updateScenario((prev) => {
      const parentScene = prev.scenes[sceneIndex];
      const parentSceneId = parentScene?.id;
      if (!parentSceneId) {
        return prev;
      }
      const optionId =
        parentScene.contents[contentIndex]?.branch?.options?.[optionIndex]
          ?.id ?? optionIndex + 1;
      const nextId = getNextSceneIdForOption(
        prev.scenes,
        parentSceneId,
        optionId,
      );
      const nextScene: IOnboardingScenarioScene = {
        id: nextId,
        contents: [],
      };
      const scenes = prev.scenes.map((scene, sIndex) =>
        sIndex === sceneIndex
          ? {
              ...scene,
              contents: scene.contents.map((item, cIndex) =>
                cIndex === contentIndex
                  ? withBranch(item, (branch) => ({
                      ...branch,
                      options: branch.options.map((option, oIndex) =>
                        oIndex === optionIndex
                          ? { ...option, nextSceneId: nextId }
                          : option,
                      ),
                    }))
                  : item,
              ),
            }
          : scene,
      );
      return {
        ...prev,
        entrySceneId: prev.entrySceneId || nextId,
        scenes: [...scenes, nextScene],
      };
    });
  };

  const handleAddSceneAndLinkDraftOption = (optionIndex: number) => {
    if (!draftContent) return;
    const optionId =
      draftContent.content.branch?.options?.[optionIndex]?.id ??
      optionIndex + 1;
    const nextId = getNextSceneIdForOption(
      scenario.scenes,
      draftContent.sceneId,
      optionId,
    );
    updateScenario((prev) => {
      const nextScene: IOnboardingScenarioScene = {
        id: nextId,
        contents: [],
      };
      return {
        ...prev,
        entrySceneId: prev.entrySceneId || nextId,
        scenes: [...prev.scenes, nextScene],
      };
    });
    setDraftContent((prev) =>
      prev
        ? {
            ...prev,
            content: withBranch(prev.content, (branch) => ({
              ...branch,
              options: branch.options.map((option, oIndex) =>
                oIndex === optionIndex
                  ? { ...option, nextSceneId: nextId }
                  : option,
              ),
            })),
          }
        : prev,
    );
  };

  const handleAddCourseToOption = (
    sceneIndex: number,
    contentIndex: number,
    optionIndex: number,
    courseId: string,
    optionKey?: string,
  ) => {
    updateContent(sceneIndex, contentIndex, (item) =>
      withBranch(item, (branch) => ({
        ...branch,
        options: branch.options.map((optionItem, oIndex) => {
          if (oIndex !== optionIndex) return optionItem;
          const current = optionItem.courses || [];
          if (current.includes(courseId)) return optionItem;
          return {
            ...optionItem,
            courses: [...current, courseId],
          };
        }),
      })),
    );
    setCourseQuery("");
    if (optionKey) {
      setCourseQueryByOption((prev) => ({
        ...prev,
        [optionKey]: "",
      }));
    }
    setActiveCourseOptionKey("");
  };

  const handleRemoveCourseFromOption = (
    sceneIndex: number,
    contentIndex: number,
    optionIndex: number,
    courseId: string,
  ) => {
    updateContent(sceneIndex, contentIndex, (item) =>
      withBranch(item, (branch) => ({
        ...branch,
        options: branch.options.map((optionItem, oIndex) => {
          if (oIndex !== optionIndex) return optionItem;
          return {
            ...optionItem,
            courses: (optionItem.courses || []).filter((id) => id !== courseId),
          };
        }),
      })),
    );
  };

  const handleSave = async (
    scenarioOverride?: IOnboardingScenarioBranching,
  ) => {
    if (!scenarioId) {
      showError("Không tìm thấy onboarding id để lưu.");
      return false;
    }

    setIsSaving(true);
    try {
      const scenarioForSave = ensureScenarioActivation(
        scenarioOverride || scenario,
      );
      if (!scenarioOverride) {
        setScenario(scenarioForSave);
      }
      const payload = sanitizeScenario(scenarioForSave);
      const payloadToSend = addLegacyActivations(payload);
      await onboardingService.updateScenarioBranching(
        scenarioId,
        payloadToSend,
      );
      showSuccess("Đã lưu dữ liệu thành công.");
      return true;
    } catch (error) {
      showError("Lưu thất bại. Vui lòng kiểm tra lại dữ liệu.");
      return false;
    } finally {
      setIsSaving(false);
    }
  };

  const closeContentModal = () => {
    setContentModal(null);
    setDraftContent(null);
  };

  const handleSubmitContentModal = async () => {
    if (!contentModal) return;
    if (contentModal.mode === "create") {
      if (!draftContent) {
        showError("Vui lòng nhập nội dung trước khi tạo.");
        return;
      }
      const nextScenario = normalizeScenario({
        ...scenario,
        scenes: scenario.scenes.map((scene) =>
          scene.id === draftContent.sceneId
            ? {
                ...scene,
                contents: [
                  ...scene.contents,
                  normalizeActivationContent(draftContent.content),
                ],
              }
            : scene,
        ),
      });
      const saved = await handleSave(nextScenario);
      if (saved) {
        setScenario(nextScenario);
        closeContentModal();
      }
      return;
    }

    const saved = await handleSave();
    if (saved) {
      closeContentModal();
    }
  };

  const renderContentEditor = (
    content: IOnboardingScenarioContentItem,
    sceneIndex: number,
    contentIndex: number,
  ) => (
    <div className="space-y-6">
      {content.type === OnboardingContentType.FACT && content.fact ? (
        <div className="space-y-4">
          <LabelEditor
            label={content.fact}
            title="Fact label"
            lang={lang}
            tone="blue"
            showTitleInput={false}
            onChange={(nextLabel) =>
              updateContent(sceneIndex, contentIndex, (item) =>
                item.type === OnboardingContentType.FACT
                  ? { ...item, fact: nextLabel }
                  : item,
              )
            }
          />
        </div>
      ) : null}

      {content.type === OnboardingContentType.ACTIVATION &&
      content.activation ? (
        <div className="space-y-4">
          <div className="rounded-2xl border border-slate-200 bg-white p-4">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <p className="text-sm font-semibold text-slate-700">
                Activation {content.activation.id}
              </p>
            </div>

            <div className="mt-3 w-52">
              <CloudflareFileUpload
                initialUrl={content.activation.content.icon || ""}
                onUrlChange={(newUrl) =>
                  updateContent(sceneIndex, contentIndex, (item) =>
                    item.type === OnboardingContentType.ACTIVATION &&
                    item.activation
                      ? {
                          ...item,
                          activation: {
                            ...item.activation,
                            content: {
                              ...item.activation.content,
                              icon: newUrl,
                            },
                          },
                        }
                      : item,
                  )
                }
                label="Icon"
                uploadPayload={{
                  prefix: "",
                  folder: "onboarding",
                }}
              />
            </div>

            <div className="mt-3">
              <TranslationInputs
                label="Title"
                value={content.activation.title}
                lang={lang}
                tone="emerald"
                onChange={(nextValue) =>
                  updateContent(sceneIndex, contentIndex, (item) =>
                    item.type === OnboardingContentType.ACTIVATION &&
                    item.activation
                      ? {
                          ...item,
                          activation: {
                            ...item.activation,
                            title: nextValue,
                          },
                        }
                      : item,
                  )
                }
              />
            </div>

            <div className="mt-3">
              <TranslationInputs
                label="Description"
                value={content.activation.description}
                lang={lang}
                tone="emerald"
                onChange={(nextValue) =>
                  updateContent(sceneIndex, contentIndex, (item) =>
                    item.type === OnboardingContentType.ACTIVATION &&
                    item.activation
                      ? {
                          ...item,
                          activation: {
                            ...item.activation,
                            description: nextValue,
                          },
                        }
                      : item,
                  )
                }
              />
            </div>

            <div className="mt-4 space-y-3">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <span className={`${labelTextClass} ${toneClasses.emerald}`}>
                  Labels
                </span>
              </div>

              {content.activation.content.labels.map(
                (labelItem, labelIndex) => (
                  <LabelEditor
                    key={labelItem.id}
                    label={labelItem}
                    title={`Label ${labelItem.id}`}
                    lang={lang}
                    tone="emerald"
                    showIconUpload={false}
                    showTitleInput={false}
                    onChange={(nextLabel) =>
                      updateContent(sceneIndex, contentIndex, (item) =>
                        item.type === OnboardingContentType.ACTIVATION &&
                        item.activation
                          ? {
                              ...item,
                              activation: {
                                ...item.activation,
                                content: {
                                  ...item.activation.content,
                                  labels: item.activation.content.labels.map(
                                    (labelEntry, lIndex) =>
                                      lIndex === labelIndex
                                        ? nextLabel
                                        : labelEntry,
                                  ),
                                },
                              },
                            }
                          : item,
                      )
                    }
                    onRemove={() =>
                      updateContent(sceneIndex, contentIndex, (item) =>
                        item.type === OnboardingContentType.ACTIVATION &&
                        item.activation
                          ? {
                              ...item,
                              activation: {
                                ...item.activation,
                                content: {
                                  ...item.activation.content,
                                  labels: reindexLabels(
                                    item.activation.content.labels.filter(
                                      (_, lIndex) => lIndex !== labelIndex,
                                    ),
                                  ),
                                },
                              },
                            }
                          : item,
                      )
                    }
                  />
                ),
              )}
              <div className="mt-4 flex justify-center">
                <button
                  type="button"
                  onClick={() =>
                    updateContent(sceneIndex, contentIndex, (item) =>
                      item.type === OnboardingContentType.ACTIVATION &&
                      item.activation
                        ? {
                            ...item,
                            activation: {
                              ...item.activation,
                              content: {
                                ...item.activation.content,
                                labels: [
                                  ...item.activation.content.labels,
                                  createLabel(
                                    nextNumericId(
                                      item.activation.content.labels,
                                    ),
                                  ),
                                ],
                              },
                            },
                          }
                        : item,
                    )
                  }
                  className={iconButtonAddClass}
                  aria-label="Add label"
                  title="Add label"
                >
                  <PlusIcon className="h-4 w-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : null}

      {content.type === OnboardingContentType.BRANCH && content.branch ? (
        <div className="space-y-4">
          <TranslationInputs
            label="Sub question"
            value={content.branch.subQuestion}
            lang={lang}
            tone="amber"
            onChange={(nextValue) =>
              updateContent(sceneIndex, contentIndex, (item) =>
                withBranch(item, (branch) => ({
                  ...branch,
                  subQuestion: nextValue,
                })),
              )
            }
          />
          <TranslationInputs
            label="Question"
            value={content.branch.question}
            lang={lang}
            tone="amber"
            onChange={(nextValue) =>
              updateContent(sceneIndex, contentIndex, (item) =>
                withBranch(item, (branch) => ({
                  ...branch,
                  question: nextValue,
                })),
              )
            }
          />
          <div className="flex flex-wrap items-center justify-between gap-2">
            <p className="text-xs font-semibold uppercase tracking-[0.2em]">
              Options
            </p>
          </div>
          <div className="space-y-3">
            {content.branch.options.map((option, optionIndex) => (
              <div
                key={option.id}
                className="rounded-2xl border border-slate-200 bg-white p-4"
              >
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <p className="text-sm font-semibold text-sky-400">
                    Option {option.id}
                  </p>
                  <button
                    type="button"
                    onClick={() =>
                      updateContent(sceneIndex, contentIndex, (item) =>
                        withBranch(item, (branch) => ({
                          ...branch,
                          options: reindexOptions(
                            branch.options.filter(
                              (_, oIndex) => oIndex !== optionIndex,
                            ),
                          ),
                        })),
                      )
                    }
                    className={iconButtonDangerClass}
                    aria-label="Remove option"
                    title="Remove option"
                  >
                    <TrashIcon className="h-4 w-4" />
                  </button>
                </div>
                <div className="mt-3 w-52">
                  <CloudflareFileUpload
                    initialUrl={option.icon || ""}
                    onUrlChange={(newUrl) =>
                      updateContent(sceneIndex, contentIndex, (item) =>
                        withBranch(item, (branch) => ({
                          ...branch,
                          options: branch.options.map((optionItem, oIndex) =>
                            oIndex === optionIndex
                              ? { ...optionItem, icon: newUrl }
                              : optionItem,
                          ),
                        })),
                      )
                    }
                    label="Icon"
                    uploadPayload={{
                      prefix: "",
                      folder: "onboarding",
                    }}
                  />
                </div>
                <div className="mt-3">
                  <TranslationInputs
                    label="Label"
                    value={option.label}
                    lang={lang}
                    tone="amber"
                    onChange={(nextValue) =>
                      updateContent(sceneIndex, contentIndex, (item) =>
                        withBranch(item, (branch) => ({
                          ...branch,
                          options: branch.options.map((optionItem, oIndex) =>
                            oIndex === optionIndex
                              ? { ...optionItem, label: nextValue }
                              : optionItem,
                          ),
                        })),
                      )
                    }
                  />
                </div>
                <div className="mt-3 space-y-1">
                  <span className={labelTextClass}>Next scene ID</span>
                  <div className="flex flex-wrap items-center gap-2">
                    <select
                      className={`${textInputClass} flex-1 w-auto`}
                      value={option.nextSceneId || ""}
                      onChange={(event) =>
                        updateContent(sceneIndex, contentIndex, (item) =>
                          withBranch(item, (branch) => ({
                            ...branch,
                            options: branch.options.map((optionItem, oIndex) =>
                              oIndex === optionIndex
                                ? {
                                    ...optionItem,
                                    nextSceneId: event.target.value,
                                  }
                                : optionItem,
                            ),
                          })),
                        )
                      }
                    >
                      <option value="">Chọn scene tiếp theo</option>
                      {(scenario.scenes[sceneIndex]?.id
                        ? getDirectChildScenes(
                            scenario.scenes,
                            scenario.scenes[sceneIndex].id,
                          )
                        : []
                      ).map((scene) => (
                        <option key={scene.id} value={scene.id}>
                          {scene.id}
                        </option>
                      ))}
                    </select>
                    <button
                      type="button"
                      onClick={() =>
                        contentModal?.mode === "create"
                          ? handleAddSceneAndLinkDraftOption(optionIndex)
                          : handleAddSceneAndLinkOption(
                              sceneIndex,
                              contentIndex,
                              optionIndex,
                            )
                      }
                      className={iconButtonAddClass}
                      aria-label="Create scene and link"
                      title="Create scene and link"
                    >
                      <PlusIcon className="h-4 w-4" />
                    </button>
                  </div>
                </div>
                <div className="mt-4 space-y-2">
                    <span className={`${labelTextClass} ${toneClasses.amber}`}>
                      Courses
                    </span>
                    {(() => {
                      const courseOptionKey = `${sceneIndex}-${contentIndex}-${optionIndex}`;
                      const optionCourseQuery =
                        courseQueryByOption[courseOptionKey] || "";
                      const isCourseOptionActive =
                        activeCourseOptionKey === courseOptionKey;
                      return (
                        <>
                    <input
                      value={optionCourseQuery}
                      onFocus={() => {
                        setActiveCourseOptionKey(courseOptionKey);
                        setCourseQuery(optionCourseQuery);
                      }}
                      onChange={(event) => {
                        const nextValue = event.target.value;
                        setCourseQueryByOption((prev) => ({
                          ...prev,
                          [courseOptionKey]: nextValue,
                        }));
                        setActiveCourseOptionKey(courseOptionKey);
                        setCourseQuery(nextValue);
                      }}
                      placeholder="Search course..."
                      className={`${textInputClass} text-xs`}
                    />
                    {isCourseOptionActive && optionCourseQuery.trim() ? (
                      <div className="max-h-32 space-y-2 overflow-y-auto rounded-xl border border-slate-200 bg-white p-2">
                        {isCourseLoading ? (
                          <p className="text-xs text-slate-400">Loading...</p>
                        ) : courses.length ? (
                          courses.map((course) => {
                            const title =
                              getDisplayTranslationValue(course.title, lang) ||
                              course._id;
                            const isSelected =
                              option.courses?.includes(course._id) || false;
                            return (
                              <button
                                key={course._id}
                                type="button"
                                onClick={() =>
                                  handleAddCourseToOption(
                                    sceneIndex,
                                    contentIndex,
                                    optionIndex,
                                    course._id,
                                    courseOptionKey,
                                  )
                                }
                                disabled={isSelected}
                                className={`flex w-full items-center justify-between rounded-lg px-3 py-2 text-left text-xs transition ${
                                  isSelected
                                    ? "cursor-not-allowed bg-slate-100 text-slate-400"
                                    : "bg-slate-50 text-slate-700 hover:bg-slate-100"
                                }`}
                              >
                                <TextWithTooltip
                                  text={title}
                                  maxLength={32}
                                  className="text-slate-700"
                                />
                                <span className="text-slate-400">
                                  {isSelected ? "Added" : "Add"}
                                </span>
                              </button>
                            );
                          })
                        ) : (
                          <p className="text-xs text-slate-400">
                            Không tìm thấy course.
                          </p>
                        )}
                      </div>
                    ) : isCourseOptionActive ? (
                      <p className="text-xs text-slate-400">
                        Nhập từ khoá để tìm course.
                      </p>
                    ) : null}
                    {option.courses?.length ? (
                      <div className="flex flex-wrap gap-2">
                        {option.courses.map((courseId) => (
                          <span
                            key={`${option.id}-${courseId}`}
                            className="flex items-center gap-2 rounded-full border border-slate-200 bg-white px-3 py-1 text-xs text-slate-600"
                          >
                            <TextWithTooltip
                              text={getCourseTitle(courseId)}
                              maxLength={28}
                              className="text-slate-600"
                            />
                            <button
                              type="button"
                              onClick={() =>
                                handleRemoveCourseFromOption(
                                  sceneIndex,
                                  contentIndex,
                                  optionIndex,
                                  courseId,
                                )
                              }
                              className="text-rose-500 hover:text-rose-600"
                              aria-label="Remove course"
                              title="Remove course"
                            >
                              <XMarkIcon className="h-4 w-4" />
                            </button>
                          </span>
                        ))}
                      </div>
                    ) : null}
                        </>
                      );
                    })()}
                  </div>
              </div>
            ))}
          </div>
          <div className="mt-4 flex justify-center">
            <button
              type="button"
              onClick={() =>
                updateContent(sceneIndex, contentIndex, (item) =>
                  withBranch(item, (branch) => ({
                    ...branch,
                    options: [
                      ...branch.options,
                      {
                        id: nextNumericId(branch.options),
                        label: createTranslation(),
                        icon: "",
                        nextSceneId: "",
                        courses: [],
                      },
                    ],
                  })),
                )
              }
              className={iconButtonAddClass}
              aria-label="Add option"
              title="Add option"
            >
              <PlusIcon className="h-4 w-4" />
            </button>
          </div>
        </div>
      ) : null}

      {content.type === OnboardingContentType.PERSON_ADMIRE &&
      content.personAdmire ? (
        <div className="space-y-4">
          <TranslationInputs
            label="Sub question"
            value={content.personAdmire.subQuestion}
            lang={lang}
            tone="emerald"
            onChange={(nextValue) =>
              updateContent(sceneIndex, contentIndex, (item) =>
                withPersonAdmire(item, (personAdmire) => ({
                  ...personAdmire,
                  subQuestion: nextValue,
                })),
              )
            }
          />
          <TranslationInputs
            label="Question"
            value={content.personAdmire.question}
            lang={lang}
            tone="emerald"
            onChange={(nextValue) =>
              updateContent(sceneIndex, contentIndex, (item) =>
                withPersonAdmire(item, (personAdmire) => ({
                  ...personAdmire,
                  question: nextValue,
                })),
              )
            }
          />
          <div className="flex flex-wrap items-center justify-between gap-2">
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-emerald-600">
              Options
            </p>
          </div>
          <div className="space-y-3">
            {content.personAdmire.options.map((option, optionIndex) => (
              <div
                key={`person-admire-${optionIndex}`}
                className="rounded-2xl border border-slate-200 bg-white p-4"
              >
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <p className="text-sm font-semibold text-sky-400">
                    Option {optionIndex + 1}
                  </p>
                  <button
                    type="button"
                    onClick={() =>
                      updateContent(sceneIndex, contentIndex, (item) =>
                        withPersonAdmire(item, (personAdmire) => ({
                          ...personAdmire,
                          options: personAdmire.options.filter(
                            (_, index) => index !== optionIndex,
                          ),
                        })),
                      )
                    }
                    className={iconButtonDangerClass}
                    aria-label="Remove option"
                    title="Remove option"
                  >
                    <TrashIcon className="h-4 w-4" />
                  </button>
                </div>

                <div className="mt-3 w-52">
                  <CloudflareFileUpload
                    initialUrl={option.image || ""}
                    onUrlChange={(newUrl) =>
                      updateContent(sceneIndex, contentIndex, (item) =>
                        withPersonAdmire(item, (personAdmire) => ({
                          ...personAdmire,
                          options: personAdmire.options.map((entry, index) =>
                            index === optionIndex
                              ? { ...entry, image: newUrl }
                              : entry,
                          ),
                        })),
                      )
                    }
                    label="Image"
                    uploadPayload={{
                      prefix: "",
                      folder: "onboarding",
                    }}
                  />
                </div>

                <div className="mt-3">
                  <label className="space-y-1">
                    <span className={labelTextClass}>Name</span>
                    <input
                      className={textInputClass}
                      value={option.name}
                      onChange={(event) =>
                        updateContent(sceneIndex, contentIndex, (item) =>
                          withPersonAdmire(item, (personAdmire) => ({
                            ...personAdmire,
                            options: personAdmire.options.map(
                              (entry, index) =>
                                index === optionIndex
                                  ? { ...entry, name: event.target.value }
                                  : entry,
                            ),
                          })),
                        )
                      }
                    />
                  </label>
                </div>

                <div className="mt-3">
                  <TranslationInputs
                    label="Title"
                    value={option.title}
                    lang={lang}
                    tone="emerald"
                    onChange={(nextValue) =>
                      updateContent(sceneIndex, contentIndex, (item) =>
                        withPersonAdmire(item, (personAdmire) => ({
                          ...personAdmire,
                          options: personAdmire.options.map(
                            (entry, index) =>
                              index === optionIndex
                                ? { ...entry, title: nextValue }
                                : entry,
                          ),
                        })),
                      )
                    }
                  />
                </div>

                <div className="mt-3">
                  <TranslationInputs
                    label="Sub title"
                    value={option.subTitle}
                    lang={lang}
                    tone="emerald"
                    onChange={(nextValue) =>
                      updateContent(sceneIndex, contentIndex, (item) =>
                        withPersonAdmire(item, (personAdmire) => ({
                          ...personAdmire,
                          options: personAdmire.options.map(
                            (entry, index) =>
                              index === optionIndex
                                ? { ...entry, subTitle: nextValue }
                                : entry,
                          ),
                        })),
                      )
                    }
                  />
                </div>
              </div>
            ))}
          </div>

          <div className="mt-4 flex justify-center">
            <button
              type="button"
              onClick={() =>
                updateContent(sceneIndex, contentIndex, (item) =>
                  withPersonAdmire(item, (personAdmire) => ({
                    ...personAdmire,
                    options: [
                      ...(personAdmire.options || []),
                      (() => {
                        const previousOption =
                          personAdmire.options?.[
                            (personAdmire.options?.length || 1) - 1
                          ];
                        return previousOption
                          ? createPersonAdmireOption({
                              title: previousOption.title,
                              subTitle: previousOption.subTitle,
                            })
                          : createPersonAdmireOption();
                      })(),
                    ],
                  })),
                )
              }
              className={iconButtonAddClass}
              aria-label="Add option"
              title="Add option"
            >
              <PlusIcon className="h-4 w-4" />
            </button>
          </div>
        </div>
      ) : null}

      {content.type === OnboardingContentType.FIXED && content.fixed ? (
        <div className="space-y-4">
          <TranslationInputs
            label="Sub question"
            value={content.fixed.subQuestion}
            lang={lang}
            tone="blue"
            onChange={(nextValue) =>
              updateContent(sceneIndex, contentIndex, (item) =>
                withFixed(item, (fixed) => ({
                  ...fixed,
                  subQuestion: nextValue,
                })),
              )
            }
          />
          <TranslationInputs
            label="Question"
            value={content.fixed.question}
            lang={lang}
            tone="blue"
            onChange={(nextValue) =>
              updateContent(sceneIndex, contentIndex, (item) =>
                withFixed(item, (fixed) => ({
                  ...fixed,
                  question: nextValue,
                })),
              )
            }
          />
          <div className="flex flex-wrap items-center justify-between gap-2">
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-blue-600">
              Options
            </p>
          </div>
          <div className="space-y-3">
            {content.fixed.options.map((option, optionIndex) => (
              <LabelEditor
                key={option.id}
                label={option}
                title={`Option ${option.id}`}
                lang={lang}
                tone="blue"
                showTitleInput={false}
                onChange={(nextLabel) =>
                  updateContent(sceneIndex, contentIndex, (item) =>
                    withFixed(item, (fixed) => ({
                      ...fixed,
                      options: fixed.options.map((optionItem, oIndex) =>
                        oIndex === optionIndex ? nextLabel : optionItem,
                      ),
                    })),
                  )
                }
                onRemove={() =>
                  updateContent(sceneIndex, contentIndex, (item) =>
                    withFixed(item, (fixed) => ({
                      ...fixed,
                      options: reindexLabels(
                        fixed.options.filter(
                          (_, oIndex) => oIndex !== optionIndex,
                        ),
                      ),
                    })),
                  )
                }
              />
            ))}
          </div>
          <div className="mt-4 flex justify-center">
            <button
              type="button"
              onClick={() =>
                updateContent(sceneIndex, contentIndex, (item) =>
                  withFixed(item, (fixed) => ({
                    ...fixed,
                    options: [
                      ...fixed.options,
                      createLabel(nextNumericId(fixed.options)),
                    ],
                  })),
                )
              }
              className={iconButtonAddClass}
              aria-label="Add option"
              title="Add option"
            >
              <PlusIcon className="h-4 w-4" />
            </button>
          </div>
        </div>
      ) : null}
    </div>
  );

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      <div className="px-6 py-8" style={{ animation: "fadeIn 0.6s ease both" }}>
        <div className="mx-auto max-w-full">
          <div className="flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
            <div className="space-y-3">
              <h1 className="text-3xl font-semibold text-slate-900 md:text-4xl">
                🗂️ Onboarding Branching
              </h1>
            </div>

            <div className="flex flex-wrap items-center gap-3">
              <button
                type="button"
                onClick={() => {
                  void handleSave();
                }}
                disabled={isSaving || isLoading}
                className={`flex items-center justify-center gap-2 rounded-lg px-6 py-3 text-sm font-semibold text-white shadow transition ${
                  isSaving || isLoading
                    ? "cursor-not-allowed bg-gray-400"
                    : "bg-gradient-to-r from-blue-600 to-green-500 hover:opacity-90"
                }`}
              >
                {isSaving ? "Saving..." : "Save Onboarding"}
              </button>
            </div>
          </div>

          <div className="mt-8 grid gap-6 xl:grid-cols-[380px_minmax(0,1fr)]">
            <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs font-semibold uppercase tracking-[0.3em] text-slate-500">
                    Scenes
                  </p>
                </div>
                <button
                  type="button"
                  onClick={handleAddScene}
                  className="rounded-full border border-slate-200 bg-white px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em] text-slate-600"
                >
                  + Scene
                </button>
              </div>
              <div className="mt-4">
                <label className="space-y-1">
                  <span className={labelTextClass}>Search label</span>
                  <input
                    value={sceneLabelQuery}
                    onChange={(event) => setSceneLabelQuery(event.target.value)}
                    placeholder="Tìm theo label..."
                    className={`${textInputClass} text-xs`}
                  />
                </label>
              </div>

              <div className="mt-5 max-h-[70vh] overflow-y-auto space-y-3 pr-1">
                {!scenario.scenes.length ? (
                  <div className="rounded-2xl border border-dashed border-slate-200 bg-white p-6 text-center text-sm text-slate-500">
                    Chưa có scene. Nhấn “+ Scene” để tạo mới.
                  </div>
                ) : null}

                {rootSceneId ? renderRootScene(rootSceneId) : null}
              </div>
            </section>

            <section className="rounded-2xl border border-slate-200 bg-white shadow-sm">
              <div className="border-b border-slate-200/70 px-6 py-5">
                <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                  <div>
                    <h2 className="text-lg font-semibold text-slate-400">
                      {selectedScene?.id || "Chưa chọn"}
                    </h2>
                  </div>
                  {selectedScene ? (
                    <div className="flex flex-wrap gap-2">
                      <button
                        type="button"
                        onClick={() => {
                          if (!selectedScene) return;
                          setConfirmDialog({
                            type: "setEntry",
                            sceneId: selectedScene.id,
                          });
                        }}
                        className="rounded-full border border-blue-200 bg-blue-50 px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em] text-blue-700"
                      >
                        Set Entry
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          if (!selectedScene) return;
                          setConfirmDialog({
                            type: "deleteScene",
                            sceneId: selectedScene.id,
                          });
                        }}
                        className={iconButtonDangerClass}
                        aria-label="Delete scene"
                        title="Delete scene"
                      >
                        <TrashIcon className="h-4 w-4" />
                      </button>
                    </div>
                  ) : null}
                </div>
              </div>

              <div className="space-y-6 p-6">
                {!selectedScene ? (
                  <div className="rounded-2xl border border-dashed border-slate-200 bg-white p-10 text-center text-sm text-slate-500">
                    Chọn hoặc tạo scene để bắt đầu thêm nội dung.
                  </div>
                ) : (
                  <>
                    <DndContext
                      collisionDetection={closestCenter}
                      onDragEnd={(event) => {
                        const { active, over } = event;
                        if (over && active.id !== over.id) {
                          const activeId =
                            typeof active.id === "string"
                              ? parseInt(active.id, 10)
                              : active.id;
                          const overId =
                            typeof over.id === "string"
                              ? parseInt(over.id, 10)
                              : over.id;
                          handleReorderContents(
                            selectedScene.id,
                            activeId,
                            overId,
                          );
                        }
                      }}
                    >
                      <SortableContext
                        items={selectedScene.contents.map((item) =>
                          item.id.toString(),
                        )}
                        strategy={verticalListSortingStrategy}
                      >
                        <div className="space-y-6">
                          {selectedScene.contents.map(
                            (content, contentIndex) => {
                              const meta = typeMeta[content.type];
                              const sceneIndex = selectedSceneIndex;
                              const factLabel =
                                content.type === OnboardingContentType.FACT
                                  ? stripHtml(
                                      getDisplayTranslationValue(
                                        content.fact?.label,
                                        lang,
                                      ),
                                    )
                                  : "";
                              const factTitle =
                                content.type === OnboardingContentType.FACT
                                  ? getDisplayTranslationValue(
                                      content.fact?.title,
                                      lang,
                                    )
                                  : "";
                              const factIcon =
                                content.type === OnboardingContentType.FACT
                                  ? content.fact?.icon || ""
                                  : "";
                              const activationCount =
                                content.type ===
                                OnboardingContentType.ACTIVATION
                                  ? content.activation
                                    ? 1
                                    : 0
                                  : 0;
                              const activationTitle =
                                content.type ===
                                OnboardingContentType.ACTIVATION
                                  ? getDisplayTranslationValue(
                                      content.activation?.title,
                                      lang,
                                    )
                                  : "";
                              const activationDescription =
                                content.type ===
                                OnboardingContentType.ACTIVATION
                                  ? getDisplayTranslationValue(
                                      content.activation?.description,
                                      lang,
                                    )
                                  : "";
                              const activationIcon =
                                content.type ===
                                OnboardingContentType.ACTIVATION
                                  ? content.activation?.content.icon || ""
                                  : "";
                              const branchQuestion =
                                content.type === OnboardingContentType.BRANCH
                                  ? getDisplayTranslationValue(
                                      content.branch?.question,
                                      lang,
                                    )
                                  : "";
                              const branchSubQuestion =
                                content.type === OnboardingContentType.BRANCH
                                  ? getDisplayTranslationValue(
                                      content.branch?.subQuestion,
                                      lang,
                                    )
                                  : "";
                              const branchOptions =
                                content.type === OnboardingContentType.BRANCH
                                  ? content.branch?.options || []
                                  : [];
                              const fixedQuestion =
                                content.type === OnboardingContentType.FIXED
                                  ? getDisplayTranslationValue(
                                      content.fixed?.question,
                                      lang,
                                    )
                                  : "";
                              const fixedSubQuestion =
                                content.type === OnboardingContentType.FIXED
                                  ? getDisplayTranslationValue(
                                      content.fixed?.subQuestion,
                                      lang,
                                    )
                                  : "";
                              const fixedOptions =
                                content.type === OnboardingContentType.FIXED
                                  ? content.fixed?.options || []
                                  : [];
                              const personAdmireQuestion =
                                content.type ===
                                OnboardingContentType.PERSON_ADMIRE
                                  ? getDisplayTranslationValue(
                                      content.personAdmire?.question,
                                      lang,
                                    )
                                  : "";
                              const personAdmireSubQuestion =
                                content.type ===
                                OnboardingContentType.PERSON_ADMIRE
                                  ? getDisplayTranslationValue(
                                      content.personAdmire?.subQuestion,
                                      lang,
                                    )
                                  : "";
                              const personAdmireOptions =
                                content.type ===
                                OnboardingContentType.PERSON_ADMIRE
                                  ? content.personAdmire?.options || []
                                  : [];

                              return (
                                <SortableItem
                                  key={`${selectedScene.id}-${content.id}`}
                                  id={content.id.toString()}
                                >
                                  <div
                                    className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
                                    style={{
                                      animation: `riseIn 0.45s ease ${
                                        contentIndex * 0.08
                                      }s both`,
                                    }}
                                  >
                                    <div className="flex flex-wrap items-center justify-between gap-3">
                                      <div className="flex flex-wrap items-center gap-3">
                                        <span
                                          className={`rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em] ${
                                            typeBadgeClasses[content.type]
                                          }`}
                                        >
                                          {meta.label}
                                        </span>
                                        <span className="text-xs font-medium text-slate-400">
                                          Content {content.id}
                                        </span>
                                      </div>
                                      <p className="text-xs font-medium text-slate-500">
                                        {meta.description}
                                      </p>
                                    </div>

                                    <div className="mt-3 flex flex-wrap items-center justify-between gap-3 rounded-xl border border-slate-100 bg-slate-50/70 px-4 py-3 text-sm text-slate-600">
                                      {content.type ===
                                      OnboardingContentType.FACT ? (
                                        <div className="space-y-1">
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelSubClass}
                                            >
                                              Title:
                                            </span>
                                            <TextWithTooltip text={factTitle} />
                                          </div>
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelSubClass}
                                            >
                                              Label:
                                            </span>
                                            <TextWithTooltip text={factLabel} />
                                          </div>
                                          {factIcon ? (
                                            <div className="flex items-start gap-2">
                                              <span
                                                className={summaryLabelSubClass}
                                              >
                                                Icon:
                                              </span>
                                              <TextWithTooltip
                                                text={factIcon}
                                              />
                                            </div>
                                          ) : null}
                                        </div>
                                      ) : null}

                                      {content.type ===
                                      OnboardingContentType.ACTIVATION ? (
                                        <div className="space-y-1">
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelMainClass}
                                            >
                                              Activations:
                                            </span>
                                            <TextWithTooltip
                                              text={activationCount.toString()}
                                            />
                                          </div>
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelMainClass}
                                            >
                                              Labels:
                                            </span>
                                            <TextWithTooltip
                                              text={
                                                content.activation?.content.labels?.length?.toString() ||
                                                "0"
                                              }
                                            />
                                          </div>
                                          {content.activation?.content.labels
                                            ?.length ? (
                                            <div className="space-y-1 pl-2">
                                              {content.activation.content.labels.map(
                                                (labelItem) => {
                                                  const labelValue =
                                                    stripHtml(
                                                      getDisplayTranslationValue(
                                                        labelItem.label,
                                                        lang,
                                                      ),
                                                    );
                                                  return (
                                                    <div
                                                      key={labelItem.id}
                                                      className="flex items-start gap-2"
                                                    >
                                                      <span className="text-xs font-semibold text-green-500">
                                                        Label {labelItem.id}:
                                                      </span>
                                                      <TextWithTooltip
                                                        text={labelValue}
                                                        maxLength={60}
                                                      />
                                                    </div>
                                                  );
                                                },
                                              )}
                                            </div>
                                          ) : null}
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelMainClass}
                                            >
                                              Title:
                                            </span>
                                            <TextWithTooltip
                                              text={activationTitle}
                                            />
                                          </div>
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelMainClass}
                                            >
                                              Description:
                                            </span>
                                            <TextWithTooltip
                                              text={activationDescription}
                                              maxLength={80}
                                            />
                                          </div>
                                          {activationIcon ? (
                                            <div className="flex items-start gap-2">
                                              <span
                                                className={
                                                  summaryLabelMainClass
                                                }
                                              >
                                                Icon:
                                              </span>
                                              <TextWithTooltip
                                                text={activationIcon}
                                              />
                                            </div>
                                          ) : null}
                                        </div>
                                      ) : null}

                                      {content.type ===
                                      OnboardingContentType.BRANCH ? (
                                        <div className="space-y-1">
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelMainClass}
                                            >
                                              Sub question:
                                            </span>
                                            <TextWithTooltip
                                              text={branchSubQuestion}
                                            />
                                          </div>
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelMainClass}
                                            >
                                              Question:
                                            </span>
                                            <TextWithTooltip
                                              text={branchQuestion}
                                              maxLength={80}
                                            />
                                          </div>
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelMainClass}
                                            >
                                              Options:
                                            </span>
                                            <TextWithTooltip
                                              text={branchOptions.length.toString()}
                                            />
                                          </div>
                                          {branchOptions.length ? (
                                            <div className="space-y-1">
                                              {branchOptions.map((option) => {
                                                const optionLabel =
                                                  getDisplayTranslationValue(
                                                    option.label,
                                                    lang,
                                                  );
                                                return (
                                                  <div
                                                    key={option.id}
                                                    className="flex flex-col gap-1 px-2 py-1"
                                                  >
                                                    <div className="flex items-start gap-2">
                                                      <span className="text-xs font-semibold text-green-500">
                                                        Option {option.id}:
                                                      </span>
                                                      <TextWithTooltip
                                                        text={optionLabel}
                                                        maxLength={60}
                                                      />
                                                    </div>
                                                    {option.icon ? (
                                                      <div className="flex items-start gap-2">
                                                        <span className="text-xs font-semibold text-green-500">
                                                          Icon:
                                                        </span>
                                                        <TextWithTooltip
                                                          text={option.icon}
                                                          maxLength={60}
                                                        />
                                                      </div>
                                                    ) : null}
                                                    {option.nextSceneId ? (
                                                      <div className="flex items-start gap-2">
                                                        <span className="text-xs font-semibold text-green-500">
                                                          Next scene:
                                                        </span>
                                                        <TextWithTooltip
                                                          text={
                                                            option.nextSceneId
                                                          }
                                                          maxLength={40}
                                                        />
                                                      </div>
                                                    ) : null}
                                                  </div>
                                                );
                                              })}
                                            </div>
                                          ) : null}
                                        </div>
                                      ) : null}

                                      {content.type ===
                                      OnboardingContentType.PERSON_ADMIRE ? (
                                        <div className="space-y-1">
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelMainClass}
                                            >
                                              Sub question:
                                            </span>
                                            <TextWithTooltip
                                              text={personAdmireSubQuestion}
                                            />
                                          </div>
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelMainClass}
                                            >
                                              Question:
                                            </span>
                                            <TextWithTooltip
                                              text={personAdmireQuestion}
                                              maxLength={80}
                                            />
                                          </div>
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelMainClass}
                                            >
                                              Options:
                                            </span>
                                            <TextWithTooltip
                                              text={personAdmireOptions.length.toString()}
                                            />
                                          </div>
                                          {personAdmireOptions.length ? (
                                            <div className="space-y-1">
                                              {personAdmireOptions.map(
                                                (option, optionIndex) => (
                                                  <div
                                                    key={`person-admire-summary-${optionIndex}`}
                                                    className="flex flex-col gap-1 px-2 py-1"
                                                  >
                                                    <div className="flex items-start gap-2">
                                                      <span className="text-xs font-semibold text-green-500">
                                                        Option {optionIndex + 1}:
                                                      </span>
                                                      <TextWithTooltip
                                                        text={option.name}
                                                        maxLength={60}
                                                      />
                                                    </div>
                                                    <div className="flex items-start gap-2">
                                                      <span className="text-xs font-semibold text-green-500">
                                                        Title:
                                                      </span>
                                                      <TextWithTooltip
                                                        text={getDisplayTranslationValue(
                                                          option.title,
                                                          lang,
                                                        )}
                                                        maxLength={60}
                                                      />
                                                    </div>
                                                    <div className="flex items-start gap-2">
                                                      <span className="text-xs font-semibold text-green-500">
                                                        Sub title:
                                                      </span>
                                                      <TextWithTooltip
                                                        text={getDisplayTranslationValue(
                                                          option.subTitle,
                                                          lang,
                                                        )}
                                                        maxLength={60}
                                                      />
                                                    </div>
                                                    {option.image ? (
                                                      <div className="flex items-start gap-2">
                                                        <span className="text-xs font-semibold text-green-500">
                                                          Image:
                                                        </span>
                                                        <TextWithTooltip
                                                          text={option.image}
                                                          maxLength={60}
                                                        />
                                                      </div>
                                                    ) : null}
                                                  </div>
                                                ),
                                              )}
                                            </div>
                                          ) : null}
                                        </div>
                                      ) : null}

                                      {content.type ===
                                      OnboardingContentType.FIXED ? (
                                        <div className="space-y-1">
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelMainClass}
                                            >
                                              Sub question:
                                            </span>
                                            <TextWithTooltip
                                              text={fixedSubQuestion}
                                            />
                                          </div>
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelMainClass}
                                            >
                                              Question:
                                            </span>
                                            <TextWithTooltip
                                              text={fixedQuestion}
                                              maxLength={80}
                                            />
                                          </div>
                                          <div className="flex items-start gap-2">
                                            <span
                                              className={summaryLabelMainClass}
                                            >
                                              Options:
                                            </span>
                                            <TextWithTooltip
                                              text={fixedOptions.length.toString()}
                                            />
                                          </div>
                                          {fixedOptions.length ? (
                                            <div className="space-y-1">
                                              {fixedOptions.map((option) => {
                                                const optionTitle =
                                                  getDisplayTranslationValue(
                                                    option.title,
                                                    lang,
                                                  );
                                                const optionLabel =
                                                  stripHtml(
                                                    getDisplayTranslationValue(
                                                      option.label,
                                                      lang,
                                                    ),
                                                  );
                                                return (
                                                  <div
                                                    key={option.id}
                                                    className="flex flex-col gap-1 px-2 py-1"
                                                  >
                                                    <div className="flex items-start gap-2">
                                                      <span className="text-xs font-semibold text-green-500">
                                                        Option {option.id}:
                                                      </span>
                                                      <TextWithTooltip
                                                        text={optionTitle}
                                                        maxLength={60}
                                                      />
                                                    </div>
                                                    <div className="flex items-start gap-2">
                                                      <span className="text-xs font-semibold text-green-500">
                                                        Label:
                                                      </span>
                                                      <TextWithTooltip
                                                        text={optionLabel}
                                                        maxLength={60}
                                                      />
                                                    </div>
                                                    {option.icon ? (
                                                      <div className="flex items-start gap-2">
                                                        <span className="text-xs font-semibold text-green-500">
                                                          Icon:
                                                        </span>
                                                        <TextWithTooltip
                                                          text={option.icon}
                                                          maxLength={60}
                                                        />
                                                      </div>
                                                    ) : null}
                                                  </div>
                                                );
                                              })}
                                            </div>
                                          ) : null}
                                        </div>
                                      ) : null}

                                      <div className="flex items-center gap-2">
                                        <button
                                          type="button"
                                          onClick={() =>
                                            setContentModal({
                                              sceneId: selectedScene.id,
                                              contentId: content.id,
                                              mode: "edit",
                                            })
                                          }
                                          className={iconButtonClass}
                                          aria-label="Edit content"
                                          title="Edit content"
                                        >
                                          <PencilSquareIcon className="h-4 w-4" />
                                        </button>
                                        <button
                                          type="button"
                                          onClick={() =>
                                            updateScenario((prev) => ({
                                              ...prev,
                                              scenes: prev.scenes.map(
                                                (scene, sIndex) =>
                                                  sIndex === sceneIndex
                                                    ? {
                                                        ...scene,
                                                        contents:
                                                          scene.contents.filter(
                                                            (_, cIndex) =>
                                                              cIndex !==
                                                              contentIndex,
                                                          ),
                                                      }
                                                    : scene,
                                              ),
                                            }))
                                          }
                                          className={iconButtonDangerClass}
                                          aria-label="Remove content"
                                          title="Remove content"
                                        >
                                          <TrashIcon className="h-4 w-4" />
                                        </button>
                                      </div>
                                    </div>
                                  </div>
                                </SortableItem>
                              );
                            },
                          )}
                        </div>
                      </SortableContext>
                    </DndContext>
                    <div className="relative flex justify-center pt-2">
                      <button
                        type="button"
                        onClick={() => {
                          if (!selectedScene) {
                            showError("Vui lòng chọn scene trước.");
                            return;
                          }
                          setIsTypeModalOpen(true);
                        }}
                        className={iconButtonAddClass}
                        aria-label="Add content"
                        title="Add content"
                      >
                        <PlusIcon className="h-4 w-4" />
                      </button>
                    </div>
                  </>
                )}
              </div>
            </section>
          </div>
        </div>
      </div>

      <AnimatePresence>
        {isTypeModalOpen ? (
          <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60">
            <motion.div
              initial={{ opacity: 0, y: 100 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 100 }}
              className="w-full max-w-md rounded-t-2xl bg-white p-6 shadow-xl"
            >
              <h2 className="mb-4 text-xl font-bold">Chọn loại content</h2>
              <div className="grid grid-cols-2 gap-4">
                <button
                  type="button"
                  onClick={() =>
                    handleSelectContentType(OnboardingContentType.FACT)
                  }
                  className="flex flex-col items-center gap-2 rounded-lg bg-blue-50 p-4 transition hover:bg-blue-100"
                >
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100">
                    <span className="font-bold text-blue-600">F</span>
                  </div>
                  <span className="font-medium">Fact</span>
                </button>
                <button
                  type="button"
                  onClick={() =>
                    handleSelectContentType(OnboardingContentType.ACTIVATION)
                  }
                  className="flex flex-col items-center gap-2 rounded-lg bg-emerald-50 p-4 transition hover:bg-emerald-100"
                >
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-emerald-100">
                    <span className="font-bold text-emerald-600">A</span>
                  </div>
                  <span className="font-medium">Activation</span>
                </button>
                <button
                  type="button"
                  onClick={() =>
                    handleSelectContentType(OnboardingContentType.BRANCH)
                  }
                  disabled={selectedSceneHasBranch}
                  title={
                    selectedSceneHasBranch
                      ? "Scene đã có branch"
                      : "Thêm branch"
                  }
                  className={`flex flex-col items-center gap-2 rounded-lg bg-amber-50 p-4 transition hover:bg-amber-100 ${
                    selectedSceneHasBranch
                      ? "cursor-not-allowed opacity-60"
                      : ""
                  }`}
                >
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-amber-100">
                    <span className="font-bold text-amber-600">B</span>
                  </div>
                  <span className="font-medium">Branch</span>
                </button>
                <button
                  type="button"
                  onClick={() =>
                    handleSelectContentType(OnboardingContentType.FIXED)
                  }
                  className="flex flex-col items-center gap-2 rounded-lg bg-sky-50 p-4 transition hover:bg-sky-100"
                >
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-sky-100">
                    <span className="font-bold text-sky-600">Fx</span>
                  </div>
                  <span className="font-medium">Fixed</span>
                </button>
                {selectedScene?.id === rootSceneId ? (
                  <button
                    type="button"
                    onClick={() =>
                      handleSelectContentType(
                        OnboardingContentType.PERSON_ADMIRE,
                      )
                    }
                    className="flex flex-col items-center gap-2 rounded-lg bg-rose-50 p-4 transition hover:bg-rose-100"
                  >
                    <div className="flex h-10 w-10 items-center justify-center rounded-full bg-rose-100">
                      <span className="font-bold text-rose-600">PA</span>
                    </div>
                    <span className="font-medium">Person Admire</span>
                  </button>
                ) : null}
              </div>
              <button
                type="button"
                onClick={() => setIsTypeModalOpen(false)}
                className="mt-6 w-full rounded-lg bg-gray-200 py-3 text-gray-700 transition hover:bg-gray-300"
              >
                Cancel
              </button>
            </motion.div>
          </div>
        ) : null}
      </AnimatePresence>

      <ConfirmDialog
        open={!!confirmDialog}
        title={
          confirmDialog?.type === "deleteScene"
            ? "Xoá scene"
            : "Đặt scene làm Entry"
        }
        message={
          confirmDialog?.type === "deleteScene"
            ? "Bạn có chắc muốn xoá scene này? Hành động này không thể hoàn tác."
            : "Bạn có chắc muốn đặt scene này làm Entry? Thao tác này sẽ làm thay đổi cấu trúc của toàn bộ dữ liệu."
        }
        messageClassName={
          confirmDialog?.type === "setEntry" ? "text-amber-600" : undefined
        }
        confirmLabel={
          confirmDialog?.type === "deleteScene" ? "Xoá" : "Đặt Entry"
        }
        confirmTone={
          confirmDialog?.type === "deleteScene" ? "danger" : "primary"
        }
        onCancel={() => setConfirmDialog(null)}
        onConfirm={() => {
          void handleConfirmAction();
        }}
      />

      <AnimatePresence>
        {activeContentData ? (
          <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 px-4 py-6">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="flex w-full max-w-4xl flex-col rounded-2xl bg-white shadow-xl"
              style={{ maxHeight: "90vh" }}
              role="dialog"
              aria-modal="true"
            >
              <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-200 px-6 py-4">
                <div className="flex flex-wrap items-center gap-3">
                  <span
                    className={`rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em] ${
                      typeBadgeClasses[activeContentData.content.type]
                    }`}
                  >
                    {typeMeta[activeContentData.content.type].label}
                  </span>
                  <p className="text-sm font-semibold text-slate-900">
                    Content {activeContentData.content.id}
                  </p>
                  <span className="text-xs font-medium text-slate-400">
                    Scene {activeContentData.sceneId}
                  </span>
                </div>
                <button
                  type="button"
                  onClick={closeContentModal}
                  className="rounded-full border border-slate-200 bg-white p-2 text-slate-500 transition hover:border-slate-300 hover:text-slate-700"
                  aria-label="Close"
                >
                  <XMarkIcon className="h-5 w-5" />
                </button>
              </div>
              <div className="flex-grow overflow-y-auto p-6">
                {renderContentEditor(
                  activeContentData.content,
                  activeContentData.sceneIndex,
                  activeContentData.contentIndex,
                )}
              </div>
              <div className="flex flex-wrap items-center justify-end gap-3 border-t border-slate-200 px-6 py-4">
                <button
                  type="button"
                  onClick={closeContentModal}
                  className="rounded-full border border-slate-200 bg-white px-4 py-2 text-xs font-semibold uppercase tracking-[0.2em] text-slate-600"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={handleSubmitContentModal}
                  disabled={isSaving}
                  className="rounded-full border border-blue-600 bg-blue-600 px-5 py-2 text-xs font-semibold uppercase tracking-[0.2em] text-white shadow-sm transition hover:bg-blue-700 disabled:opacity-50"
                >
                  {contentModal?.mode === "create" ? "Create" : "Update"}
                </button>
              </div>
            </motion.div>
          </div>
        ) : null}
      </AnimatePresence>
    </div>
  );
}
