// src/components/categories/CategoryModal.tsx
import React, { useEffect, useState } from "react";
import { XMarkIcon, ArrowPathIcon } from "@heroicons/react/24/outline";
import {
  ICategory,
  CategoryPayload,
} from "../../types/interface/category.interface";
import {
  CategoryOnboardingIntroduce,
  CategoryStatus,
} from "../../types/enum/category.enum";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { motion, AnimatePresence } from "framer-motion";
import CloudflareFileUpload from "../files/CloudflareFileUpload";
import { ITranslation } from "../../utils/translate";
import { updateTranslationValue, cleanTranslation } from "../../utils/translation";

interface Props {
  isOpen: boolean;
  initial?: ICategory | null;
  onClose: () => void;
  onSubmit: (payload: CategoryPayload, id?: string) => Promise<void>;
  loading?: boolean;
  error?: string | null;
}

export default function CategoryModal({
  isOpen,
  initial = null,
  onClose,
  onSubmit,
  loading = false,
  error = null,
}: Props) {
  const onboardingIntroduceOptions = Object.values(
    CategoryOnboardingIntroduce
  );
  const lang = useSelector((state: RootState) => state.lang.code);

  const [title, setTitle] = useState<ITranslation>({});
  const [description, setDescription] = useState<ITranslation>({});
  const [titleError, setTitleError] = useState("");
  const [image, setImage] = useState("");
  const [status, setStatus] = useState<CategoryStatus>(CategoryStatus.DRAFT);
  const [onboardingIntroduce, setOnboardingIntroduce] = useState<
    CategoryOnboardingIntroduce | ""
  >("");
  const [indexValue, setIndexValue] = useState("");

  useEffect(() => {
    if (isOpen) {
      if (initial) {
        setTitleError("");
        setTitle(initial.title ?? {});
        setDescription(initial.description ?? {});
        setImage(initial.image ?? "");
        setStatus(initial.status ?? CategoryStatus.DRAFT);
        setOnboardingIntroduce(initial.onboardingIntroduce ?? "");
        setIndexValue(
          initial.index !== undefined && initial.index !== null
            ? String(initial.index)
            : ""
        );
      } else {
        setTitleError("");
        setTitle({});
        setDescription({});
        setImage("");
        setStatus(CategoryStatus.DRAFT);
        setOnboardingIntroduce("");
        setIndexValue("");
      }
    }
  }, [initial, isOpen]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Update and clean translations
    const cleanedTitle = cleanTranslation(
      updateTranslationValue(title, lang, title[lang] || "")
    );
    const cleanedDescription = cleanTranslation(
      updateTranslationValue(description, lang, description[lang] || "")
    );

    if (!cleanedTitle) {
      setTitleError("Title is required");
      return;
    }
    setTitleError("");

    // Create CategoryPayload with cleaned translations
    const trimmedIndex = indexValue.trim();
    const parsedIndex =
      trimmedIndex === "" ? undefined : Number(trimmedIndex);
    const payload: CategoryPayload = {
      title: cleanedTitle,
      ...(cleanedDescription && { description: cleanedDescription }),
      image,
      status,
      onboardingIntroduce: onboardingIntroduce || null,
      ...(trimmedIndex !== "" &&
        !Number.isNaN(parsedIndex) && { index: parsedIndex }),
    };

    await onSubmit(payload, initial?._id);
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.95 }}
          transition={{ duration: 0.2 }}
          className="bg-white rounded-xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col"
        >
          {/* Header */}
          <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <h3 className="text-xl font-semibold text-gray-900">
              {initial && initial._id ? "Edit Category" : "Create New Category"}
            </h3>
            <button
              onClick={onClose}
              className="p-2 rounded-full hover:bg-gray-100 transition-colors"
            >
              <XMarkIcon className="h-5 w-5 text-gray-500" />
            </button>
          </div>

          <form
            onSubmit={handleSubmit}
            className="flex-grow overflow-y-auto p-6"
          >
            {(error || titleError) && (
              <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-lg text-sm">
                {titleError || error}
              </div>
            )}

            <div className="space-y-6">
              {/* Title */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Title *
                </label>
                <input
                  value={title[lang] || ""}
                  onChange={(e) => {
                    setTitle((prev) =>
                      updateTranslationValue(prev, lang, e.target.value)
                    );
                    setTitleError("");
                  }}
                  className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-brand-500 focus:border-brand-500 transition"
                />
              </div>

              {/* Description */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Description
                </label>
                <textarea
                  value={description[lang] || ""}
                  onChange={(e) =>
                    setDescription((prev) => updateTranslationValue(prev, lang, e.target.value))
                  }
                  className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-brand-500 focus:border-brand-500 transition"
                  rows={4}
                />
              </div>

              {/* Status */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Status *
                </label>
                <select
                  value={status}
                  onChange={(e) => setStatus(e.target.value as CategoryStatus)}
                  className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-brand-500 focus:border-brand-500 transition"
                  required
                >
                  <option value={CategoryStatus.DRAFT}>Draft</option>
                  <option value={CategoryStatus.PUBLISHED}>Published</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Onboarding Introduce
                </label>
                <div className="flex items-center gap-3">
                  <select
                    value={onboardingIntroduce}
                    onChange={(e) =>
                      setOnboardingIntroduce(
                        e.target.value as CategoryOnboardingIntroduce | ""
                      )
                    }
                    className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-brand-500 focus:border-brand-500 transition"
                  >
                    <option value="" disabled>
                      Select onboarding introduce
                    </option>
                    {onboardingIntroduceOptions.map((option) => (
                      <option key={option} value={option}>
                        {option}
                      </option>
                    ))}
                  </select>
                  <button
                    type="button"
                    onClick={() => setOnboardingIntroduce("")}
                    disabled={!onboardingIntroduce}
                    className="shrink-0 rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium text-gray-600 transition hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    Clear
                  </button>
                </div>
              </div>

              {/* Index */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Index
                </label>
                <input
                  type="number"
                  min={0}
                  step={1}
                  value={indexValue}
                  onChange={(e) => setIndexValue(e.target.value)}
                  className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-brand-500 focus:border-brand-500 transition"
                  placeholder="Optional"
                />
              </div>

              {/* Image */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Image URL
                </label>
                <CloudflareFileUpload
                  initialUrl={image || ""}
                  onUrlChange={(url) => setImage(url)}
                  label=""
                  // Bạn có thể tùy chỉnh payload này theo nhu cầu
                  uploadPayload={{
                    prefix: "",
                    folder: "categories",
                  }}
                />
              </div>
            </div>

            {/* Actions */}
            <div className="mt-8 flex justify-end gap-3 pt-4 border-t border-gray-200">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="px-4 py-2 bg-gradient-to-r from-brand-600 to-bronze-600 text-white rounded-lg hover:from-brand-700 hover:to-bronze-700 transition-all flex items-center gap-2 disabled:opacity-70"
              >
                {loading ? (
                  <>
                    <ArrowPathIcon className="h-4 w-4 animate-spin" />
                    <span>Saving...</span>
                  </>
                ) : initial ? (
                  <span>Save Changes</span>
                ) : (
                  <span>Create Category</span>
                )}
              </button>
            </div>
          </form>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
