import React, { useState, useEffect } from "react";
import {
  ILearningItem,
  LearningItemPayload,
} from "../../types/interface/learning-item/learning-item.interface";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { learningItemService } from "../../services/learningItemService";
import { LearningItemType } from "../../types/enum/learningItem.enum";
import {
  TrashIcon,
  PlusCircleIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";
import { PuzzlePieceIcon } from "@heroicons/react/24/solid";
import { motion, AnimatePresence } from "framer-motion";
import { DndContext, closestCenter } from "@dnd-kit/core";
import {
  arrayMove,
  SortableContext,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import SortableItem from "../../components/common/SortableItem";
import { keypointService } from "../../services/keypointService";
import { Combobox } from "@headlessui/react";
import { IKeypoint } from "../../types/interface/keypoint.interface";
import { useNavigate } from "react-router-dom";
import LearningItemConfirm from "../../components/learning-item/LearningItemConfirm";
import {
  ITheoryDocument,
  TheoryDocumentPayload,
} from "../../types/interface/learning-item/theories/theory.interface";
import { DocumentType } from "../../utils/enum/course.enum";
import {
  IDocument,
  IMediaDocument,
} from "../../types/interface/learning-item/document.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import { ITag } from "../../types/interface/tag.interface";
import { tagService } from "../../services/tagService";
import { ITranslation } from "../../utils/translate";
import {
  getTranslationValue,
  getCurrentTranslationValue,
  updateTranslationValue,
  cleanTranslation,
} from "../../utils/translation";
import { LangCode } from "../../types/enum/common.enum";
import CloudflareFileUpload from "../../components/files/CloudflareFileUpload";

const TEXTUAL_DOCUMENT_TYPES: DocumentType[] = [
  DocumentType.TITLE,
  DocumentType.CAPTION,
  DocumentType.TEXT,
];

const isTextualDocumentType = (type: DocumentType) =>
  TEXTUAL_DOCUMENT_TYPES.includes(type);

const cleanDocumentItems = (documents: IDocument[]) => {
  return documents
    .map((doc) => {
      const cleanedContent = cleanTranslation(doc.data?.content);
      const cleanedUrl = cleanTranslation(doc.data?.url);
      const cleanedData: any = { ...doc.data };
      if (cleanedContent && Object.keys(cleanedContent).length > 0) {
        cleanedData.content = cleanedContent;
      } else {
        delete cleanedData.content;
      }
      if (cleanedUrl && Object.keys(cleanedUrl).length > 0) {
        cleanedData.url = cleanedUrl;
      } else {
        delete cleanedData.url;
      }
      if (!cleanedData.thumbnail) {
        delete cleanedData.thumbnail;
      }

      const hasValue =
        (isTextualDocumentType(doc.type) &&
          !!cleanedData.content &&
          Object.keys(cleanedData.content).length > 0) ||
        ((doc.type === DocumentType.IMAGE || doc.type === DocumentType.AUDIO) &&
          !!cleanedData.url) ||
        (doc.type === DocumentType.VIDEO &&
          (!!cleanedData.url || !!cleanedData.thumbnail));

      return hasValue ? ({ ...doc, data: cleanedData } as IDocument) : null;
    })
    .filter(Boolean) as IDocument[];
};

const getDocumentContentLabel = (type: DocumentType) => {
  switch (type) {
    case DocumentType.TITLE:
      return "Title";
    case DocumentType.CAPTION:
      return "Caption";
    default:
      return "Content";
  }
};

const createEmptyMediaDocument = (currentLang: LangCode): IMediaDocument => ({
  content: { [currentLang]: "" },
  url: { [currentLang]: "" },
  thumbnail: "",
});

// Helper component để hiển thị văn bản với cắt bớt và tooltip
const TextWithTooltip = ({
  text = "",
  maxLength = 100,
  lang = LangCode.EN,
}: {
  text?: string | ITranslation;
  maxLength?: number;
  lang?: LangCode;
}) => {
  if (!text) return null;

  const displayText =
    typeof text === "string" ? text : getTranslationValue(text, lang);

  if (!displayText) return null;

  return (
    <div className="relative group">
      <span className="truncate inline-block max-w-xl">
        {displayText.length > maxLength
          ? `${displayText.substring(0, maxLength)}...`
          : displayText}
      </span>
      {displayText.length > maxLength && (
        <div className="absolute bottom-full left-0 mb-2 hidden group-hover:block z-10 bg-gray-800 text-white text-xs rounded py-2 px-3 w-64 max-h-40 overflow-y-auto shadow-lg">
          {displayText}
        </div>
      )}
    </div>
  );
};

// Định nghĩa một type riêng cho state của form, cho phép tag là null
type DocumentFormState = Omit<ITheoryDocument, "tag"> & { tag: ITag | null };

interface TheoryFormProps {
  theory?: ILearningItem;
  onSave?: (theory: ILearningItem) => void;
  onCancel?: () => void;
}

export default function TheoryForm({
  theory,
  onSave,
  onCancel,
}: TheoryFormProps) {
  const navigate = useNavigate();
  const lang = useSelector(
    (state: RootState) => state.lang.code
  ) as keyof ITranslation as LangCode;
  const isEditMode = !!theory;
  const { showSuccess, showError } = useNotification();

  const [keypoints, setKeypoints] = useState<IKeypoint[]>([]);
  const [keypointQuery, setKeypointQuery] = useState("");
  const [selectedKeypoint, setSelectedKeypoint] = useState<IKeypoint | null>(
    null
  );
  const [allTags, setAllTags] = useState<ITag[]>([]);
  const [nextDocId, setNextDocId] = useState(1);

  const [currentTheory, setCurrentTheory] = useState<ILearningItem>(
    () =>
      theory ??
      ({
        _id: "",
        keypointId: "",
        type: LearningItemType.THEORY,
        title: { [lang]: "" },
        image: "",
        isSub: false,
        tag: [],
        questions: [],
        subQuestions: [],
        documents: [],
        index: 0,
      } as ILearningItem)
  );

  useEffect(() => {
    if (theory) {
      setCurrentTheory(theory);
      const maxDocId =
        theory.documents?.reduce((max, doc) => Math.max(max, doc.id), 0) || 0;
      setNextDocId(maxDocId + 1);
    }
  }, [theory]); // Remove lang from dependency to prevent reset on language change

  // Separate effect to update title language when creating new theory
  useEffect(() => {
    if (!theory && currentTheory._id === "") {
      // Only update the title field to ensure it has the current language
      setCurrentTheory((prev) => ({
        ...prev,
        title: { [lang]: (prev.title as ITranslation)?.[lang] || "" },
      }));
    }
  }, [lang, theory, currentTheory._id]);

  const [saving, setSaving] = useState(false);
  const [modalOpen, setModalOpen] = useState<{
    section: "documents" | null;
    theoryDocument?: ITheoryDocument;
  }>({ section: null });
  const [confirmDeleteDocument, setConfirmDeleteDocument] = useState<{
    section: "documents" | null;
    itemId: number | null;
    itemTitle: string;
  } | null>(null);
  const [confirmDeleteTheory, setConfirmDeleteTheory] = useState(false);

  useEffect(() => {
    let active = true;
    const fetchKeypoints = async () => {
      try {
        const res = await keypointService.getList({
          page: 1,
          take: 20,
          search: keypointQuery,
        });
        const list: IKeypoint[] = res.data.items || [];
        if (active) setKeypoints(list);
      } catch (err) {
        console.error("fetchKeypoints", err);
      }
    };
    fetchKeypoints();
    return () => {
      active = false;
    };
  }, [keypointQuery]);

  useEffect(() => {
    let active = true;
    const fetchAllTags = async () => {
      try {
        const res = await tagService.getList({ page: 1, take: 1000 });
        const list: ITag[] = res.data.items || [];
        if (active) setAllTags(list);
      } catch (err) {
        console.error("fetchAllTags", err);
      }
    };
    fetchAllTags();
    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    if (currentTheory.keypointId) {
      const fetchKeypointDetail = async () => {
        try {
          const res = await keypointService.getById(currentTheory.keypointId);
          if (res.data) setSelectedKeypoint(res.data);
        } catch (err) {
          console.error("fetchKeypointDetail", err);
        }
      };
      fetchKeypointDetail();
    } else {
      setSelectedKeypoint(null);
    }
  }, [currentTheory.keypointId]);

  // Hàm helper chuyển đổi từ ITheoryDocument[] sang TheoryDocumentPayload[]
  const convertDocumentsToPayload = (
    documents: ITheoryDocument[]
  ): TheoryDocumentPayload[] => {
    return (
      documents
        .map((doc) => {
          const payload: any = {
            id: doc.id,
            tagId: doc.tag?._id || "",
            document: [],
          };

          // Only add speechBubble if it has non-empty translations
          const cleanedSpeechBubble = cleanTranslation(doc.speechBubble);
          if (cleanedSpeechBubble) {
            payload.speechBubble = cleanedSpeechBubble;
          }

          const cleanedDocuments = doc.document?.length
            ? cleanDocumentItems(doc.document)
            : [];

          if (cleanedDocuments.length > 0) {
            payload.document = cleanedDocuments;
          }

          // Skip if nothing to send
          if (
            !payload.speechBubble &&
            (!payload.document || payload.document.length === 0)
          ) {
            return null;
          }

          return payload;
        })
        // Remove empty payloads
        .filter(Boolean) as TheoryDocumentPayload[]
    );
  };

  const handleSaveTheory = async () => {
    try {
      setSaving(true);
      const payload: LearningItemPayload = {
        keypointId: currentTheory.keypointId,
        title: (cleanTranslation(currentTheory.title) || "") as string,
        type: LearningItemType.THEORY,
        image: currentTheory.image,
        tag: currentTheory.tag || [],
        isSub: currentTheory.isSub,
        documents: convertDocumentsToPayload(currentTheory.documents || []), // Sử dụng hàm helper
        index: currentTheory.index,
      };
      if (currentTheory._id) {
        await learningItemService.update(currentTheory._id, payload);
      } else {
        const res = await learningItemService.create(payload);
        const savedTheory = res.data?.data ?? res.data;
        setCurrentTheory(savedTheory);
        onSave?.(savedTheory);
      }
      showSuccess(
        isEditMode ? "Saved theory successfully" : "Create theory successfully"
      );
    } catch (err) {
      console.error("handleSaveTheory", err);
      showError(
        (err as any).response?.data?.message || "Failed to save theory"
      );
    } finally {
      setSaving(false);
    }
  };

  const handleReorder = (activeId: number, overId: number) => {
    setCurrentTheory((prev) => {
      if (!prev) return prev;
      const list = prev.documents || [];
      const activeIndex = list.findIndex((item) => item.id === activeId);
      const overIndex = list.findIndex((item) => item.id === overId);
      if (activeIndex === -1 || overIndex === -1 || activeIndex === overIndex)
        return prev;
      const newDocuments = arrayMove(list, activeIndex, overIndex);
      const reorderedDocuments = newDocuments.map((doc, index) => ({
        ...doc,
        id: index + 1,
      }));
      return { ...prev, documents: reorderedDocuments };
    });
  };

  const handleOpenModal = (
    section: "documents",
    theoryDocument?: ITheoryDocument
  ) => {
    setModalOpen({ section, theoryDocument });
  };

  const handleSaveDocumentAndTheory = async (documentData: ITheoryDocument) => {
    try {
      setSaving(true);
      let updatedTheory;
      if (modalOpen.theoryDocument) {
        const existing = currentTheory.documents || [];
        const updatedList = existing.map((doc) =>
          doc.id === documentData.id ? documentData : doc
        );
        updatedTheory = { ...currentTheory, documents: updatedList };
      } else {
        const existing = currentTheory.documents || [];
        updatedTheory = {
          ...currentTheory,
          documents: [...existing, documentData],
        };
        setNextDocId(nextDocId + 1);
      }
      setCurrentTheory(updatedTheory);
      const payload: LearningItemPayload = {
        keypointId: updatedTheory.keypointId,
        title: (cleanTranslation(updatedTheory.title) || "") as string,
        type: LearningItemType.THEORY,
        image: updatedTheory.image,
        tag: updatedTheory.tag || [],
        isSub: updatedTheory.isSub,
        documents: convertDocumentsToPayload(updatedTheory.documents), // Sử dụng hàm helper
        index: updatedTheory.index,
      };
      if (updatedTheory._id) {
        await learningItemService.update(updatedTheory._id, payload);
      } else {
        const res = await learningItemService.create(payload);
        const savedTheory = res.data?.data ?? res.data;
        setCurrentTheory(savedTheory);
        onSave?.(savedTheory);
      }
      showSuccess("Document saved successfully");
      setModalOpen({ section: null });
    } catch (err) {
      console.error("handleSaveDocumentAndTheory", err);
      showError(
        (err as any).response?.data?.message || "Failed to save document"
      );
    } finally {
      setSaving(false);
    }
  };

  const requestDeleteItem = (
    section: "documents",
    itemId: number,
    itemTitle = "document"
  ) => {
    setConfirmDeleteDocument({ section, itemId, itemTitle });
  };

  const confirmDeleteItem = async () => {
    if (!confirmDeleteDocument) return;
    const { section, itemId } = confirmDeleteDocument;
    if (!section || !itemId) {
      setConfirmDeleteDocument(null);
      return;
    }
    const updatedTheory = (() => {
      if (!currentTheory) return currentTheory;
      const newList = (currentTheory[section] || []).filter(
        (doc) => doc.id !== itemId
      );
      return { ...currentTheory, [section]: newList };
    })();
    setCurrentTheory(updatedTheory);
    try {
      setSaving(true);
      const payload: LearningItemPayload = {
        keypointId: updatedTheory.keypointId,
        title: updatedTheory.title?.[lang] || "",
        type: LearningItemType.THEORY,
        image: updatedTheory.image,
        tag: updatedTheory.tag || [],
        isSub: updatedTheory.isSub,
        documents: convertDocumentsToPayload(updatedTheory.documents),
        index: updatedTheory.index,
      };
      if (updatedTheory._id) {
        await learningItemService.update(updatedTheory._id, payload);
        showSuccess("Document deleted successfully");
      }
    } catch (err) {
      console.error("confirmDeleteItem", err);
      showError((err as any).response?.data?.message || "Failed to detete");
    } finally {
      setSaving(false);
      setConfirmDeleteDocument(null);
    }
  };

  const handleDeleteTheory = async () => {
    if (!currentTheory._id) return;
    try {
      await learningItemService.remove(currentTheory._id);
      setConfirmDeleteTheory(false);
      if (onCancel) {
        onCancel();
      } else {
        navigate("/theory");
      }
    } catch (err) {
      console.error(err);
    } finally {
      setConfirmDeleteTheory(false);
    }
  };

  const renderDocumentsSection = () => {
    const list = currentTheory.documents || [];
    return (
      <div className="mb-6 bg-gray-50 rounded-xl p-6 shadow-sm">
        <div className="flex justify-start gap-3 mb-4">
          <h2 className="text-xl font-semibold text-gray-800">Documents</h2>
        </div>
        <p className="text-sm text-gray-500 mb-4">
          👉 Drag to reorder. Click on item to edit.
        </p>
        <DndContext
          collisionDetection={closestCenter}
          onDragEnd={(event) => {
            const { active, over } = event;
            if (over && active.id !== over.id) {
              const activeId =
                typeof active.id === "string" ? parseInt(active.id) : active.id;
              const overId =
                typeof over.id === "string" ? parseInt(over.id) : over.id;
              handleReorder(activeId, overId);
            }
          }}
        >
          <SortableContext
            items={list.map((item) => item.id.toString())}
            strategy={verticalListSortingStrategy}
          >
            {list.length > 0 ? (
              <div className="space-y-3">
                {list.map((theoryDoc) => (
                  <SortableItem key={theoryDoc.id} id={theoryDoc.id.toString()}>
                    <motion.div
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
                    >
                      <div className="flex items-start gap-3">
                        <div className="flex-shrink-0 mt-1">
                          <PuzzlePieceIcon className="h-6 w-6 text-yellow-500" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center justify-between mb-2">
                            <h3 className="font-medium text-gray-800 truncate">
                              Document {theoryDoc.id}
                            </h3>
                            <div className="flex gap-1">
                              <button
                                onClick={() =>
                                  handleOpenModal("documents", theoryDoc)
                                }
                                className="text-blue-600 hover:text-blue-800 p-1 rounded"
                                title="Edit"
                              >
                                <svg
                                  xmlns="http://www.w3.org/2000/svg"
                                  className="h-5 w-5"
                                  viewBox="0 0 20 20"
                                  fill="currentColor"
                                >
                                  <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" />
                                </svg>
                              </button>
                              <button
                                onClick={() =>
                                  requestDeleteItem(
                                    "documents",
                                    theoryDoc.id,
                                    `Document ${theoryDoc.id}`
                                  )
                                }
                                className="text-red-500 hover:text-red-700 p-1 rounded"
                                title="Delete"
                              >
                                <TrashIcon className="h-5 w-5" />
                              </button>
                            </div>
                          </div>
                          <div className="text-sm text-gray-600 space-y-1">
                            {theoryDoc.speechBubble && (
                              <div className="flex items-start">
                                <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                  Speech Bubble:
                                </span>
                                <TextWithTooltip
                                  text={theoryDoc.speechBubble}
                                  lang={lang}
                                />
                              </div>
                            )}
                            {theoryDoc.tag && (
                              <div className="flex items-start">
                                <span className="font-medium text-blue-400 flex-shrink-0 mr-2">
                                  Tag:
                                </span>
                                <div className="flex items-center gap-1">
                                  {theoryDoc.tag.url && (
                                    <img
                                      src={theoryDoc.tag.url}
                                      alt={
                                        getTranslationValue(
                                          theoryDoc.tag.title,
                                          lang
                                        ) || "Tag url"
                                      }
                                      className="w-5 h-5 object-contain flex-shrink-0"
                                    />
                                  )}
                                  <span>
                                    {getTranslationValue(
                                      theoryDoc.tag.title,
                                      lang
                                    )}
                                  </span>
                                </div>
                              </div>
                            )}
                            {theoryDoc.document &&
                              theoryDoc.document.length > 0 && (
                                <div className="mt-2 p-2 bg-gray-50 rounded">
                                  <span className="font-medium text-gray-700">
                                    Content:
                                  </span>
                                  {theoryDoc.document.map((doc, index) => (
                                    <div
                                      key={index}
                                      className="ml-2 mt-1 text-xs"
                                    >
                                      <span className="font-semibold text-green-600">
                                        {doc.type.toUpperCase()}:
                                      </span>
                                      {isTextualDocumentType(doc.type) &&
                                        doc.data.content && (
                                          <div className="ml-1">
                                            <TextWithTooltip
                                              text={doc.data.content}
                                              maxLength={50}
                                              lang={lang}
                                            />
                                          </div>
                                        )}
                                      {doc.type === DocumentType.IMAGE &&
                                        getTranslationValue(
                                          doc.data.url,
                                          lang
                                        ) && (
                                          <div className="ml-1">
                                            <TextWithTooltip
                                              text={doc.data.url}
                                              maxLength={50}
                                              lang={lang}
                                            />
                                          </div>
                                        )}
                                      {doc.type === DocumentType.AUDIO &&
                                        getTranslationValue(
                                          doc.data.url,
                                          lang
                                        ) && (
                                          <div className="ml-1">
                                            <TextWithTooltip
                                              text={doc.data.url}
                                              maxLength={50}
                                              lang={lang}
                                            />
                                          </div>
                                        )}
                                      {doc.type === DocumentType.VIDEO && (
                                        <>
                                          {getTranslationValue(
                                            doc.data.url,
                                            lang
                                          ) && (
                                            <div className="ml-1">
                                              <TextWithTooltip
                                                text={doc.data.url}
                                                maxLength={50}
                                                lang={lang}
                                              />
                                            </div>
                                          )}
                                          {doc.data.thumbnail && (
                                            <div className="ml-1">
                                              <TextWithTooltip
                                                text={doc.data.thumbnail}
                                                maxLength={50}
                                              />
                                            </div>
                                          )}
                                        </>
                                      )}
                                    </div>
                                  ))}
                                </div>
                              )}
                          </div>
                        </div>
                      </div>
                    </motion.div>
                  </SortableItem>
                ))}
              </div>
            ) : null}
            <div className="text-center pt-5">
              <button
                className="text-blue-500 hover:text-blue-700 transition-colors"
                onClick={() => handleOpenModal("documents")}
              >
                <PlusCircleIcon className="h-8 w-8" />
              </button>
            </div>
          </SortableContext>
        </DndContext>
      </div>
    );
  };

  type DirectDocField = "type";
  type DataField = keyof IMediaDocument;
  type AllDocFields = DirectDocField | DataField;

  // Định nghĩa interface cho props
  interface DocumentContentEditorProps {
    doc: IDocument;
    index: number;
    onChange: (itemIndex: number, field: AllDocFields, value: string) => void;
    onRemove: (index: number) => void;
    availableTypes: DocumentType[];
    lang: LangCode;
  }

  // Document form component
  const DocumentForm = ({
    theoryDocument,
    onSave,
    onCancel,
    availableTags,
    lang,
  }: {
    theoryDocument?: ITheoryDocument;
    onSave: (doc: ITheoryDocument) => void;
    onCancel: () => void;
    availableTags: ITag[];
    lang: LangCode;
  }) => {
    const [formData, setFormData] = useState<DocumentFormState>(() => {
      if (theoryDocument) {
        return { ...theoryDocument };
      }
      return {
        id: nextDocId,
        speechBubble: { [lang]: "" },
        tag: null,
        document: [],
      };
    });

    const [tagQuery, setTagQuery] = useState("");
    const selectedTag = formData.tag;

    // Update formData when theoryDocument changes (for editing) or language changes
    useEffect(() => {
      if (theoryDocument) {
        setFormData({ ...theoryDocument });
      }
    }, [theoryDocument]);

    const renderDocumentFields = (doc: IDocument, index: number) => {
      if (isTextualDocumentType(doc.type)) {
        const label = getDocumentContentLabel(doc.type);
        const isLongForm = doc.type === DocumentType.TEXT;
        const placeholder =
          doc.type === DocumentType.TEXT
            ? "Enter content"
            : `Enter ${label.toLowerCase()}`;

        return (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {label}
            </label>
            {isLongForm ? (
              <textarea
                value={getCurrentTranslationValue(doc.data.content, lang)}
                onChange={(e) =>
                  handleDataChange(index, "content", e.target.value)
                }
                rows={3}
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                placeholder={placeholder}
              />
            ) : (
              <input
                type="text"
                value={getCurrentTranslationValue(doc.data.content, lang)}
                onChange={(e) =>
                  handleDataChange(index, "content", e.target.value)
                }
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                placeholder={placeholder}
              />
            )}
          </div>
        );
      }

      const mediaUrl = getCurrentTranslationValue(doc.data.url, lang) || "";

      if (doc.type === DocumentType.IMAGE) {
        return (
          <div className="w-52">
            <CloudflareFileUpload
              initialUrl={mediaUrl}
              onUrlChange={(newUrl) => handleDataChange(index, "url", newUrl)}
              label="Image URL"
              uploadPayload={{
                prefix: "",
                folder: "theories",
              }}
            />
          </div>
        );
      }

      if (doc.type === DocumentType.AUDIO) {
        return (
          <div className="w-52">
            <CloudflareFileUpload
              initialUrl={mediaUrl}
              onUrlChange={(newUrl) => handleDataChange(index, "url", newUrl)}
              label="Audio URL"
              uploadPayload={{
                prefix: "",
                folder: "theories",
              }}
              accept="audio/*"
            />
          </div>
        );
      }

      if (doc.type === DocumentType.VIDEO) {
        return (
          <div className="flex flex-col gap-3">
            <div className="w-52">
              <CloudflareFileUpload
                initialUrl={mediaUrl}
                onUrlChange={(newUrl) => handleDataChange(index, "url", newUrl)}
                label="Video URL"
                uploadPayload={{
                  prefix: "",
                  folder: "theories",
                }}
              />
            </div>
            <div className="w-52">
              <CloudflareFileUpload
                initialUrl={doc.data.thumbnail || ""}
                onUrlChange={(newUrl) =>
                  handleDataChange(index, "thumbnail", newUrl)
                }
                label="Video Thumbnail"
                uploadPayload={{
                  prefix: "",
                  folder: "theories",
                }}
              />
            </div>
          </div>
        );
      }

      if (doc.type === DocumentType.ANIMATION) {
        return (
          <div className="w-52">
            <CloudflareFileUpload
              initialUrl={mediaUrl}
              onUrlChange={(newUrl) => handleDataChange(index, "url", newUrl)}
              label="Animation URL"
              uploadPayload={{
                prefix: "",
                folder: "theories",
              }}
            />
          </div>
        );
      }

      return null;
    };

    const handleChange = (field: keyof DocumentFormState, value: any) => {
      setFormData((prev) => ({ ...prev, [field]: value }));
    };
    const handleDocumentChange = (
      index: number,
      field: keyof IDocument,
      value: any
    ) => {
      setFormData((prev) => {
        const currentDocs = prev.document || [];
        const newDocuments = [...currentDocs];
        const updatedDoc = { ...newDocuments[index], [field]: value };
        if (field === "type") {
          updatedDoc.data = createEmptyMediaDocument(lang);
        }
        newDocuments[index] = updatedDoc;
        return { ...prev, document: newDocuments };
      });
    };
    const handleDataChange = (
      docIndex: number,
      field: keyof IMediaDocument,
      value: string | ITranslation
    ) => {
      setFormData((prev) => {
        const currentDocs = prev.document || [];
        const newDocuments = [...currentDocs];
        const currentDoc = newDocuments[docIndex];
        const targetFieldValue = currentDoc?.data?.[field];
        const shouldTranslate =
          (field === "content" || field === "url") && typeof value === "string";

        newDocuments[docIndex] = {
          ...currentDoc,
          data: {
            ...currentDoc.data,
            [field]: shouldTranslate
              ? updateTranslationValue(
                  (targetFieldValue as ITranslation) || {},
                  lang,
                  value
                )
              : value,
          },
        };
        return { ...prev, document: newDocuments };
      });
    };
    const addNewInnerDocument = () => {
      const currentMaxId = (formData.document || []).reduce(
        (max, doc) => Math.max(max, doc.id),
        0
      );
      const newId = currentMaxId + 1;
      setFormData((prev) => ({
        ...prev,
        document: [
          ...prev.document,
          {
            id: newId,
            type: DocumentType.TEXT,
            data: createEmptyMediaDocument(lang),
          },
        ],
      }));
    };
    const removeInnerDocument = (index: number) => {
      setFormData((prev) => ({
        ...prev,
        document: (prev.document || []).filter((_, i) => i !== index),
      }));
    };

    const handleSave = () => {
      // Clean speechBubble if empty
      const cleanedData: any = {
        ...formData,
        tag: selectedTag,
      };

      const cleanedSpeechBubble = cleanTranslation(formData.speechBubble);
      if (cleanedSpeechBubble) {
        cleanedData.speechBubble = cleanedSpeechBubble;
      } else {
        delete cleanedData.speechBubble;
      }

      const cleanedDocuments = formData.document?.length
        ? cleanDocumentItems(formData.document)
        : [];
      if (cleanedDocuments.length > 0) {
        cleanedData.document = cleanedDocuments;
      } else {
        cleanedData.document = [];
      }

      onSave(cleanedData);
    };

    const filteredTags =
      tagQuery === ""
        ? availableTags
        : availableTags.filter((tag) =>
            getTranslationValue(tag.title, lang)
              ?.toLowerCase()
              .includes(tagQuery.toLowerCase())
          );

    return (
      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Speech Bubble
          </label>
          <input
            type="text"
            value={getCurrentTranslationValue(formData.speechBubble, lang)}
            onChange={(e) =>
              handleChange(
                "speechBubble",
                updateTranslationValue(
                  formData.speechBubble || {},
                  lang,
                  e.target.value
                )
              )
            }
            className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
            placeholder="Enter speech bubble text"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Tag
          </label>
          <Combobox<ITag | null>
            key={`tag-selector-${lang}`} // Force re-render when language changes
            value={selectedTag}
            onChange={(val: ITag | null) => {
              handleChange("tag", val);
              setTagQuery("");
            }}
          >
            <div className="relative">
              <Combobox.Input
                displayValue={(tag: ITag | null) => {
                  if (tagQuery) return tagQuery;
                  return getTranslationValue(tag?.title, lang);
                }}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                  setTagQuery(e.target.value)
                }
                className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                placeholder="Search tag..."
              />
              <Combobox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                {filteredTags.length > 0 ? (
                  filteredTags.map((tag) => (
                    <Combobox.Option
                      key={tag._id}
                      value={tag}
                      className="cursor-pointer px-3 py-3 hover:bg-blue-50 flex items-center gap-2"
                    >
                      {tag.url && (
                        <img
                          src={tag.url}
                          alt={
                            getTranslationValue(tag.title, lang) || "Tag url"
                          }
                          className="w-6 h-6 object-contain flex-shrink-0"
                        />
                      )}
                      <span>{getTranslationValue(tag.title, lang)}</span>
                    </Combobox.Option>
                  ))
                ) : (
                  <div className="px-3 py-3 text-gray-500">No tags found.</div>
                )}
              </Combobox.Options>
            </div>
          </Combobox>
        </div>
        <div className="border-t pt-4">
          <div className="flex justify-between items-center mb-3">
            <h3 className="font-medium text-gray-800">Content Documents</h3>
          </div>
          {formData.document.map((doc, index) => (
            <div key={doc.id} className="border rounded-lg p-4 bg-gray-50 mb-3">
              <div className="flex justify-between items-center mb-3">
                <h4 className="font-medium text-sky-400">
                  Content {index + 1}
                </h4>
                <button
                  type="button"
                  onClick={() => removeInnerDocument(index)}
                  className="text-red-500 hover:text-red-700"
                >
                  <TrashIcon className="h-4 w-4" />
                </button>
              </div>
              <div className="space-y-3">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Type
                  </label>
                  <select
                    value={doc.type}
                    onChange={(e) =>
                      handleDocumentChange(
                        index,
                        "type",
                        e.target.value as DocumentType
                      )
                    }
                    className="border rounded-lg w-full p-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
                  >
                    <option value={DocumentType.TITLE}>Title</option>
                    <option value={DocumentType.CAPTION}>Caption</option>
                    <option value={DocumentType.TEXT}>Text</option>
                    <option value={DocumentType.IMAGE}>Image</option>
                    <option value={DocumentType.VIDEO}>Video</option>
                    <option value={DocumentType.AUDIO}>Audio</option>
                    <option value={DocumentType.ANIMATION}>Animation</option>
                  </select>
                </div>
                {renderDocumentFields(doc, index)}
              </div>
            </div>
          ))}

          <div className="text-center">
            <button
              type="button"
              onClick={addNewInnerDocument}
              className="px-3 py-1 bg-blue-600 text-white rounded-md text-sm hover:bg-blue-700"
            >
              Add Content
            </button>
          </div>
        </div>
        <div className="flex justify-end gap-2 mt-6">
          <button
            className="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 transition"
            onClick={onCancel}
          >
            Cancel
          </button>
          <button
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
            onClick={handleSave}
            disabled={saving}
          >
            {saving ? (
              <>Saving...</>
            ) : theoryDocument ? (
              "Update Document"
            ) : (
              "Add Document"
            )}
          </button>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <div className="max-w-7xl mx-auto">
        <div className="bg-white shadow-xl rounded-xl overflow-hidden flex flex-col md:flex-row">
          <div className="flex-1 flex flex-col items-center p-6 bg-gray-50">
            <div className="w-full max-w-md">
              {currentTheory.image ? (
                <img
                  src={currentTheory.image}
                  alt={currentTheory.title?.[lang]}
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
            <div className="mt-6 w-full max-w-md">
              <label className="block mb-2 text-sm font-medium text-gray-700">
                Image URL
              </label>
              <input
                value={currentTheory.image || ""}
                onChange={(e) =>
                  setCurrentTheory((prev) => ({
                    ...prev,
                    image: e.target.value,
                  }))
                }
                className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                placeholder="Paste image link..."
              />
            </div>
          </div>
          <div className="flex-[1.5] p-6">
            <div className="flex justify-between items-center mb-6">
              <h1 className="text-2xl md:text-3xl font-bold text-gray-800">
                {isEditMode ? "✏️ Edit Theory" : "🌱 Create New Theory"}
              </h1>
            </div>
            <div className="space-y-6">
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Title *
                </label>
                <input
                  value={currentTheory.title[lang] || ""}
                  onChange={(e) =>
                    setCurrentTheory((prev) => ({
                      ...prev,
                      title: { ...prev.title, [lang]: e.target.value },
                    }))
                  }
                  className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                  placeholder="Theory title..."
                  required
                />
              </div>
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Keypoint *
                </label>
                <Combobox<string | null>
                  value={currentTheory.keypointId || null}
                  onChange={(val: string | null) => {
                    setCurrentTheory((prev) =>
                      prev ? { ...prev, keypointId: val ?? "" } : prev
                    );
                    setKeypointQuery("");
                  }}
                >
                  <div className="relative">
                    <Combobox.Input
                      displayValue={(val: string | null) => {
                        if (selectedKeypoint) {
                          return selectedKeypoint.title?.[lang] || "";
                        }
                        return keypointQuery;
                      }}
                      onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                        setKeypointQuery(e.target.value)
                      }
                      className="border rounded-lg w-full p-3 focus:outline-none focus:ring-2 focus:ring-blue-400 transition"
                      placeholder="Search course..."
                    />
                    <Combobox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                      {keypoints
                        .filter((k) =>
                          k.title?.[lang]
                            ?.toLowerCase()
                            .includes(keypointQuery.toLowerCase())
                        )
                        .map((c) => (
                          <Combobox.Option
                            key={c._id}
                            value={c._id}
                            className="cursor-pointer px-3 py-3 hover:bg-blue-50"
                          >
                            {c.title?.[lang]}
                          </Combobox.Option>
                        ))}
                    </Combobox.Options>
                  </div>
                </Combobox>
              </div>
              <div>
                <label className="block mb-1 text-sm font-medium text-gray-700">
                  Tags
                </label>
                <div className="flex flex-wrap gap-2 mb-2">
                  {currentTheory.tag?.map((tag, index) => (
                    <div
                      key={index}
                      className="flex items-center bg-indigo-100 rounded-md"
                    >
                      <input
                        type="text"
                        value={tag}
                        onChange={(e) => {
                          const newTags = [...(currentTheory.tag || [])];
                          newTags[index] = e.target.value;
                          setCurrentTheory({ ...currentTheory, tag: newTags });
                        }}
                        className="px-3 py-1 bg-transparent border-0 focus:ring-0 text-sm"
                        placeholder="Enter tag"
                      />
                      <button
                        type="button"
                        onClick={() => {
                          const newTags = (currentTheory.tag || []).filter(
                            (_, i) => i !== index
                          );
                          setCurrentTheory({ ...currentTheory, tag: newTags });
                        }}
                        className="text-red-600 hover:text-red-800 px-2 py-1"
                      >
                        <svg
                          className="w-4 h-4"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                          xmlns="http://www.w3.org/2000/svg"
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth="2"
                            d="M6 18L18 6M6 6l12 12"
                          ></path>
                        </svg>
                      </button>
                    </div>
                  ))}
                </div>
                <button
                  type="button"
                  onClick={() =>
                    setCurrentTheory({
                      ...currentTheory,
                      tag: [...(currentTheory.tag || []), ""],
                    })
                  }
                  className="inline-flex items-center px-3 py-1 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  <svg
                    className="w-4 h-4 mr-1"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                      d="M12 4v16m8-8H4"
                    ></path>
                  </svg>
                  Add Tag
                </button>
              </div>
            </div>
            <div className="flex pt-8 gap-2 justify-end">
              <button
                onClick={handleSaveTheory}
                disabled={saving}
                className={`flex items-center justify-center gap-2 px-6 py-3 rounded-lg text-white font-semibold shadow transition ${
                  saving
                    ? "bg-gray-400 cursor-not-allowed"
                    : "bg-gradient-to-r from-blue-600 to-green-500 hover:opacity-90"
                }`}
              >
                {saving ? (
                  <>Saving...</>
                ) : isEditMode ? (
                  "Save Theory"
                ) : (
                  "Create Theory"
                )}
              </button>
            </div>
          </div>
        </div>
        {currentTheory._id ? (
          <div className="mt-8">{renderDocumentsSection()}</div>
        ) : null}
        {currentTheory._id && (
          <div className="flex justify-center mt-8">
            <button
              onClick={() => setConfirmDeleteTheory(true)}
              className="px-6 py-3 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg shadow hover:from-red-700 hover:to-red-800 transition-all flex items-center gap-2"
            >
              <TrashIcon className="h-5 w-5" />
              Delete Theory
            </button>
          </div>
        )}
        <AnimatePresence>
          {confirmDeleteTheory && (
            <LearningItemConfirm
              title="Confirm Delete"
              message="Are you sure you want to delete this theory? This action cannot be undone."
              onCancel={() => setConfirmDeleteTheory(false)}
              onConfirm={handleDeleteTheory}
            />
          )}
        </AnimatePresence>
        <AnimatePresence>
          {modalOpen.section && (
            <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-[9999]">
              <motion.div
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9 }}
                className="bg-white w-[600px] rounded-xl shadow-xl flex flex-col"
                style={{ maxHeight: "90vh" }}
              >
                <div className="p-6 pt-6 border-b border-gray-200 flex justify-between items-center">
                  <h2 className="text-xl font-bold">
                    {modalOpen.theoryDocument
                      ? "Edit Document"
                      : "New Document"}
                  </h2>
                  <button
                    onClick={() => setModalOpen({ section: null })}
                    className="text-gray-500 hover:text-gray-700 p-1 rounded-full transition-colors"
                  >
                    <XMarkIcon className="h-6 w-6" />
                  </button>
                </div>
                <div className="flex-grow overflow-y-auto p-6">
                  <DocumentForm
                    theoryDocument={modalOpen.theoryDocument}
                    onSave={handleSaveDocumentAndTheory}
                    onCancel={() => setModalOpen({ section: null })}
                    availableTags={allTags}
                    lang={lang}
                  />
                </div>
              </motion.div>
            </div>
          )}
        </AnimatePresence>
        <AnimatePresence>
          {confirmDeleteDocument && (
            <LearningItemConfirm
              title="Confirm Delete"
              message={`Are you sure you want to delete "${confirmDeleteDocument.itemTitle}"?`}
              onCancel={() => setConfirmDeleteDocument(null)}
              onConfirm={() => confirmDeleteItem()}
            />
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
