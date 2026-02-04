import {
  Container,
  Paper,
  Typography,
  Button,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  IconButton,
  Box,
  CircularProgress,
} from "@mui/material";
import { Edit, Delete, Add, Save, Close } from "@mui/icons-material";
import {
  ILablel,
  LangCode,
  IMotivation,
  LablelPayload,
} from "../../types/enum/common.enum";
import {
  IOnboardingIntro,
  IOnboarding,
  OnboardingPayload,
  OnboardingIntroPayload,
} from "../../types/interface/onboarding.interface";
import type { ITranslation } from "../../utils/translation";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { onboardingService } from "../../services/onboardingService";
import { useCallback, useEffect, useState } from "react";
import { useNotification } from "../../utils/hooks/useNotification";
import CloudflareFileUpload from "../../components/files/CloudflareFileUpload";
import CloudflareAssetPreview from "../../components/files/CloudflareAssetPreview";
import {
  getTranslationValue,
  getCurrentTranslationValue,
  updateTranslationValue,
  cleanTranslation,
} from "../../utils/translation";
import DOMPurify from "dompurify";
import { EditorContent, useEditor } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import Underline from "@tiptap/extension-underline";
import TextStyle from "@tiptap/extension-text-style";
import Color from "@tiptap/extension-color";
import { Extension } from "@tiptap/core";

type MotivationField =
  | "welcome"
  | "motivationOne"
  | "motivationTwo"
  | "motivationThree"
  | "loading";

type OnboardingArrayField =
  | "intro"
  | "age"
  | "gender"
  | "skillsetWantToMaster"
  | "learningGoal"
  | "learningStruggles"
  | "comfortableLearningTime"
  | "dailyLearningGoal";

const sanitizeTranslation = (
  translation: ITranslation | undefined,
): ITranslation => {
  const sanitized: ITranslation = {};

  Object.entries(translation || {}).forEach(([key, value]) => {
    if (value !== undefined) {
      sanitized[key as LangCode] = sanitizeHtml(value);
    }
  });

  return sanitized;
};

const sanitizeHtml = (html: string) =>
  DOMPurify.sanitize(html, {
    ADD_ATTR: ["style"],
  });

const ICON_ASSET_REGEX = /\.(png|jpe?g|gif|webp|svg|json|lottie)(\?|#|$)/i;

const isIconAsset = (value: string) =>
  value.startsWith("http") ||
  value.startsWith("data:") ||
  value.startsWith("blob:") ||
  value.startsWith("/") ||
  ICON_ASSET_REGEX.test(value);

const FontSize = Extension.create({
  name: "fontSize",
  addGlobalAttributes() {
    return [
      {
        types: ["textStyle"],
        attributes: {
          fontSize: {
            default: null,
            parseHTML: (element) => element.style.fontSize || null,
            renderHTML: (attributes) => {
              if (!attributes.fontSize) {
                return {};
              }
              return {
                style: `font-size: ${attributes.fontSize}`,
              };
            },
          },
        },
      },
    ];
  },
  addCommands() {
    return {
      setFontSize:
        (size: string) =>
        ({ chain }: { chain: any }) =>
          chain().setMark("textStyle", { fontSize: size }).run(),
      unsetFontSize:
        () =>
        ({ chain }: { chain: any }) =>
          chain().setMark("textStyle", { fontSize: null }).run(),
    };
  },
});

const TiptapEditor: React.FC<{
  value: string;
  onChange: (html: string) => void;
}> = ({ value, onChange }) => {
  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        heading: { levels: [3, 4] },
      }),
      Underline,
      TextStyle,
      Color.configure({ types: ["textStyle"] }),
      FontSize,
    ],
    content: value || "",
    editorProps: {
      attributes: {
        style:
          "min-height: 160px; padding: 12px; border: 1px solid #d0d7de; border-radius: 6px; background: white; outline: none;",
      },
    },
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML());
    },
  });

  useEffect(() => {
    if (!editor) return;
    const current = editor.getHTML();
    if (value !== current) {
      editor.commands.setContent(value || "", false);
    }
  }, [editor, value]);

  const [currentFontSize, setCurrentFontSize] = useState<string>("");

  useEffect(() => {
    if (!editor) return;
    const update = () => {
      const size = editor.getAttributes("textStyle").fontSize || "";
      setCurrentFontSize(size);
    };
    editor.on("selectionUpdate", update);
    editor.on("transaction", update);
    update();
    return () => {
      editor.off("selectionUpdate", update);
      editor.off("transaction", update);
    };
  }, [editor]);

  if (!editor) return null;

  const applyColor = (color: string) =>
    editor.chain().focus().setColor(color).run();
  const applyHighlight = (color: string) =>
    editor
      .chain()
      .focus()
      .setMark("textStyle", { backgroundColor: color })
      .run();
  const clearFormat = () =>
    editor.chain().focus().unsetAllMarks().clearNodes().run();

  const buttonProps = { size: "small" as const };

  return (
    <Box>
      <Box
        sx={{
          mb: 1,
          display: "flex",
          gap: 1,
          alignItems: "center",
          flexWrap: "wrap",
          border: "1px solid",
          borderColor: "grey.200",
          borderRadius: 1,
          p: 0.75,
          bgcolor: "white",
        }}
      >
        <Button
          {...buttonProps}
          onClick={() => editor.chain().focus().toggleBold().run()}
        >
          Bold
        </Button>
        <Button
          {...buttonProps}
          onClick={() => editor.chain().focus().toggleItalic().run()}
        >
          Italic
        </Button>
        <Button
          {...buttonProps}
          onClick={() => editor.chain().focus().toggleUnderline().run()}
        >
          Underline
        </Button>
        <Button
          {...buttonProps}
          onClick={() => editor.chain().focus().toggleStrike().run()}
        >
          Strike
        </Button>
        <Button
          {...buttonProps}
          onClick={() => editor.chain().focus().toggleBulletList().run()}
        >
          • List
        </Button>
        <Button
          {...buttonProps}
          onClick={() => editor.chain().focus().toggleOrderedList().run()}
        >
          1. List
        </Button>
        <Button
          {...buttonProps}
          onClick={() =>
            editor.chain().focus().toggleHeading({ level: 3 }).run()
          }
        >
          H3
        </Button>
        <Button
          {...buttonProps}
          onClick={() =>
            editor.chain().focus().toggleHeading({ level: 4 }).run()
          }
        >
          H4
        </Button>
        <Box sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
          <Typography variant="caption" color="text.secondary">
            Màu chữ
          </Typography>
          <input
            type="color"
            aria-label="Text color"
            onChange={(e) => applyColor(e.target.value)}
            style={{
              height: 28,
              width: 36,
              border: "none",
              background: "transparent",
              cursor: "pointer",
            }}
          />
        </Box>
        <Box sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
          <Typography variant="caption" color="text.secondary">
            Nền
          </Typography>
          <input
            type="color"
            aria-label="Highlight color"
            onChange={(e) => applyHighlight(e.target.value)}
            style={{
              height: 28,
              width: 36,
              border: "none",
              background: "transparent",
              cursor: "pointer",
            }}
          />
        </Box>
        <Box sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
          <Typography variant="caption" color="text.secondary">
            Cỡ chữ
          </Typography>
          <select
            value={currentFontSize || ""}
            onChange={(e) =>
              e.target.value
                ? editor.commands.setFontSize(e.target.value)
                : editor.commands.unsetFontSize()
            }
            style={{
              height: 30,
              borderRadius: 4,
              border: "1px solid #ccc",
              padding: "4px 6px",
              fontSize: 12,
            }}
          >
            <option value="">Default</option>
            <option value="14px">14</option>
            <option value="16px">16</option>
            <option value="18px">18</option>
            <option value="20px">20</option>
            <option value="24px">24</option>
            <option value="28px">28</option>
            <option value="32px">32</option>
          </select>
        </Box>
        <Button {...buttonProps} onClick={clearFormat}>
          Clear
        </Button>
      </Box>
      <EditorContent editor={editor} />
    </Box>
  );
};

const IntroInput: React.FC<{
  item: IOnboardingIntro;
  onChange: (id: number, newIntro: IOnboardingIntro) => void;
  onDelete: (id: number) => void;
  onAdd: (id: number) => void;
  lang: LangCode;
}> = ({ item, onChange, onDelete, onAdd, lang }) => {
  const handleImageChange = useCallback(
    (newUrl: string) => {
      // Gọi onChange với ID của item hiện tại
      onChange(item.id, { ...item, image: newUrl });
    },
    [item.id, onChange],
  );

  return (
    <Box
      sx={{
        display: "flex",
        flexDirection: "column",
        mb: 3,
        p: 2,
        borderRadius: 1,
        bgcolor: "grey.100",
        boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
        transition: "all 0.3s ease",
        "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
      }}
    >
      <Box sx={{ display: "flex", alignItems: "center", mb: 2 }}>
        <Box sx={{ mr: 2, flex: 1 }}>
          <TextField
            label="Title"
            value={getCurrentTranslationValue(item.title, lang)}
            onChange={(e) =>
              onChange(item.id, {
                ...item,
                title: updateTranslationValue(item.title, lang, e.target.value),
              })
            }
            fullWidth
            size="small"
            variant="outlined"
          />
        </Box>
        <Box sx={{ display: "flex" }}>
          <IconButton
            onClick={() => onDelete(item.id)}
            color="error"
            size="small"
          >
            <Delete />
          </IconButton>
          <IconButton
            onClick={() => onAdd(item.id)}
            color="primary"
            size="small"
          >
            <Add />
          </IconButton>
        </Box>
      </Box>

      <Box sx={{ mb: 2 }}>
        <TextField
          label="Source"
          value={item.source || ""}
          onChange={(e) =>
            onChange(item.id, {
              ...item,
              source: e.target.value,
            })
          }
          fullWidth
          size="small"
          variant="outlined"
        />
      </Box>

      <Box sx={{ mb: 2 }}>
        <TextField
          label="Source Title"
          value={item.sourceTitle || ""}
          onChange={(e) =>
            onChange(item.id, {
              ...item,
              sourceTitle: e.target.value,
            })
          }
          fullWidth
          size="small"
          variant="outlined"
        />
      </Box>

      <Box sx={{ display: "flex", alignItems: "center", mb: 2 }}>
        <Box sx={{ mr: 2 }}>
          <CloudflareFileUpload
            initialUrl={item.image || ""}
            onUrlChange={handleImageChange}
            label="Image URL"
            uploadPayload={{
              prefix: "",
              folder: "onboarding",
            }}
          />
        </Box>
      </Box>

      <Box sx={{ display: "flex", alignItems: "center" }}>
        <Box sx={{ flex: 1 }}>
          <Typography variant="caption" sx={{ mb: 0.5, display: "block" }}>
            Content (rich text + màu)
          </Typography>
          <TiptapEditor
            value={getCurrentTranslationValue(item.content, lang)}
            onChange={(html) =>
              onChange(item.id, {
                ...item,
                content: updateTranslationValue(item.content, lang, html),
              })
            }
          />
          {getCurrentTranslationValue(item.content, lang).trim() !== "" && (
            <Box
              sx={{
                mt: 1.5,
                p: 1.5,
                borderRadius: 1,
                bgcolor: "grey.50",
                border: "1px solid",
                borderColor: "grey.200",
              }}
              dangerouslySetInnerHTML={{
                __html: DOMPurify.sanitize(
                  getCurrentTranslationValue(item.content, lang),
                ),
              }}
            />
          )}
        </Box>
      </Box>
    </Box>
  );
};

const LabelInput: React.FC<{
  item: ILablel;
  onChange: (id: number, newLabel: ILablel) => void;
  onDelete: (id: number) => void;
  onAdd: (id: number) => void;
  lang: LangCode;
  showTitle?: boolean;
}> = ({ item, onChange, onDelete, onAdd, lang, showTitle = false }) => (
  <Box
    sx={{
      display: "flex",
      flexDirection: "column",
      mb: 3,
      p: 2,
      borderRadius: 1,
      bgcolor: "grey.100",
      boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
      transition: "all 0.3s ease",
      "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
    }}
  >
    <Box sx={{ display: "flex", alignItems: "center", mb: 2 }}>
      <Box sx={{ mr: 2, minWidth: 120 }}>
        <CloudflareFileUpload
          initialUrl={item.icon || ""}
          onUrlChange={(newUrl) => onChange(item.id, { ...item, icon: newUrl })}
          label="Icon"
          uploadPayload={{ prefix: "", folder: "onboarding" }}
        />
      </Box>
      <Box sx={{ display: "flex" }}>
        <IconButton
          onClick={() => onDelete(item.id)}
          color="error"
          size="small"
        >
          <Delete />
        </IconButton>
        <IconButton onClick={() => onAdd(item.id)} color="primary" size="small">
          <Add />
        </IconButton>
      </Box>
    </Box>

    {showTitle && (
      <Box sx={{ display: "flex", alignItems: "center", mb: 2 }}>
        <Box sx={{ flex: 1 }}>
          <TextField
            label="Title"
            value={getCurrentTranslationValue(item.title, lang)}
            onChange={(e) =>
              onChange(item.id, {
                ...item,
                title: updateTranslationValue(item.title, lang, e.target.value),
              })
            }
            fullWidth
            size="small"
            variant="outlined"
          />
        </Box>
      </Box>
    )}

    <Box sx={{ display: "flex", alignItems: "center", mb: 2 }}>
      <Box sx={{ flex: 1 }}>
        <TextField
          label="Label"
          value={getCurrentTranslationValue(item.label, lang)}
          onChange={(e) =>
            onChange(item.id, {
              ...item,
              label: updateTranslationValue(item.label, lang, e.target.value),
            })
          }
          fullWidth
          size="small"
          variant="outlined"
        />
      </Box>
    </Box>
    <Box sx={{ display: "flex", alignItems: "center", mb: 2 }}>
      <Box sx={{ flex: 1 }}>
        <TextField
          label="Tracking Label"
          value={item.trackingLabel || ""}
          onChange={(e) =>
            onChange(item.id, {
              ...item,
              trackingLabel: e.target.value,
            })
          }
          fullWidth
          size="small"
          variant="outlined"
        />
      </Box>
    </Box>
  </Box>
);

const MotivationInput: React.FC<{
  item: IMotivation;
  onChange: (value: IMotivation) => void;
  lang: LangCode;
  title: string;
}> = ({ item, onChange, lang, title }) => {
  const handleImageChange = useCallback(
    (newUrl: string) => {
      onChange({ ...item, image: newUrl });
    },
    [item, onChange],
  );

  return (
    <Box
      sx={{
        display: "flex",
        flexDirection: "column",
        mb: 3,
        p: 2,
        borderRadius: 1,
        bgcolor: "grey.100",
        boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
        transition: "all 0.3s ease",
        "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
      }}
    >
      <Typography variant="subtitle1" sx={{ mb: 2, fontWeight: "bold" }}>
        {title}
      </Typography>
      <Box sx={{ display: "flex", alignItems: "center", mb: 2 }}>
        <CloudflareFileUpload
          initialUrl={item.image || ""}
          onUrlChange={handleImageChange}
          label="Image"
          uploadPayload={{ prefix: "", folder: "onboarding" }}
        />
      </Box>
      <TextField
        label="Content"
        value={getCurrentTranslationValue(item.content, lang)}
        onChange={(e) =>
          onChange({
            ...item,
            content: updateTranslationValue(
              item.content as ITranslation,
              lang,
              e.target.value,
            ),
          })
        }
        fullWidth
        multiline
        rows={3}
        size="small"
        variant="outlined"
      />
    </Box>
  );
};

// --- Component Cha: OnboardingManagement ---
const OnboardingManagement: React.FC = () => {
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showSuccess, showError } = useNotification();

  const [onboarding, setOnboarding] = useState<IOnboarding | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState<boolean>(false);
  const [activeTab, setActiveTab] = useState<string>("intro");
  const [loading, setLoading] = useState<boolean>(false);

  const [nextIds, setNextIds] = useState({
    intro: 1,
    age: 1,
    gender: 1,
    skillsetWantToMaster: 1,
    learningGoal: 1,
    learningStruggles: 1,
    comfortableLearningTime: 1,
    dailyLearningGoal: 1,
  });

  const createNewIntro = (): IOnboardingIntro => {
    const newId = nextIds.intro;
    setNextIds((prev) => ({ ...prev, intro: newId + 1 }));
    return {
      id: newId,
      title: { [lang]: "" },
      image: "",
      content: { [lang]: "" },
      source: "",
      sourceTitle: "",
    };
  };

  const createNewLabel = (field: OnboardingArrayField): ILablel => {
    const newId = nextIds[field as keyof typeof nextIds];
    setNextIds((prev) => ({ ...prev, [field]: newId + 1 }));
    return {
      id: newId,
      icon: "",
      title: { [lang]: "" },
      label: { [lang]: "" },
      trackingLabel: "",
    };
  };

  const calculateNextIds = (data: IOnboarding) => {
    const fields: OnboardingArrayField[] = [
      "intro",
      "age",
      "gender",
      "skillsetWantToMaster",
      "learningGoal",
      "learningStruggles",
      "comfortableLearningTime",
      "dailyLearningGoal",
    ];

    const newIds = { ...nextIds };

    fields.forEach((field) => {
      if (Array.isArray(data[field]) && data[field].length > 0) {
        const maxId = Math.max(
          ...(data[field] as any[]).map((item) => item.id),
        );
        newIds[field as keyof typeof newIds] = maxId + 1;
      }
    });

    setNextIds(newIds);
  };

  useEffect(() => {
    const fetchOnboarding = async () => {
      setLoading(true);
      try {
        const res = await onboardingService.getOne();
        setOnboarding(res.data);
        calculateNextIds(res.data);
      } catch (err) {
        showError("Failed to fetch onboarding data");
      } finally {
        setLoading(false);
      }
    };

    fetchOnboarding();
  }, []); // ĐÃ SỬA: Chỉ chạy 1 lần

  const buildIntroPayload = (
    list: IOnboardingIntro[],
  ): OnboardingIntroPayload[] =>
    list.map((intro) => {
      const cleanedTitle = sanitizeTranslation(
        cleanTranslation(intro.title) || intro.title,
      );
      const cleanedContent = sanitizeTranslation(
        cleanTranslation(intro.content) || intro.content,
      );

      return {
        id: intro.id,
        image: intro.image,
        title: cleanedTitle || {},
        content: cleanedContent || {},
        source: intro.source || "",
        sourceTitle: intro.sourceTitle || "",
      } as OnboardingIntroPayload;
    });

  const buildLabelPayload = (
    list: ILablel[],
    requireTitle: boolean = false,
  ): LablelPayload[] =>
    list.map((l) => {
      const cleanedLabel = sanitizeTranslation(
        cleanTranslation(l.label) || l.label,
      );
      const cleanedTitle = sanitizeTranslation(
        cleanTranslation(l.title) || l.title,
      );

      const payload: Partial<LablelPayload> = {
        id: l.id,
        icon: l.icon,
        label: cleanedLabel || {},
        trackingLabel: l.trackingLabel || "",
      };

      if (requireTitle) {
        payload.title = cleanedTitle || {};
      }

      return payload as LablelPayload;
    });

  const buildMotivationPayload = (
    motivation: IMotivation | undefined,
  ): IMotivation => {
    const cleanedContent = cleanTranslation(motivation?.content);

    return {
      image: motivation?.image || "",
      content: (cleanedContent || {}) as ITranslation,
    };
  };

  const handleEdit = (tab: string): void => {
    setActiveTab(tab);
    setIsDialogOpen(true);
  };

  const handleSave = async (): Promise<void> => {
    if (!onboarding) return;

    setLoading(true);
    try {
      const payload: OnboardingPayload = {
        intro: buildIntroPayload(onboarding.intro || []),
        age: buildLabelPayload(onboarding.age || [], false),
        gender: buildLabelPayload(onboarding.gender || [], false),
        skillsetWantToMaster: buildLabelPayload(
          onboarding.skillsetWantToMaster || [],
          false,
        ),
        learningGoal: buildLabelPayload(onboarding.learningGoal || [], false),
        learningStruggles: buildLabelPayload(
          onboarding.learningStruggles || [],
          false,
        ),
        comfortableLearningTime: buildLabelPayload(
          onboarding.comfortableLearningTime || [],
          true,
        ),
        dailyLearningGoal: buildLabelPayload(
          onboarding.dailyLearningGoal || [],
          false,
        ),
        welcome: buildMotivationPayload(onboarding.welcome),
        motivationOne: buildMotivationPayload(onboarding.motivationOne),
        motivationTwo: buildMotivationPayload(onboarding.motivationTwo),
        motivationThree: buildMotivationPayload(onboarding.motivationThree),
        loading: buildMotivationPayload(onboarding.loading),
      };

      await onboardingService.update(onboarding._id, payload);
      setIsDialogOpen(false);
      showSuccess("Saved onboarding successfully");
    } catch (err) {
      console.error("Update error:", err);
      showError("Failed to save onboarding");
    } finally {
      setLoading(false);
    }
  };

  // ĐÃ SỬA: Nhận `id` thay vì `index`
  const handleArrayChange = useCallback(
    (field: OnboardingArrayField, id: number, value: any): void => {
      if (!onboarding) return;
      const currentValue = onboarding[field] as any[];
      // Tìm index bằng id
      const index = currentValue.findIndex((item) => item.id === id);
      if (index === -1) return;

      const newArray = [...currentValue];
      newArray[index] = value;
      setOnboarding({ ...onboarding, [field]: newArray });
    },
    [onboarding],
  );

  const updateMotivationField = useCallback(
    (field: MotivationField, value: IMotivation) => {
      setOnboarding((prev) => (prev ? { ...prev, [field]: value } : prev));
    },
    [],
  );

  const getMotivationValue = (field: MotivationField): IMotivation =>
    onboarding?.[field] || { image: "", content: {} };

  const addToArray = (field: OnboardingArrayField): void => {
    if (!onboarding) return;

    if (field === "intro") {
      const newIntro = createNewIntro();
      const newArray = [...(onboarding[field] as IOnboardingIntro[]), newIntro];
      setOnboarding({ ...onboarding, [field]: newArray });
    } else {
      const newLabel = createNewLabel(field);
      const newArray = [...(onboarding[field] as ILablel[]), newLabel];
      setOnboarding({ ...onboarding, [field]: newArray });
    }
  };

  // ĐÃ SỬA: Nhận `id` thay vì `index`
  const addToArrayAtIndex = (field: OnboardingArrayField, id: number): void => {
    if (!onboarding) return;
    const currentValue = onboarding[field] as any[];
    // Tìm index bằng id
    const index = currentValue.findIndex((item) => item.id === id);
    if (index === -1) return;

    if (field === "intro") {
      const newIntro = createNewIntro();
      const newArray = [...currentValue];
      newArray.splice(index + 1, 0, newIntro);
      setOnboarding({ ...onboarding, [field]: newArray });
    } else {
      const newLabel = createNewLabel(field);
      const newArray = [...currentValue];
      newArray.splice(index + 1, 0, newLabel);
      setOnboarding({ ...onboarding, [field]: newArray });
    }
  };

  // ĐÃ SỬA: Nhận `id` thay vì `index`
  const removeFromArray = (field: OnboardingArrayField, id: number): void => {
    if (!onboarding) return;
    const currentValue = onboarding[field] as any[];
    // Tìm index bằng id
    const index = currentValue.findIndex((item) => item.id === id);
    if (index === -1) return;

    const newArray = [...currentValue];
    newArray.splice(index, 1);
    setOnboarding({ ...onboarding, [field]: newArray });
  };

  const renderIntroTab = (): React.ReactNode => (
    <Box sx={{ mb: 3 }}>
      <Typography variant="h6" sx={{ mb: 2 }}>
        Introduction Steps
      </Typography>
      <Box sx={{ mt: 2 }}>
        {onboarding?.intro.map((intro) => (
          <IntroInput
            // Nếu ID của bạn không duy nhất, hãy dùng key={`${intro.id}-${index}`
            key={intro.id}
            item={intro}
            onChange={(id, newIntro) =>
              handleArrayChange("intro", id, newIntro)
            }
            onDelete={(id) => removeFromArray("intro", id)}
            onAdd={(id) => addToArrayAtIndex("intro", id)}
            lang={lang}
          />
        ))}
        <Button
          onClick={() => addToArray("intro")}
          variant="outlined"
          startIcon={<Add />}
          sx={{ mt: 1 }}
        >
          Add Intro Step
        </Button>
      </Box>
    </Box>
  );

  const renderDailyGoalTab = (): React.ReactNode => (
    <Box sx={{ mb: 3 }}>
      <Typography variant="h6" sx={{ mb: 2 }}>
        Daily Learning Goal
      </Typography>
      <Box sx={{ mt: 2 }}>
        {Array.isArray(onboarding?.dailyLearningGoal) &&
          (onboarding?.dailyLearningGoal as ILablel[]).map((item: ILablel) => (
            <LabelInput
              key={item.id}
              item={item}
              onChange={(id, newLabel) =>
                handleArrayChange("dailyLearningGoal", id, newLabel)
              }
              onDelete={(id) => removeFromArray("dailyLearningGoal", id)}
              onAdd={(id) => addToArrayAtIndex("dailyLearningGoal", id)}
              lang={lang}
            />
          ))}
        <Button
          onClick={() => addToArray("dailyLearningGoal")}
          variant="outlined"
          startIcon={<Add />}
          sx={{ mt: 1 }}
        >
          Add Daily Goal
        </Button>
      </Box>
    </Box>
  );

  const renderLabelsTab = (
    field: OnboardingArrayField,
    title: string,
    showTitle?: boolean,
  ): React.ReactNode => (
    <Box sx={{ mb: 3 }}>
      <Typography variant="h6" sx={{ mb: 2 }}>
        {title}
      </Typography>
      <Box sx={{ mt: 2 }}>
        {Array.isArray(onboarding?.[field]) &&
          (onboarding?.[field] as ILablel[]).map((item: ILablel) => (
            <LabelInput
              key={item.id}
              item={item}
              onChange={(id, newLabel) =>
                handleArrayChange(field, id, newLabel)
              }
              onDelete={(id) => removeFromArray(field, id)}
              onAdd={(id) => addToArrayAtIndex(field, id)}
              lang={lang}
              showTitle={showTitle}
            />
          ))}
        <Button
          onClick={() => addToArray(field)}
          variant="outlined"
          startIcon={<Add />}
          sx={{ mt: 1 }}
        >
          Add {title}
        </Button>
      </Box>
    </Box>
  );

  const renderMotivationTab = (
    field: MotivationField,
    title: string,
  ): React.ReactNode => (
    <MotivationInput
      item={getMotivationValue(field)}
      onChange={(value) => updateMotivationField(field, value)}
      lang={lang}
      title={title}
    />
  );

  const renderChipWithIcon = (item: ILablel) => {
    const shouldRenderIcon = item.icon && isIconAsset(item.icon);

    if (shouldRenderIcon) {
      return (
        <Box
          key={item.id}
          sx={{
            display: "flex",
            alignItems: "center",
            mb: 2,
            p: 1,
            borderRadius: 1,
            bgcolor: "white",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
            transition: "all 0.3s ease",
            "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
          }}
        >
          <CloudflareAssetPreview
            src={item.icon}
            alt={getCurrentTranslationValue(item.label, lang)}
            style={{
              width: 32,
              height: 32,
              objectFit: "contain",
              marginRight: 8,
              display: "block",
            }}
          />
          <Typography variant="body1" sx={{ fontWeight: "medium" }}>
            {getCurrentTranslationValue(item.label, lang)}
          </Typography>
        </Box>
      );
    }

    return (
      <Box
        key={item.id}
        sx={{
          display: "flex",
          alignItems: "center",
          mb: 2,
          p: 1,
          borderRadius: 1,
          bgcolor: "white",
          boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          transition: "all 0.3s ease",
          "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
        }}
      >
        <Typography variant="body1" sx={{ mr: 1 }}>
          {item.icon}
        </Typography>
        <Typography variant="body1" sx={{ fontWeight: "medium" }}>
          {getCurrentTranslationValue(item.label, lang)}
        </Typography>
      </Box>
    );
  };

  const renderMotivationSection = (
    field: MotivationField,
    title: string,
  ): React.ReactNode => {
    const motivation = getMotivationValue(field);

    return (
      <Box
        sx={{
          mb: 6,
          p: 3,
          borderRadius: 2,
          bgcolor: "grey.50",
          boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
          transition: "all 0.3s ease",
          "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
        }}
      >
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            mb: 2,
          }}
        >
          <Typography variant="h5" sx={{ fontWeight: "bold" }}>
            {title}
          </Typography>
          <Button
            variant="outlined"
            startIcon={<Edit />}
            onClick={() => handleEdit(field)}
            sx={{
              transition: "all 0.3s ease",
              "&:hover": { bgcolor: "primary.main", color: "white" },
            }}
          >
            Edit
          </Button>
        </Box>
        <Box sx={{ display: "flex", gap: 3, alignItems: "center" }}>
          {motivation.image && (
            <CloudflareAssetPreview
              src={motivation.image}
              alt={title}
              style={{
                width: 160,
                height: 160,
                objectFit: "cover",
                borderRadius: 8,
                boxShadow: "0 2px 6px rgba(0,0,0,0.1)",
                overflow: "hidden",
              }}
              errorText={`Không thể hiển thị preview cho ${title}`}
            />
          )}
          <Typography sx={{ lineHeight: 1.6, whiteSpace: "pre-wrap" }}>
            {getTranslationValue(motivation.content, lang)}
          </Typography>
        </Box>
      </Box>
    );
  };

  const renderChipWithIconAndTitle = (item: ILablel) => {
    const shouldRenderIcon = item.icon && isIconAsset(item.icon);

    if (shouldRenderIcon) {
      return (
        <Box
          key={item.id}
          sx={{
            display: "flex",
            alignItems: "center",
            mb: 2,
            p: 1,
            borderRadius: 1,
            bgcolor: "white",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
            transition: "all 0.3s ease",
            "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
          }}
        >
          <CloudflareAssetPreview
            src={item.icon}
            alt={getCurrentTranslationValue(item.label, lang)}
            style={{
              width: 32,
              height: 32,
              objectFit: "contain",
              marginRight: 8,
              display: "block",
            }}
          />
          {getCurrentTranslationValue(item.title, lang) && (
            <Typography variant="body1" sx={{ mr: 1, fontWeight: "medium" }}>
              {getCurrentTranslationValue(item.title, lang)}
            </Typography>
          )}
          <Typography variant="body1" sx={{ fontWeight: "medium" }}>
            {getCurrentTranslationValue(item.label, lang)}
          </Typography>
        </Box>
      );
    }

    return (
      <Box
        key={item.id}
        sx={{
          display: "flex",
          alignItems: "center",
          mb: 2,
          p: 1,
          borderRadius: 1,
          bgcolor: "white",
          boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          transition: "all 0.3s ease",
          "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
        }}
      >
        <Typography variant="body1" sx={{ mr: 1 }}>
          {item.icon}
        </Typography>
        {getCurrentTranslationValue(item.title, lang) && (
          <Typography variant="body1" sx={{ mr: 1, fontWeight: "medium" }}>
            {getCurrentTranslationValue(item.title, lang)}
          </Typography>
        )}
        <Typography variant="body1" sx={{ fontWeight: "medium" }}>
          {getCurrentTranslationValue(item.label, lang)}
        </Typography>
      </Box>
    );
  };

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Paper
        sx={{
          p: 3,
          boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
          transition: "all 0.3s ease",
          "&:hover": { boxShadow: "0 6px 16px rgba(0,0,0,0.15)" },
        }}
      >
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            mb: 4,
          }}
        >
          <Typography variant="h4" sx={{ fontWeight: "bold" }}>
            Onboarding Management
          </Typography>
        </Box>

        {loading ? (
          <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
            <CircularProgress />
          </Box>
        ) : onboarding ? (
          <Box>
            {/* Intro Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Introduction Steps
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("intro")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 3 }}>
                {onboarding.intro.map((intro) => (
                  <Box
                    key={intro.id}
                    sx={{
                      p: 3,
                      borderRadius: 2,
                      bgcolor: "white",
                      boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
                      transition: "all 0.3s ease",
                      "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
                    }}
                  >
                    <Box sx={{ display: "flex", gap: 3 }}>
                      <Box sx={{ flex: 1 }}>
                        {intro.image && (
                          <CloudflareAssetPreview
                            src={intro.image}
                            alt={getCurrentTranslationValue(intro.title, lang)}
                            style={{
                              width: "100%",
                              height: 200,
                              objectFit: "cover",
                              borderRadius: 4,
                              overflow: "hidden",
                            }}
                            errorText="Không thể hiển thị preview cho intro này"
                          />
                        )}
                      </Box>
                      <Box sx={{ flex: 2 }}>
                        <Typography gutterBottom sx={{ fontWeight: "bold" }}>
                          {getCurrentTranslationValue(intro.title, lang)}
                        </Typography>
                        {intro.sourceTitle && (
                          <Typography
                            variant="subtitle2"
                            color="text.secondary"
                            sx={{ display: "block", mb: 0.5 }}
                          >
                            {intro.sourceTitle}
                          </Typography>
                        )}
                        {intro.source && (
                          <Typography
                            variant="caption"
                            color="text.secondary"
                            sx={{ display: "block", mb: 1 }}
                          >
                            {intro.source}
                          </Typography>
                        )}
                        <Box
                          sx={{ lineHeight: 1.6 }}
                          dangerouslySetInnerHTML={{
                            __html: DOMPurify.sanitize(
                              getCurrentTranslationValue(intro.content, lang),
                            ),
                          }}
                        />
                      </Box>
                    </Box>
                  </Box>
                ))}
              </Box>
            </Box>

            {/* Age Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Age Options
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("age")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.age.map((item) => renderChipWithIcon(item))}
              </Box>
            </Box>

            {/* Gender Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Gender Options
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("gender")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.gender.map((item) => renderChipWithIcon(item))}
              </Box>
            </Box>

            {/* Topics Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Skillset to Master
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("skillsetWantToMaster")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.skillsetWantToMaster.map((item) =>
                  renderChipWithIcon(item),
                )}
              </Box>
            </Box>

            {/* Learning Goals */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Learning Goals
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("learningGoal")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.learningGoal.map((item) =>
                  renderChipWithIcon(item),
                )}
              </Box>
            </Box>

            {/* Struggles Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Learning Struggles
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("learningStruggles")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.learningStruggles.map((item) =>
                  renderChipWithIcon(item),
                )}
              </Box>
            </Box>

            {/* Schedule Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Comfortable Learning Time
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("comfortableLearningTime")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.comfortableLearningTime.map((item) =>
                  renderChipWithIconAndTitle(item),
                )}
              </Box>
            </Box>

            {/* Goals Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Daily Learning Goals
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("dailyLearningGoal")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.dailyLearningGoal.map((item) =>
                  renderChipWithIcon(item),
                )}
              </Box>
            </Box>

            {renderMotivationSection("welcome", "Welcome")}
            {renderMotivationSection("motivationOne", "Motivation One")}
            {renderMotivationSection("motivationTwo", "Motivation Two")}
            {renderMotivationSection("motivationThree", "Motivation Three")}
            {renderMotivationSection("loading", "Loading")}
          </Box>
        ) : (
          <Typography>No onboarding data found</Typography>
        )}
      </Paper>

      <Dialog
        open={isDialogOpen}
        onClose={() => setIsDialogOpen(false)}
        maxWidth="md"
        fullWidth
        PaperProps={{
          sx: {
            minHeight: "70vh",
            borderRadius: 2,
            boxShadow: "0 8px 24px rgba(0,0,0,0.15)",
          },
        }}
      >
        <DialogTitle>
          <Box
            sx={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
            }}
          >
            <Typography variant="h6" sx={{ fontWeight: "bold" }}>
              {activeTab === "intro" && "Edit Introduction Steps"}
              {activeTab === "age" && "Edit Age Options"}
              {activeTab === "gender" && "Edit Gender Options"}
              {activeTab === "skillsetWantToMaster" &&
                "Edit Skillset to Master"}
              {activeTab === "learningGoal" && "Edit Learning Goals"}
              {activeTab === "learningStruggles" && "Edit Learning Struggles"}
              {activeTab === "comfortableLearningTime" && "Edit Learning Times"}
              {activeTab === "dailyLearningGoal" && "Edit Daily Goals"}
              {activeTab === "welcome" && "Edit Welcome"}
              {activeTab === "motivationOne" && "Edit Motivation One"}
              {activeTab === "motivationTwo" && "Edit Motivation Two"}
              {activeTab === "motivationThree" && "Edit Motivation Three"}
              {activeTab === "loading" && "Edit Loading"}
            </Typography>
            <IconButton onClick={() => setIsDialogOpen(false)}>
              <Close />
            </IconButton>
          </Box>
        </DialogTitle>
        <DialogContent>
          {activeTab === "intro" && renderIntroTab()}
          {activeTab === "age" && renderLabelsTab("age", "Age Options")}
          {activeTab === "gender" &&
            renderLabelsTab("gender", "Gender Options")}
          {activeTab === "skillsetWantToMaster" &&
            renderLabelsTab("skillsetWantToMaster", "Skillset to Master")}
          {activeTab === "learningGoal" &&
            renderLabelsTab("learningGoal", "Learning Goals")}
          {activeTab === "learningStruggles" &&
            renderLabelsTab("learningStruggles", "Learning Struggles")}
          {activeTab === "comfortableLearningTime" &&
            renderLabelsTab("comfortableLearningTime", "Learning Times", true)}
          {activeTab === "dailyLearningGoal" && renderDailyGoalTab()}
          {activeTab === "welcome" && renderMotivationTab("welcome", "Welcome")}
          {activeTab === "motivationOne" &&
            renderMotivationTab("motivationOne", "Motivation One")}
          {activeTab === "motivationTwo" &&
            renderMotivationTab("motivationTwo", "Motivation Two")}
          {activeTab === "motivationThree" &&
            renderMotivationTab("motivationThree", "Motivation Three")}
          {activeTab === "loading" && renderMotivationTab("loading", "Loading")}
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => setIsDialogOpen(false)}
            sx={{
              transition: "all 0.3s ease",
              "&:hover": { bgcolor: "grey.200" },
            }}
          >
            Cancel
          </Button>
          <Button
            onClick={handleSave}
            variant="contained"
            startIcon={<Save />}
            disabled={loading}
            sx={{
              transition: "all 0.3s ease",
              "&:hover": { transform: "translateY(-2px)" },
            }}
          >
            {loading ? "Saving..." : "Save"}
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default OnboardingManagement;
