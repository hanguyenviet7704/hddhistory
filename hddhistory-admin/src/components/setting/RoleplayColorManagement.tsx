import React, { useEffect, useState, useRef } from "react";
import {
  IColorStyle,
  IRoleplayColorTemplate,
} from "../../types/interface/learning-item/roleplays/color-template.interface";
import { roleplayColorTemplateService } from "../../services/roleplayColorTemplateService";
import { PlusIcon, TrashIcon } from "@heroicons/react/24/outline";
import { PencilSquareIcon } from "@heroicons/react/24/solid";
import { useNotification } from "../../utils/hooks/useNotification";
import RoleplayColorConfirm from "./RoleplayColorConfirm";

type RoleplayColorTemplateForm = IRoleplayColorTemplate & { _id?: string };

const defaultStyle = (bg = "#ffffff", text = "#111827"): IColorStyle => ({
  backgroundColor: bg,
  textColor: text,
});

const cloneStyle = (style?: IColorStyle): IColorStyle => ({
  backgroundColor: style?.backgroundColor || "#ffffff",
  textColor: style?.textColor || "#111827",
});

const createEmptyTemplate = (): RoleplayColorTemplateForm => ({
  title: "",
  conversation: {
    left: defaultStyle("#f0f9ff", "#0f172a"),
    right: defaultStyle("#fff7ed", "#1c1917"),
  },
  leadingText: defaultStyle("#eef2ff", "#1e1b4b"),
  transition: defaultStyle("#fdf2f8", "#86198f"),
  resultsOfAnsweringTheQuestion: defaultStyle("#ecfdf3", "#065f46"),
});

const ColorInput = ({
  label,
  color,
  onChange,
}: {
  label: string;
  color: string;
  onChange: (value: string) => void;
}) => (
  <div className="space-y-1">
    <label className="block text-xs font-medium text-gray-500">{label}</label>
    <div className="flex items-center gap-2">
      <input
        type="color"
        value={color || "#000000"}
        onChange={(e) => onChange(e.target.value)}
        className="h-10 w-10 rounded border"
      />
      <input
        type="text"
        value={color || ""}
        onChange={(e) => onChange(e.target.value)}
        className="flex-1 border rounded px-2 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
        placeholder="#000000"
      />
    </div>
  </div>
);

const ColorStyleField = ({
  label,
  value,
  onChange,
}: {
  label: string;
  value: IColorStyle;
  onChange: (field: keyof IColorStyle, value: string) => void;
}) => (
  <div className="border rounded-lg p-3 space-y-3">
    <div className="font-medium text-gray-800">{label}</div>
    <div className="grid gap-3 md:grid-cols-2">
      <ColorInput
        label="Background color"
        color={value.backgroundColor || ""}
        onChange={(val) => onChange("backgroundColor", val)}
      />
      <ColorInput
        label="Text color"
        color={value.textColor || ""}
        onChange={(val) => onChange("textColor", val)}
      />
    </div>
  </div>
);

const ColorSwatchPreview = ({
  label,
  style,
}: {
  label: string;
  style: IColorStyle;
}) => (
  <div className="rounded-xl border overflow-hidden">
    <div className="text-xs px-2 py-1 bg-gray-100">{label}</div>
    <div
      className="px-3 py-4 text-sm font-semibold min-h-[48px]"
      style={{
        backgroundColor: style.backgroundColor || "#ffffff",
        color: style.textColor || "#111827",
      }}
    >
      Aa
    </div>
    <div className="text-[11px] px-2 py-1 border-t text-gray-500 space-y-0.5">
      <div>BG: {style.backgroundColor || "--"}</div>
      <div>Text: {style.textColor || "--"}</div>
    </div>
  </div>
);

const RoleplayColorManagement: React.FC = () => {
  const { showSuccess, showError } = useNotification();
  const [templates, setTemplates] = useState<RoleplayColorTemplateForm[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState<RoleplayColorTemplateForm>(
    createEmptyTemplate()
  );
  const [deleteTarget, setDeleteTarget] =
    useState<RoleplayColorTemplateForm | null>(null);
  const formRef = useRef<HTMLDivElement>(null);

  const fetchTemplates = async () => {
    try {
      setLoading(true);
      const res = await roleplayColorTemplateService.getList({
        page: 1,
        take: 1000,
      });
      const list: RoleplayColorTemplateForm[] =
        res?.data?.items ||
        res?.items ||
        res?.data ||
        res ||
        [];
      setTemplates(list || []);
    } catch (err) {
      console.error(err);
      showError("Failed to load templates");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTemplates();
  }, []);

  const resetForm = () => {
    setForm(createEmptyTemplate());
  };

  const handleStyleChange = (
    target:
      | "conversationLeft"
      | "conversationRight"
      | "leadingText"
      | "transition"
      | "resultsOfAnsweringTheQuestion",
    field: keyof IColorStyle,
    value: string
  ) => {
    setForm((prev) => {
      const next: RoleplayColorTemplateForm = {
        ...prev,
        conversation: {
          left: cloneStyle(prev.conversation?.left),
          right: cloneStyle(prev.conversation?.right),
        },
        leadingText: cloneStyle(prev.leadingText),
        transition: cloneStyle(prev.transition),
        resultsOfAnsweringTheQuestion: cloneStyle(
          prev.resultsOfAnsweringTheQuestion
        ),
      };

      const updateStyle = (style: IColorStyle) => ({
        ...style,
        [field]: value,
      });

      switch (target) {
        case "conversationLeft":
          next.conversation.left = updateStyle(next.conversation.left);
          break;
        case "conversationRight":
          next.conversation.right = updateStyle(next.conversation.right);
          break;
        case "leadingText":
          next.leadingText = updateStyle(next.leadingText);
          break;
        case "transition":
          next.transition = updateStyle(next.transition);
          break;
        case "resultsOfAnsweringTheQuestion":
          next.resultsOfAnsweringTheQuestion = updateStyle(
            next.resultsOfAnsweringTheQuestion
          );
          break;
        default:
          break;
      }

      return next;
    });
  };

  const handleEdit = (template: RoleplayColorTemplateForm) => {
    setForm({
      _id: template._id,
      title: template.title,
      conversation: {
        left: cloneStyle(template.conversation?.left),
        right: cloneStyle(template.conversation?.right),
      },
      leadingText: cloneStyle(template.leadingText),
      transition: cloneStyle(template.transition),
      resultsOfAnsweringTheQuestion: cloneStyle(
        template.resultsOfAnsweringTheQuestion
      ),
    });
    setShowForm(true);
    setTimeout(() => {
      formRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
    }, 0);
  };

  const handleSave = async () => {
    const trimmedTitle = form.title.trim();
    if (!trimmedTitle) {
      showError("Template title is required");
      return;
    }

    const payload: IRoleplayColorTemplate = {
      title: trimmedTitle,
      conversation: form.conversation,
      leadingText: form.leadingText,
      transition: form.transition,
      resultsOfAnsweringTheQuestion: form.resultsOfAnsweringTheQuestion,
    };

    try {
      setSaving(true);
      if (form._id) {
        await roleplayColorTemplateService.update(form._id, payload);
        showSuccess("Updated template successfully");
      } else {
        await roleplayColorTemplateService.create(payload);
        showSuccess("Created template successfully");
      }
      resetForm();
      setShowForm(false);
      fetchTemplates();
    } catch (err) {
      console.error(err);
      showError("Failed to save template");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id?: string) => {
    if (!id) return;
    try {
      setSaving(true);
      await roleplayColorTemplateService.remove(id);
      showSuccess("Deleted template");
      if (form._id === id) {
        resetForm();
        setShowForm(false);
      }
      fetchTemplates();
    } catch (err) {
      console.error(err);
      showError("Failed to delete template");
    } finally {
      setSaving(false);
      setDeleteTarget(null);
    }
  };

  const renderTemplates = () => {
    if (loading) {
      return (
        <div className="text-center py-8 text-gray-500">Loading templates…</div>
      );
    }

    if (!templates.length) {
      return (
        <div className="text-center py-8 text-gray-500">
          No templates found. Create one to get started.
        </div>
      );
    }

    return (
      <div className="grid gap-4 md:grid-cols-2">
        {templates.map((template) => (
          <div
            key={template._id || template.title}
            className="border rounded-xl p-4 bg-white shadow-sm space-y-4"
          >
            <div className="flex items-start justify-between gap-3">
              <div>
                <h3 className="text-lg font-semibold text-gray-800">
                  {template.title}
                </h3>
                <p className="text-sm text-gray-500">
                  Conversation, leading text & transition colors
                </p>
              </div>
              <div className="flex gap-2">
                <button
                  className="px-3 py-1 text-sm bg-gray-100 rounded inline-flex items-center gap-1"
                  onClick={() => handleEdit(template)}
                >
                  <PencilSquareIcon className="h-4 w-4" />
                  Edit
                </button>
                <button
                  className="px-3 py-1 text-sm bg-red-100 text-red-600 rounded inline-flex items-center gap-1"
                  onClick={() => setDeleteTarget(template)}
                  disabled={saving}
                >
                  <TrashIcon className="h-4 w-4" />
                  Delete
                </button>
              </div>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <ColorSwatchPreview
                label="Conversation Left"
                style={cloneStyle(template.conversation?.left)}
              />
              <ColorSwatchPreview
                label="Conversation Right"
                style={cloneStyle(template.conversation?.right)}
              />
              <ColorSwatchPreview
                label="Leading Text"
                style={cloneStyle(template.leadingText)}
              />
              <ColorSwatchPreview
                label="Transition"
                style={cloneStyle(template.transition)}
              />
              <ColorSwatchPreview
                label="Results of answering the question"
                style={cloneStyle(template.resultsOfAnsweringTheQuestion)}
              />
            </div>
          </div>
        ))}
      </div>
    );
  };

  return (
    <div className="space-y-6">
      <div className="bg-white shadow rounded-xl p-4 space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold">Roleplay Color Templates</h2>
          <button
            className="flex items-center gap-2 px-4 py-2 bg-bronze-600 text-white rounded-lg hover:bg-bronze-700 transition-colors"
            onClick={() => {
              resetForm();
              setShowForm((prev) => !prev);
            }}
          >
            <PlusIcon className="h-5 w-5" />
            {showForm ? "Close form" : "New Template"}
          </button>
        </div>

        {showForm && (
          <div
            className="border rounded-lg p-4 space-y-4 bg-gray-50"
            ref={formRef}
          >
            <div className="grid gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Template title
                </label>
                <input
                  type="text"
                  value={form.title}
                  onChange={(e) =>
                    setForm((prev) => ({ ...prev, title: e.target.value }))
                  }
                  className="w-full border rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-bronze-500"
                  placeholder="e.g. Calm Conversation"
                />
              </div>

              <div className="grid gap-4">
                <div className="border rounded-lg p-3 space-y-3 bg-white">
                  <div className="font-semibold">Conversation</div>
                  <div className="grid gap-4 md:grid-cols-2">
                    <ColorStyleField
                      label="Left bubble"
                      value={form.conversation.left}
                      onChange={(field, value) =>
                        handleStyleChange("conversationLeft", field, value)
                      }
                    />
                    <ColorStyleField
                      label="Right bubble"
                      value={form.conversation.right}
                      onChange={(field, value) =>
                        handleStyleChange("conversationRight", field, value)
                      }
                    />
                  </div>
                </div>

                <ColorStyleField
                  label="Leading text"
                  value={form.leadingText}
                  onChange={(field, value) =>
                    handleStyleChange("leadingText", field, value)
                  }
                />

                <ColorStyleField
                  label="Transition"
                  value={form.transition}
                  onChange={(field, value) =>
                    handleStyleChange("transition", field, value)
                  }
                />

                <ColorStyleField
                  label="Results of answering the question"
                  value={form.resultsOfAnsweringTheQuestion}
                  onChange={(field, value) =>
                    handleStyleChange(
                      "resultsOfAnsweringTheQuestion",
                      field,
                      value
                    )
                  }
                />
              </div>
            </div>

            <div className="flex gap-3">
              <button
                className="inline-flex items-center gap-2 px-4 py-2 bg-bronze-600 text-white rounded-lg disabled:opacity-60"
                onClick={handleSave}
                disabled={saving}
              >
                <PlusIcon className="h-5 w-5" />
                {form._id ? "Update template" : "Create template"}
              </button>
              {form._id && (
                <button
                  className="px-4 py-2 bg-gray-200 rounded-lg"
                  onClick={() => {
                    resetForm();
                    setShowForm(false);
                  }}
                  disabled={saving}
                >
                  Cancel edit
                </button>
              )}
            </div>
          </div>
        )}
      </div>

      <div className="bg-white shadow rounded-xl p-4">{renderTemplates()}</div>

      <RoleplayColorConfirm
        isOpen={!!deleteTarget}
        template={deleteTarget ?? undefined}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => handleDelete(deleteTarget?._id)}
      />
    </div>
  );
};

export default RoleplayColorManagement;
