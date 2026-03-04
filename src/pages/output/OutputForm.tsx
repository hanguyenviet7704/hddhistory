import React, { useEffect, useState } from "react";
import { TrashIcon } from "@heroicons/react/24/outline";
import { XMarkIcon } from "@heroicons/react/24/solid";
import { useSelector } from "react-redux";
import { Combobox } from "@headlessui/react";
import { useNavigate } from "react-router-dom";
import { AnimatePresence } from "framer-motion";
import { EditorContent, useEditor } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import { Bold, Italic, List, ListOrdered } from "lucide-react";
import { RootState } from "../../store";
import { ICourse } from "../../types/interface/course.interface";
import { ITag } from "../../types/interface/tag.interface";
import { IAvatar } from "../../types/interface/avatar.interface";
import { ILesson, LessonPayload } from "../../types/interface/lesson.interface";
import { LessonStatus, LessonType } from "../../types/enum/lesson.enum";
import { LangCode } from "../../types/enum/common.enum";
import { courseService } from "../../services/courseService";
import { tagService } from "../../services/tagService";
import { avatarService } from "../../services/avatarService";
import { lessonService } from "../../services/lessonService";
import CloudflareFileUpload from "../../components/files/CloudflareFileUpload";
import LessonConfirm from "../../components/lessons/LessonConfirm";
import { useNotification } from "../../utils/hooks/useNotification";
import {
  cleanTranslation,
  getTranslationValue,
  updateTranslationValue,
} from "../../utils/translation";
import {
  EstimateCompleteTimeUnit,
  buildEstimateCompleteTimeValue,
  getEstimateCompleteTimeUnitLabel,
  parseEstimateCompleteTimeInput,
} from "../../utils/estimate-complete-time";

interface OutputFormProps {
  output?: ILesson;
  onSave?: (output: ILesson) => void;
}

interface AIConfigEditorProps {
  value: string;
  onChange: (value: string) => void;
}

const AIConfigEditor: React.FC<AIConfigEditorProps> = ({ value, onChange }) => {
  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        heading: false,
        blockquote: false,
        codeBlock: false,
        horizontalRule: false,
      }),
    ],
    content: value || "<p></p>",
    editorProps: {
      attributes: {
        class:
          "ai-config-editor-content min-h-[180px] rounded-b-lg border border-t-0 border-gray-300 p-3 focus:outline-none",
      },
    },
    onUpdate: ({ editor: nextEditor }) => {
      onChange(nextEditor.getHTML());
    },
  });

  useEffect(() => {
    if (!editor) return;
    const current = editor.getHTML();
    if (value !== current) {
      editor.commands.setContent(value || "<p></p>", false);
    }
  }, [editor, value]);

  if (!editor) return null;

  const toolbarBtn = (active: boolean) =>
    `p-2 rounded-md border transition ${
      active
        ? "bg-blue-100 text-blue-700 border-blue-300"
        : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
    }`;

  return (
    <div className="rounded-lg overflow-hidden">
      <div className="flex flex-wrap items-center gap-2 border border-gray-300 border-b-0 rounded-t-lg bg-gray-50 p-2">
        <button
          type="button"
          aria-label="Bold"
          title="Bold"
          onMouseDown={(e) => e.preventDefault()}
          onClick={() => editor.chain().focus().toggleBold().run()}
          className={toolbarBtn(editor.isActive("bold"))}
        >
          <Bold className="h-4 w-4" />
        </button>
        <button
          type="button"
          aria-label="Italic"
          title="Italic"
          onMouseDown={(e) => e.preventDefault()}
          onClick={() => editor.chain().focus().toggleItalic().run()}
          className={toolbarBtn(editor.isActive("italic"))}
        >
          <Italic className="h-4 w-4" />
        </button>
        <button
          type="button"
          aria-label="Bullet list"
          title="Bullet List"
          onMouseDown={(e) => e.preventDefault()}
          onClick={() => editor.chain().focus().toggleBulletList().run()}
          className={toolbarBtn(editor.isActive("bulletList"))}
        >
          <List className="h-4 w-4" />
        </button>
        <button
          type="button"
          aria-label="Ordered list"
          title="Ordered List"
          onMouseDown={(e) => e.preventDefault()}
          onClick={() => editor.chain().focus().toggleOrderedList().run()}
          className={toolbarBtn(editor.isActive("orderedList"))}
        >
          <ListOrdered className="h-4 w-4" />
        </button>
      </div>
      <EditorContent editor={editor} />
    </div>
  );
};

const createInitialOutput = (lang: string): ILesson =>
  ({
    _id: "",
    courseId: "",
    type: LessonType.OUTPUT,
    title: { en: "Practice" },
    description: { [lang]: "" },
    image: "",
    keypoints: [],
    estimateCompleTime: { [lang]: "" },
    icon: null,
    lightIcon: null,
    AIConfig: "",
    animation: null,
    status: LessonStatus.DRAFT,
    index: 0,
  }) as ILesson;

export default function OutputForm({ output, onSave }: OutputFormProps) {
  const lang = useSelector((state: RootState) => state.lang.code);
  const isEditMode = !!output;
  const navigate = useNavigate();
  const { showSuccess, showError } = useNotification();

  const [currentOutput, setCurrentOutput] = useState<ILesson>(
    output ?? createInitialOutput(lang),
  );
  const [saving, setSaving] = useState(false);
  const [courses, setCourses] = useState<ICourse[]>([]);
  const [courseQuery, setCourseQuery] = useState("");
  const [selectedCourse, setSelectedCourse] = useState<ICourse | null>(null);
  const [confirmDeleteOutput, setConfirmDeleteOutput] = useState(false);

  const [icons, setIcons] = useState<ITag[]>([]);
  const [iconQuery, setIconQuery] = useState("");
  const [isIconSearchActive, setIsIconSearchActive] = useState(false);

  const [lightIcons, setLightIcons] = useState<ITag[]>([]);
  const [lightIconQuery, setLightIconQuery] = useState("");
  const [isLightIconSearchActive, setIsLightIconSearchActive] = useState(false);

  const [animations, setAnimations] = useState<IAvatar[]>([]);
  const [animationQuery, setAnimationQuery] = useState("");
  const [isAnimationSearchActive, setIsAnimationSearchActive] = useState(false);
  const [estimateCompleTimeInput, setEstimateCompleTimeInput] = useState("");
  const [estimateCompleTimeUnit, setEstimateCompleTimeUnit] =
    useState<EstimateCompleteTimeUnit>("minute");

  const normalizeTagList = (res: any): ITag[] => {
    const list = res?.data?.items ?? res?.data ?? res?.items ?? [];
    return Array.isArray(list) ? list : [];
  };

  useEffect(() => {
    if (!output) {
      setCurrentOutput(createInitialOutput(lang));
      return;
    }

    setCurrentOutput({
      ...createInitialOutput(lang),
      ...output,
      title: output.title || { en: "Practice" },
      AIConfig: output.AIConfig || "",
      animation: output.animation || null,
    });
  }, [output, lang]);

  useEffect(() => {
    const parsed = parseEstimateCompleteTimeInput(
      currentOutput.estimateCompleTime,
      currentOutput.estimateCompleTimeNumber,
      lang
    );
    setEstimateCompleTimeInput(parsed.amount);
    setEstimateCompleTimeUnit(parsed.unit);
  }, [
    currentOutput.estimateCompleTime,
    currentOutput.estimateCompleTimeNumber,
    lang,
  ]);

  useEffect(() => {
    let active = true;
    const fetchIcons = async () => {
      try {
        const res = await tagService.getList({ search: iconQuery });
        const list = normalizeTagList(res);
        if (active) setIcons(list);
      } catch (err) {
        console.error("fetchIcons", err);
      }
    };
    fetchIcons();
    return () => {
      active = false;
    };
  }, [iconQuery]);

  useEffect(() => {
    let active = true;
    const fetchLightIcons = async () => {
      try {
        const res = await tagService.getList({ search: lightIconQuery });
        const list = normalizeTagList(res);
        if (active) setLightIcons(list);
      } catch (err) {
        console.error("fetchLightIcons", err);
      }
    };
    fetchLightIcons();
    return () => {
      active = false;
    };
  }, [lightIconQuery]);

  useEffect(() => {
    let active = true;
    const fetchAnimations = async () => {
      try {
        const res = await avatarService.getList({
          page: 1,
          take: 100,
          search: animationQuery,
        });
        const list: IAvatar[] =
          res?.data?.items ?? res?.data ?? res?.items ?? ([] as IAvatar[]);
        if (active) setAnimations(Array.isArray(list) ? list : []);
      } catch (err) {
        console.error("fetchAnimations", err);
      }
    };
    fetchAnimations();
    return () => {
      active = false;
    };
  }, [animationQuery]);

  useEffect(() => {
    let active = true;
    const fetchCourses = async () => {
      try {
        const res = await courseService.getList({
          page: 1,
          take: 20,
          search: courseQuery,
          isAll: true,
        });
        const list: ICourse[] = res.data.items ?? [];
        if (active) setCourses(list);
      } catch (err) {
        console.error("fetchCourses", err);
      }
    };
    fetchCourses();
    return () => {
      active = false;
    };
  }, [courseQuery]);

  useEffect(() => {
    if (!currentOutput.courseId) {
      setSelectedCourse(null);
      return;
    }

    const fetchCourseDetails = async () => {
      try {
        const res = await courseService.getById(currentOutput.courseId);
        if (res.data) setSelectedCourse(res.data);
      } catch (err) {
        console.error("fetchCourseDetails", err);
      }
    };

    fetchCourseDetails();
  }, [currentOutput.courseId]);

  const getTagId = (tag: ITag | null | undefined) => (tag as any)?._id || "";

  const applyEstimateCompleTime = (
    amount: string,
    unit: EstimateCompleteTimeUnit
  ) => {
    const { label, estimateCompleTimeNumber } = buildEstimateCompleteTimeValue(
      amount,
      unit,
      lang
    );
    setCurrentOutput((prev) => ({
      ...prev,
      estimateCompleTime: updateTranslationValue(prev.estimateCompleTime, lang, label),
      estimateCompleTimeNumber,
    }));
  };

  const handleSaveOutput = async () => {
    try {
      setSaving(true);

      const localizedTitleValue =
        currentOutput.title?.[lang] ||
        (lang !== "en" ? currentOutput.title?.en || "" : "");

      const title = cleanTranslation(
        updateTranslationValue(
          currentOutput.title || { en: "Practice" },
          lang,
          localizedTitleValue,
        ),
      );

      const description = cleanTranslation(
        updateTranslationValue(
          currentOutput.description,
          lang,
          currentOutput.description?.[lang] || "",
        ),
      );
      const {
        label: estimateCompleTimeLabel,
        estimateCompleTimeNumber,
      } = buildEstimateCompleteTimeValue(
        estimateCompleTimeInput,
        estimateCompleTimeUnit,
        lang
      );

      const estimateCompleTime = cleanTranslation(
        updateTranslationValue(
          currentOutput.estimateCompleTime,
          lang,
          estimateCompleTimeLabel,
        ),
      );

      const keypointIds =
        currentOutput.keypoints?.map((kp: any) => kp?._id || kp) || [];

      const lessonPayload: LessonPayload = {
        courseId: currentOutput.courseId,
        learningItemId: currentOutput.learningItemId,
        type: LessonType.OUTPUT,
        title: title || { en: "Practice" },
        ...(description && { description }),
        ...(estimateCompleTime && { estimateCompleTime }),
        ...(Number.isFinite(estimateCompleTimeNumber) && {
          estimateCompleTimeNumber,
        }),
        image: currentOutput.image,
        status: currentOutput.status,
        keypoints: keypointIds,
        icon: getTagId(currentOutput.icon),
        lightIcon: getTagId(currentOutput.lightIcon),
        AIConfig: currentOutput.AIConfig || "",
        animation: currentOutput.animation?._id || "",
        index: currentOutput.index,
      };

      let res;
      if (currentOutput._id) {
        res = await lessonService.update(currentOutput._id, lessonPayload);
      } else {
        res = await lessonService.create(lessonPayload);
      }

      const savedOutput = res.data?.data ?? res.data;
      onSave?.(savedOutput);
      currentOutput._id
        ? showSuccess("Saved output successfully")
        : showSuccess("Create output successfully");
    } catch (err) {
      console.error("handleSaveOutput", err);
      showError(
        (err as any).response?.data?.message || "Failed to save output",
      );
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteOutput = async () => {
    if (!currentOutput._id) return;

    try {
      await lessonService.remove(currentOutput._id);
      setConfirmDeleteOutput(false);
      navigate("/output");
    } catch (err) {
      console.error(err);
    } finally {
      setConfirmDeleteOutput(false);
    }
  };

  const handleOutputImageChange = (newUrl: string) => {
    setCurrentOutput((prev) => ({
      ...prev,
      image: newUrl,
    }));
  };

  const handleClearIcon = () => {
    setCurrentOutput((prev) => ({
      ...prev,
      icon: null,
    }));
    setIconQuery("");
    setIsIconSearchActive(false);
  };

  const handleClearLightIcon = () => {
    setCurrentOutput((prev) => ({
      ...prev,
      lightIcon: null,
    }));
    setLightIconQuery("");
    setIsLightIconSearchActive(false);
  };

  const handleClearAnimation = () => {
    setCurrentOutput((prev) => ({
      ...prev,
      animation: null,
    }));
    setAnimationQuery("");
    setIsAnimationSearchActive(false);
  };

  const handleSelectIcon = (icon: ITag) => {
    setCurrentOutput((prev) => ({
      ...prev,
      icon: icon as any,
    }));
    setIsIconSearchActive(false);
    setIconQuery("");
  };

  const handleSelectLightIcon = (icon: ITag) => {
    setCurrentOutput((prev) => ({
      ...prev,
      lightIcon: icon as any,
    }));
    setIsLightIconSearchActive(false);
    setLightIconQuery("");
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <div className="max-w-7xl mx-auto">
        <div className="bg-white shadow-xl rounded-xl overflow-hidden flex flex-col md:flex-row">
          <div className="flex-1 flex flex-col items-start p-6 bg-gray-50">
            <div className="w-full">
              {currentOutput.image ? (
                <img
                  src={currentOutput.image}
                  alt={getTranslationValue(currentOutput.title, lang)}
                  className="w-full max-h-[320px] object-cover rounded-xl shadow-lg border border-gray-200"
                />
              ) : (
                <div className="w-full h-[320px] bg-gray-100 flex items-center justify-center rounded-xl border border-dashed border-gray-300 text-gray-400">
                  <div className="text-center">
                    <p>No image</p>
                  </div>
                </div>
              )}
            </div>

            <div className="mt-6 w-52 h-auto max-w-md">
              <CloudflareFileUpload
                initialUrl={currentOutput.image || ""}
                onUrlChange={handleOutputImageChange}
                label="Upload Image"
                uploadPayload={{
                  prefix: "",
                  folder: "lessons",
                }}
              />
            </div>
          </div>

          <div className="flex-[1.5] p-6">
            <h1 className="text-2xl md:text-3xl font-bold text-gray-800 mb-6">
              {isEditMode ? "✏️ Edit Output" : "🌱 Create New Output"}
            </h1>

            <div className="space-y-6">
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Title *
                </label>
                <input
                  value={
                    currentOutput.title?.[lang] ||
                    (lang !== "en" ? currentOutput.title?.en || "" : "")
                  }
                  onChange={(e) =>
                    setCurrentOutput((prev) => ({
                      ...prev,
                      title: updateTranslationValue(
                        prev.title,
                        lang,
                        e.target.value,
                      ),
                    }))
                  }
                  className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                  placeholder="Output title..."
                  required
                />
              </div>

              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Description
                </label>
                <textarea
                  value={currentOutput.description?.[lang] || ""}
                  onChange={(e) =>
                    setCurrentOutput((prev) => ({
                      ...prev,
                      description: updateTranslationValue(
                        prev.description,
                        lang,
                        e.target.value,
                      ),
                    }))
                  }
                  rows={4}
                  className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition resize-none"
                  placeholder="Short description..."
                />
              </div>

              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Time complete
                </label>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <select
                    value={estimateCompleTimeUnit}
                    onChange={(e) => {
                      const nextUnit = e.target.value as EstimateCompleteTimeUnit;
                      setEstimateCompleTimeUnit(nextUnit);
                      applyEstimateCompleTime(estimateCompleTimeInput, nextUnit);
                    }}
                    className="border rounded-lg w-full p-3 bg-white focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                  >
                    <option value="minute">
                      {getEstimateCompleteTimeUnitLabel(
                        "minute",
                        lang as LangCode,
                        2
                      )}
                    </option>
                    <option value="hour">
                      {getEstimateCompleteTimeUnitLabel("hour", lang as LangCode, 2)}
                    </option>
                  </select>
                  <input
                    type="number"
                    min={1}
                    step={1}
                    value={estimateCompleTimeInput}
                    onChange={(e) => {
                      const nextAmount = e.target.value;
                      setEstimateCompleTimeInput(nextAmount);
                      applyEstimateCompleTime(nextAmount, estimateCompleTimeUnit);
                    }}
                    className="border rounded-lg w-full p-3 sm:col-span-2 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                    placeholder="Enter number..."
                  />
                </div>
              </div>

              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Icon
                </label>

                <div className="relative">
                  <input
                    value={
                      isIconSearchActive
                        ? iconQuery
                        : getTranslationValue(
                            (currentOutput.icon as any)?.title,
                            lang,
                          ) || ""
                    }
                    onChange={(e) => setIconQuery(e.target.value)}
                    onFocus={() => {
                      setIsIconSearchActive(true);
                      setIconQuery(
                        getTranslationValue(
                          (currentOutput.icon as any)?.title,
                          lang,
                        ) || "",
                      );
                    }}
                    onBlur={() => {
                      setTimeout(() => {
                        setIsIconSearchActive(false);
                        setIconQuery("");
                      }, 150);
                    }}
                    className="border rounded-lg w-full p-3 pr-10 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                    placeholder="Search icon..."
                  />

                  {currentOutput.icon && !isIconSearchActive && (
                    <button
                      type="button"
                      onClick={handleClearIcon}
                      className="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-600 focus:outline-none"
                    >
                      <XMarkIcon className="h-5 w-5" aria-hidden="true" />
                    </button>
                  )}

                  {isIconSearchActive && (
                    <div className="absolute z-10 mt-1 w-full max-h-60 overflow-auto rounded-lg border bg-white shadow-lg">
                      {icons
                        .filter((icon) => {
                          const title = (
                            icon.title?.[lang] || ""
                          ).toLowerCase();
                          return (
                            !iconQuery ||
                            title.includes(iconQuery.toLowerCase())
                          );
                        })
                        .map((icon) => (
                          <div
                            key={icon._id}
                            className="flex items-center gap-3 p-3 hover:bg-gray-50 cursor-pointer transition-colors"
                            onMouseDown={(e) => e.preventDefault()}
                            onClick={() => handleSelectIcon(icon)}
                          >
                            {icon.url ? (
                              <img
                                src={icon.url}
                                alt={icon.title?.[lang]}
                                className="w-6 h-6 object-cover rounded"
                              />
                            ) : (
                              <div
                                className="w-6 h-6 rounded flex items-center justify-center"
                                style={{
                                  backgroundColor: icon.color || "#f3f4f6",
                                }}
                              />
                            )}
                            <div className="flex-1">
                              <div className="font-medium text-gray-800">
                                {icon.title?.[lang]}
                              </div>
                            </div>
                          </div>
                        ))}
                    </div>
                  )}
                </div>
              </div>

              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Light Icon
                </label>

                <div className="relative">
                  <input
                    value={
                      isLightIconSearchActive
                        ? lightIconQuery
                        : getTranslationValue(
                            (currentOutput.lightIcon as any)?.title,
                            lang,
                          ) || ""
                    }
                    onChange={(e) => setLightIconQuery(e.target.value)}
                    onFocus={() => {
                      setIsLightIconSearchActive(true);
                      setLightIconQuery(
                        getTranslationValue(
                          (currentOutput.lightIcon as any)?.title,
                          lang,
                        ) || "",
                      );
                    }}
                    onBlur={() => {
                      setTimeout(() => {
                        setIsLightIconSearchActive(false);
                        setLightIconQuery("");
                      }, 150);
                    }}
                    className="border rounded-lg w-full p-3 pr-10 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                    placeholder="Search light icon..."
                  />

                  {currentOutput.lightIcon && !isLightIconSearchActive && (
                    <button
                      type="button"
                      onClick={handleClearLightIcon}
                      className="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-600 focus:outline-none"
                    >
                      <XMarkIcon className="h-5 w-5" aria-hidden="true" />
                    </button>
                  )}

                  {isLightIconSearchActive && (
                    <div className="absolute z-10 mt-1 w-full max-h-60 overflow-auto rounded-lg border bg-white shadow-lg">
                      {lightIcons
                        .filter((icon) => {
                          const title = (
                            icon.title?.[lang] || ""
                          ).toLowerCase();
                          return (
                            !lightIconQuery ||
                            title.includes(lightIconQuery.toLowerCase())
                          );
                        })
                        .map((icon) => (
                          <div
                            key={icon._id}
                            className="flex items-center gap-3 p-3 hover:bg-gray-50 cursor-pointer transition-colors"
                            onMouseDown={(e) => e.preventDefault()}
                            onClick={() => handleSelectLightIcon(icon)}
                          >
                            {icon.url ? (
                              <img
                                src={icon.url}
                                alt={icon.title?.[lang]}
                                className="w-6 h-6 object-cover rounded"
                              />
                            ) : (
                              <div
                                className="w-6 h-6 rounded flex items-center justify-center"
                                style={{
                                  backgroundColor: icon.color || "#f3f4f6",
                                }}
                              />
                            )}
                            <div className="flex-1">
                              <div className="font-medium text-gray-800">
                                {icon.title?.[lang]}
                              </div>
                            </div>
                          </div>
                        ))}
                    </div>
                  )}
                </div>
              </div>

              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Animation
                </label>

                <div className="relative">
                  <input
                    value={
                      isAnimationSearchActive
                        ? animationQuery
                        : currentOutput.animation?.name || ""
                    }
                    onChange={(e) => setAnimationQuery(e.target.value)}
                    onFocus={() => {
                      setIsAnimationSearchActive(true);
                      setAnimationQuery(currentOutput.animation?.name || "");
                    }}
                    onBlur={() => {
                      setTimeout(() => {
                        setIsAnimationSearchActive(false);
                        setAnimationQuery("");
                      }, 150);
                    }}
                    className="border rounded-lg w-full p-3 pr-10 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                    placeholder="Search animation..."
                  />

                  {currentOutput.animation && !isAnimationSearchActive && (
                    <button
                      type="button"
                      onClick={handleClearAnimation}
                      className="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-600 focus:outline-none"
                    >
                      <XMarkIcon className="h-5 w-5" aria-hidden="true" />
                    </button>
                  )}

                  {isAnimationSearchActive && animationQuery && (
                    <div className="absolute z-10 mt-1 w-full max-h-60 overflow-auto rounded-lg border bg-white shadow-lg">
                      {animations
                        .filter((avatar) =>
                          avatar.name
                            ?.toLowerCase()
                            .includes(animationQuery.toLowerCase()),
                        )
                        .map((avatar) => (
                          <div
                            key={avatar._id}
                            className="flex items-center gap-3 p-3 hover:bg-gray-50 cursor-pointer transition-colors"
                            onClick={() => {
                              setCurrentOutput((prev) => ({
                                ...prev,
                                animation: avatar,
                              }));
                              setIsAnimationSearchActive(false);
                              setAnimationQuery("");
                            }}
                          >
                            <img
                              src={avatar.url}
                              alt={avatar.name}
                              className="w-8 h-8 object-cover rounded-full border"
                            />
                            <div className="flex-1">
                              <div className="font-medium text-gray-800">
                                {avatar.name}
                              </div>
                            </div>
                          </div>
                        ))}
                    </div>
                  )}
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block mb-1 text-sm font-medium text-gray-700">
                    Status
                  </label>
                  <select
                    value={currentOutput.status}
                    onChange={(e) =>
                      setCurrentOutput((prev) => ({
                        ...prev,
                        status: e.target.value as LessonStatus,
                      }))
                    }
                    className="border rounded-lg w-full p-3 bg-white focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                  >
                    {Object.values(LessonStatus).map((status) => (
                      <option key={status} value={status}>
                        {status.charAt(0).toUpperCase() + status.slice(1)}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block mb-1 text-sm font-medium text-gray-700">
                    Course *
                  </label>

                  <Combobox<string | null>
                    value={currentOutput.courseId || null}
                    onChange={(val: string | null) => {
                      setCurrentOutput((prev) => ({
                        ...prev,
                        courseId: val ?? "",
                      }));
                      setCourseQuery("");
                    }}
                  >
                    <div className="relative">
                      <Combobox.Input
                        displayValue={() => {
                          if (selectedCourse) {
                            return getTranslationValue(
                              selectedCourse.title,
                              lang,
                            );
                          }
                          return courseQuery;
                        }}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                          setCourseQuery(e.target.value)
                        }
                        className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                        placeholder="Search course..."
                      />

                      <Combobox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                        {courses
                          .filter((course) =>
                            getTranslationValue(course.title, lang)
                              ?.toLowerCase()
                              .includes(courseQuery.toLowerCase()),
                          )
                          .map((course) => (
                            <Combobox.Option
                              key={course._id}
                              value={course._id}
                              className="cursor-pointer px-3 py-3 hover:bg-blue-50"
                            >
                              {getTranslationValue(course.title, lang)}
                            </Combobox.Option>
                          ))}
                      </Combobox.Options>
                    </div>
                  </Combobox>
                </div>
              </div>

              <div className="pt-4 flex justify-end">
                <button
                  onClick={handleSaveOutput}
                  disabled={saving}
                  className={`flex items-center justify-center gap-2 px-6 py-3 rounded-lg text-white font-semibold shadow transition ${
                    saving
                      ? "bg-gray-400 cursor-not-allowed"
                      : "bg-gradient-to-r from-blue-600 to-green-500 hover:opacity-90"
                  }`}
                >
                  {saving
                    ? "Saving..."
                    : isEditMode
                      ? "Save Output"
                      : "Create Output"}
                </button>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-8 bg-white shadow-xl rounded-xl p-6">
          <label className="block mb-1 text-sm font-medium text-gray-700">
            AI Config
          </label>
          <AIConfigEditor
            value={currentOutput.AIConfig || ""}
            onChange={(value) =>
              setCurrentOutput((prev) => ({
                ...prev,
                AIConfig: value,
              }))
            }
          />
        </div>

        {currentOutput._id && (
          <div className="flex justify-center mt-8">
            <button
              onClick={() => setConfirmDeleteOutput(true)}
              className="px-6 py-3 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg shadow hover:from-red-700 hover:to-red-800 transition-all flex items-center gap-2"
            >
              <TrashIcon className="h-5 w-5" />
              Delete Output
            </button>
          </div>
        )}

        <AnimatePresence>
          {confirmDeleteOutput && (
            <LessonConfirm
              title="Confirm Delete"
              message="Are you sure you want to delete this output? This action cannot be undone."
              onCancel={() => setConfirmDeleteOutput(false)}
              onConfirm={handleDeleteOutput}
            />
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
