// src/components/courses/CourseModal.tsx
import React, { useEffect, useState } from "react";
import {
  ArrowPathIcon,
  XMarkIcon,
  PlusIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";
import {
  ICourse,
  IPrice,
  CoursePayload,
} from "../../types/interface/course.interface";
import { OnboardingSymptom } from "../../types/enum/common.enum";
import { CourseStatus } from "../../types/enum/course.enum";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { motion, AnimatePresence } from "framer-motion";
import { ISkillset } from "../../types/interface/skillset.interface";
import { skillsetService } from "../../services/skillsetService";
import { onboardingConfigService } from "../../services/onboardingConfigService";
import CloudflareFileUpload from "../files/CloudflareFileUpload";
import { ITranslation } from "../../utils/translate";
import { cleanTranslation, getTranslationValue } from "../../utils/translation";

interface Props {
  isOpen: boolean;
  initial?: ICourse | null;
  onClose: () => void;
  onSubmit: (payload: Partial<CoursePayload>, id?: string) => Promise<void>;
  loading?: boolean;
  error?: string | null;
}

// ISO 8601 → "YYYY-MM-DDTHH:mm" (local time) for <input type="datetime-local">.
function isoToLocalInput(iso?: string | null): string {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(
    d.getHours()
  )}:${pad(d.getMinutes())}`;
}

export default function CourseModal({
  isOpen,
  initial = null,
  onClose,
  onSubmit,
  loading = false,
  error = null,
}: Props) {
  const lang = useSelector((state: RootState) => state.lang.code);

  const [title, setTitle] = useState<ITranslation>({});
  const [description, setDescription] = useState<ITranslation>({});
  const [titleError, setTitleError] = useState("");
  const [image, setImage] = useState("");
  const [status, setStatus] = useState<CourseStatus>(CourseStatus.DRAFT);
  // datetime-local value ("YYYY-MM-DDTHH:mm"); only used when status = Coming Soon.
  const [publishAt, setPublishAt] = useState("");
  // Days the "New course" badge lasts after publish (Coming Soon flow).
  const [newDurationDays, setNewDurationDays] = useState("");
  // Manual override to force the "New course" badge regardless of publish date.
  const [isNew, setIsNew] = useState(false);
  // Kept as strings so an empty input stays empty rather than collapsing to 0.
  const [author, setAuthor] = useState("");
  const [viewCount, setViewCount] = useState("");
  const [prices, setPrices] = useState<IPrice[]>([]);
  const [onboardingSymptoms, setOnboardingSymptoms] = useState<
    OnboardingSymptom[]
  >([]);
  // Real symptom sentences (from the onboarding config, keyed by the
  // OnboardingSymptom enum value) so the checkboxes below read as the actual
  // symptom the user picks — not the raw title-cased key.
  const [symptomLabels, setSymptomLabels] = useState<Record<string, string>>(
    {}
  );

  // State cho Skillset
  const [skillsetId, setSkillsetId] = useState("");
  const [skillsetQuery, setSkillsetQuery] = useState("");
  const [debouncedQuery, setDebouncedQuery] = useState("");
  const [skillsets, setSkillsets] = useState<ISkillset[]>([]);
  const [loadingSkillsets, setLoadingSkillsets] = useState(false);
  const [showSkillsetDropdown, setShowSkillsetDropdown] = useState(false);
  const [selectedSkillsetLabel, setSelectedSkillsetLabel] = useState("");

  // Effect để reset form khi modal mở/đóng hoặc thay đổi initial
  useEffect(() => {
    if (!isOpen) return;
    if (initial) {
      setTitleError("");
      setTitle(initial.title ?? {});
      setDescription(initial.description ?? {});
      setImage(initial.image ?? "");
      setStatus(initial.status);
      setPublishAt(isoToLocalInput(initial.publishAt));
      setNewDurationDays(
        initial.newDurationDays != null ? String(initial.newDurationDays) : ""
      );
      setIsNew(initial.isNew ?? false);
      setAuthor(initial.author ?? "");
      setViewCount(initial.viewCount != null ? String(initial.viewCount) : "");
      setPrices(initial.prices ?? []);
      setOnboardingSymptoms(initial.onboardingSymptoms ?? []);
      setSkillsetId(initial.skillsetId ?? "");
      setSelectedSkillsetLabel("");
    } else {
      setTitleError("");
      setTitle({});
      setDescription({});
      setImage("");
      setStatus(CourseStatus.DRAFT);
      setPublishAt("");
      setNewDurationDays("");
      setIsNew(false);
      setAuthor("");
      setViewCount("");
      setPrices([]);
      setOnboardingSymptoms([]);
      setSkillsetId("");
      setSkillsetQuery("");
      setSelectedSkillsetLabel("");
    }

    setDebouncedQuery("");
  }, [initial, isOpen]);

  // Load the onboarding config once the modal opens to show the REAL symptom
  // sentences on the "Onboarding Symptoms" checkboxes (tagging a course reads as
  // "recommend this course when the user picks <symptom>" — matching the app and
  // how the recommendation, `onboardingSymptoms $in picked`, actually works).
  // Falls back to the title-cased key when a symptom isn't in the config.
  useEffect(() => {
    if (!isOpen) return;
    let cancelled = false;
    (async () => {
      try {
        const config = await onboardingConfigService.getConfig();
        const map: Record<string, string> = {};
        for (const path of config?.paths?.items ?? []) {
          for (const symptom of path.symptoms ?? []) {
            const label = getTranslationValue(symptom.label, lang);
            if (symptom.key && label) map[symptom.key] = label;
          }
        }
        if (!cancelled) setSymptomLabels(map);
      } catch {
        // Ignore — the checkboxes fall back to the key-derived label.
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [isOpen, lang]);

  useEffect(() => {
    if (!isOpen) return;
    if (!skillsetId) {
      setSelectedSkillsetLabel("");
      return;
    }
    const selectedSkillset = skillsets.find((s) => s._id === skillsetId);
    if (!selectedSkillset) return;
    const label = getTranslationValue(selectedSkillset.title, lang);
    setSelectedSkillsetLabel((prev) => (prev === label ? prev : label));
  }, [skillsetId, skillsets, lang, isOpen]);

  // Effect để debounce search query
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedQuery(skillsetQuery);
    }, 300); // Chờ 300ms sau khi người dùng ngừng gõ

    return () => {
      clearTimeout(timer); // Dọn dẹp timer cũ
    };
  }, [skillsetQuery]);

  // Effect để gọi API khi debouncedQuery thay đổi hoặc modal mở
  useEffect(() => {
    if (isOpen) {
      const fetchSkillsets = async () => {
        setLoadingSkillsets(true);
        try {
          // GỌI API THẬT TRỰC TIẾP
          // Giả sử hàm getlist nhận vào object { search: query }
          const response = await skillsetService.getList({
            search: debouncedQuery,
            isAll: true,
          });
          setSkillsets(response.data.items || []); // Giả sử API trả về { data: [...] }
        } catch (err) {
          console.error("Failed to fetch skillsets:", err);
          setSkillsets([]); // Xóa kết quả cũ nếu có lỗi
        } finally {
          setLoadingSkillsets(false);
        }
      };
      fetchSkillsets();
    }
  }, [debouncedQuery, isOpen]); // Chạy lại khi query hoặc trạng thái mở modal thay đổi

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Clean translation values to remove empty strings
    const cleanedTitle = cleanTranslation(title);
    const cleanedDescription = cleanTranslation(description);

    if (!cleanedTitle) {
      setTitleError("Title is required");
      return;
    }
    setTitleError("");

    // Create CoursePayload with cleaned translations
    const payload: Partial<CoursePayload> = {
      title: cleanedTitle,
      image,
      status,
      prices: prices,
      skillsetId, // Add skillsetId to payload
      onboardingSymptoms,
      // Publish time + New-course duration only apply to Coming Soon.
      publishAt:
        status === CourseStatus.COMING_SOON && publishAt
          ? new Date(publishAt).toISOString()
          : null,
      newDurationDays:
        status === CourseStatus.COMING_SOON && newDurationDays
          ? Number(newDurationDays)
          : null,
      // Manual "New course" override (independent of publish date).
      isNew,
      // Editorial credit + reach for the app's "New today" card. Empty stays
      // null (not "" / 0) so the app hides each half rather than crediting
      // nobody or claiming zero reach.
      author: author.trim() || null,
      viewCount: viewCount.trim() ? Number(viewCount) : null,
    };

    // Only include description if it has values
    if (cleanedDescription) {
      payload.description = cleanedDescription;
    }

    await onSubmit(payload, initial?._id);
  };

  const handleAddPrice = () => {
    setPrices((prev) => [
      ...prev,
      {
        currency: "USD",
        originalPrice: 0,
        salePrice: undefined,
        isFree: false,
      },
    ]);
  };

  const handleRemovePrice = (index: number) => {
    setPrices((prev) => prev.filter((_, i) => i !== index));
  };

  const handlePriceChange = (index: number, key: keyof IPrice, value: any) => {
    setPrices((prev) =>
      prev.map((p, i) =>
        i === index
          ? {
              ...p,
              [key]:
                key === "isFree"
                  ? value
                  : key.includes("Price")
                  ? Number(value)
                  : value,
            }
          : p
      )
    );
  };

  const handleSelectSkillset = (skillset: ISkillset) => {
    setSkillsetId(skillset._id);
    setSelectedSkillsetLabel(getTranslationValue(skillset.title, lang));
    setSkillsetQuery("");
    setShowSkillsetDropdown(false);
  };

  const handleClearSkillset = () => {
    setSkillsetId("");
    setSkillsetQuery("");
    setSelectedSkillsetLabel("");
    setShowSkillsetDropdown(true);
  };

  const formatOnboardingSymptomLabel = (value: OnboardingSymptom) =>
    value
      .toLowerCase()
      .split("_")
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(" ");

  const handleToggleOnboardingSymptom = (value: OnboardingSymptom) => {
    setOnboardingSymptoms((prev) =>
      prev.includes(value)
        ? prev.filter((symptom) => symptom !== value)
        : [...prev, value]
    );
  };

  const handleSkillsetInputChange = (
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    const value = e.target.value;
    setSkillsetQuery(value);

    // Nếu người dùng xóa hết nội dung, xóa cả skillsetId
    if (!value.trim()) {
      setSkillsetId("");
      setSelectedSkillsetLabel("");
    }

    // Hiển thị dropdown khi người dùng bắt đầu gõ
    if (!showSkillsetDropdown) {
      setShowSkillsetDropdown(true);
    }
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.95 }}
          transition={{ duration: 0.2 }}
          className="bg-white rounded-xl shadow-2xl w-full max-w-3xl max-h-[90vh] overflow-hidden flex flex-col"
        >
          {/* Header */}
          <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <h3 className="text-xl font-semibold text-gray-900">
              {initial && initial._id ? "Edit Course" : "Create New Course"}
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
                    setTitle((prev) => ({ ...prev, [lang]: e.target.value }));
                    setTitleError("");
                  }}
                  className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition"
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
                    setDescription((prev) => ({
                      ...prev,
                      [lang]: e.target.value,
                    }))
                  }
                  className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition"
                  rows={4}
                />
              </div>

              {/* Skillset Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Skillset *
                </label>
                <div className="relative">
                  <input
                    type="text"
                    value={skillsetQuery || selectedSkillsetLabel}
                    onChange={handleSkillsetInputChange}
                    onFocus={() => setShowSkillsetDropdown(true)}
                    placeholder="Search for a skillset..."
                    className="w-full border border-gray-300 rounded-lg px-4 py-2 pr-10 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition"
                    required
                  />
                  {skillsetId && (
                    <button
                      type="button"
                      onClick={handleClearSkillset}
                      className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                    >
                      <XMarkIcon className="h-5 w-5" />
                    </button>
                  )}
                  {loadingSkillsets && !skillsetId && (
                    <div className="absolute right-3 top-1/2 transform -translate-y-1/2">
                      <ArrowPathIcon className="h-4 w-4 animate-spin text-gray-400" />
                    </div>
                  )}

                  {showSkillsetDropdown && (
                    <div className="absolute z-10 mt-1 w-full bg-white border border-gray-200 rounded-lg shadow-lg max-h-60 overflow-y-auto">
                      {skillsets.length === 0 && !loadingSkillsets ? (
                        <div className="p-3 text-gray-500 text-sm">
                          No skillsets found
                        </div>
                      ) : (
                        skillsets.map((skillset) => (
                          <div
                            key={skillset._id}
                            onClick={() => handleSelectSkillset(skillset)}
                            className="px-4 py-2 hover:bg-gray-100 cursor-pointer text-sm font-bold"
                          >
                            {getTranslationValue(skillset.title, lang) ||
                              "Unnamed Skillset"}
                          </div>
                        ))
                      )}
                    </div>
                  )}
                </div>
              </div>

              {/* Image */}
              <div className="w-52 h-auto">
                <CloudflareFileUpload
                  initialUrl={image}
                  onUrlChange={setImage}
                  label="Course Image"
                  // Bạn có thể tùy chỉnh payload này theo nhu cầu
                  uploadPayload={{
                    prefix: "",
                    folder: "courses",
                  }}
                  disabled={loading}
                />
              </div>

              {/* Status */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Status
                </label>
                <div className="relative">
                  <select
                    value={status}
                    onChange={(e) => setStatus(e.target.value as CourseStatus)}
                    className="w-full border border-gray-300 rounded-lg px-4 py-2 pr-10 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition appearance-none bg-white"
                  >
                    <option value={CourseStatus.PUBLISHED}>Published</option>
                    <option value={CourseStatus.DRAFT}>Draft</option>
                    <option value={CourseStatus.COMING_SOON}>Coming Soon</option>
                  </select>
                  <div className="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
                    <svg
                      className="w-5 h-5 text-gray-400"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M19 9l-7 7-7-7"
                      />
                    </svg>
                  </div>
                </div>
              </div>

              {/* Publish time — only for Coming Soon courses */}
              {status === CourseStatus.COMING_SOON && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Publish time
                  </label>
                  <input
                    type="datetime-local"
                    value={publishAt}
                    onChange={(e) => setPublishAt(e.target.value)}
                    className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition bg-white"
                  />
                  <p className="mt-1 text-xs text-gray-500">
                    When this course should become available. Leave empty for no
                    scheduled date.
                  </p>

                  <label className="block text-sm font-medium text-gray-700 mb-1 mt-4">
                    New course duration (days)
                  </label>
                  <input
                    type="number"
                    min={1}
                    value={newDurationDays}
                    onChange={(e) => setNewDurationDays(e.target.value)}
                    placeholder="e.g. 7"
                    className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition bg-white"
                  />
                  <p className="mt-1 text-xs text-gray-500">
                    After publishing, show the “New course” badge for this many
                    days. Leave empty to skip the New-course phase.
                  </p>
                </div>
              )}

              {/* Manual "New course" toggle — forces the New badge regardless
                  of publish date / duration. */}
              <div>
                <label className="flex items-start gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={isNew}
                    onChange={(e) => setIsNew(e.target.checked)}
                    className="mt-0.5 h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span>
                    <span className="block text-sm font-medium text-gray-700">
                      Mark as “New course”
                    </span>
                    <span className="mt-1 block text-xs text-gray-500">
                      Forces the “New course” badge immediately, regardless of
                      publish date or duration. Turn off to remove it. (Has no
                      effect while the course is still Coming Soon.)
                    </span>
                  </span>
                </label>
              </div>

              {/* Author + reach for the app's "New today" card on Home. Both
                  optional: each half is hidden in the app when left empty. */}
              <div className="rounded-lg border border-gray-200 p-4">
                <p className="text-sm font-semibold text-gray-700">
                  “New today” card (Home)
                </p>
                <p className="mt-1 text-xs text-gray-500">
                  Shown under the course title on the app's Home screen. Leave a
                  field empty to hide just that half.
                </p>

                <label className="block text-sm font-medium text-gray-700 mb-1 mt-4">
                  Author
                </label>
                <input
                  type="text"
                  maxLength={120}
                  value={author}
                  onChange={(e) => setAuthor(e.target.value)}
                  placeholder="e.g. Sara Kim"
                  className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition bg-white"
                />
                <p className="mt-1 text-xs text-gray-500">
                  Not translated — the same name shows in every language.
                </p>

                <label className="block text-sm font-medium text-gray-700 mb-1 mt-4">
                  View count
                </label>
                <input
                  type="number"
                  min={0}
                  value={viewCount}
                  onChange={(e) => setViewCount(e.target.value)}
                  placeholder="e.g. 6300"
                  className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition bg-white"
                />
                <p className="mt-1 text-xs text-gray-500">
                  Enter the raw number — the app shortens 6300 to “6.3k”. This is
                  a curated figure, not a real counter.
                </p>
              </div>

              {/* Onboarding Symptoms */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Onboarding Symptoms
                </label>
                <div className="border border-gray-300 rounded-lg p-3 max-h-60 overflow-y-auto bg-white">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                    {Object.values(OnboardingSymptom).map((symptom) => (
                      <label
                        key={symptom}
                        className="flex items-start gap-2 rounded-md px-2 py-1.5 text-sm text-gray-700 hover:bg-gray-50"
                      >
                        <input
                          type="checkbox"
                          checked={onboardingSymptoms.includes(symptom)}
                          onChange={() =>
                            handleToggleOnboardingSymptom(symptom)
                          }
                          className="mt-0.5 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                        />
                        <span>
                          {symptomLabels[symptom] ??
                            formatOnboardingSymptomLabel(symptom)}
                        </span>
                      </label>
                    ))}
                  </div>
                  {onboardingSymptoms.length > 0 && (
                    <button
                      type="button"
                      onClick={() => setOnboardingSymptoms([])}
                      className="mt-3 text-sm font-medium text-gray-500 hover:text-gray-700"
                    >
                      Clear selection
                    </button>
                  )}
                </div>
              </div>

              {/* Prices */}
              <div>
                <div className="flex items-center justify-between mb-3">
                  <label className="block text-sm font-medium text-gray-700">
                    Pricing
                  </label>
                  <button
                    type="button"
                    onClick={handleAddPrice}
                    className="flex items-center gap-1 text-blue-600 hover:text-blue-800 text-sm font-medium"
                  >
                    <PlusIcon className="w-4 h-4" /> Add Price
                  </button>
                </div>

                {prices.length === 0 ? (
                  <div className="bg-gray-50 rounded-lg p-4 text-center text-gray-500 text-sm">
                    No pricing options added yet.
                  </div>
                ) : (
                  <div className="space-y-3">
                    {prices.map((p, i) => (
                      <motion.div
                        key={i}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="border border-gray-200 rounded-lg p-4 bg-white"
                      >
                        <div className="flex justify-between items-start mb-3">
                          <h4 className="text-sm font-medium text-gray-700">
                            Price Option #{i + 1}
                          </h4>
                          {prices.length > 1 && (
                            <button
                              type="button"
                              onClick={() => handleRemovePrice(i)}
                              className="text-gray-400 hover:text-red-600 transition-colors"
                              title="Remove price"
                            >
                              <TrashIcon className="w-4 h-4" />
                            </button>
                          )}
                        </div>

                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                          <div>
                            <label className="block text-xs text-gray-500 mb-1">
                              Currency
                            </label>
                            <div className="relative">
                              <select
                                value={p.currency}
                                onChange={(e) =>
                                  handlePriceChange(
                                    i,
                                    "currency",
                                    e.target.value
                                  )
                                }
                                className="w-full border border-gray-300 rounded-lg px-3 py-2 pr-8 text-sm focus:ring-1 focus:ring-blue-500 focus:border-blue-500 appearance-none bg-white"
                              >
                                <option value="USD">USD</option>
                                <option value="EUR">EUR</option>
                                <option value="GBP">GBP</option>
                                <option value="VND">VND</option>
                              </select>
                              <div className="absolute inset-y-0 right-0 flex items-center px-1 pointer-events-none">
                                <svg
                                  className="w-4 h-4 text-gray-400"
                                  fill="none"
                                  stroke="currentColor"
                                  viewBox="0 0 24 24"
                                >
                                  <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M19 9l-7 7-7-7"
                                  />
                                </svg>
                              </div>
                            </div>
                          </div>

                          <div>
                            <label className="block text-xs text-gray-500 mb-1">
                              Original Price
                            </label>
                            <div className="relative">
                              <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500 text-sm">
                                {p.currency}
                              </span>
                              <input
                                type="number"
                                value={p.originalPrice}
                                onChange={(e) =>
                                  handlePriceChange(
                                    i,
                                    "originalPrice",
                                    e.target.value
                                  )
                                }
                                className="w-full border border-gray-300 rounded-lg pl-8 pr-3 py-2 text-sm focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                                disabled={p.isFree}
                              />
                            </div>
                          </div>

                          <div>
                            <label className="block text-xs text-gray-500 mb-1">
                              Sale Price (Optional)
                            </label>
                            <div className="relative">
                              <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500 text-sm">
                                {p.currency}
                              </span>
                              <input
                                type="number"
                                value={p.salePrice ?? ""}
                                onChange={(e) =>
                                  handlePriceChange(
                                    i,
                                    "salePrice",
                                    e.target.value
                                  )
                                }
                                className="w-full border border-gray-300 rounded-lg pl-8 pr-3 py-2 text-sm focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                                disabled={p.isFree}
                              />
                            </div>
                          </div>

                          <div className="flex items-center gap-2">
                            <input
                              type="checkbox"
                              checked={p.isFree}
                              onChange={(e) =>
                                handlePriceChange(i, "isFree", e.target.checked)
                              }
                              className="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                            />
                            <label className="text-sm text-gray-700">
                              Free Course
                            </label>
                          </div>
                        </div>
                      </motion.div>
                    ))}
                  </div>
                )}
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
                className="px-4 py-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all flex items-center gap-2 disabled:opacity-70"
              >
                {loading ? (
                  <>
                    <ArrowPathIcon className="h-4 w-4 animate-spin" />
                    <span>Saving...</span>
                  </>
                ) : initial ? (
                  <span>Save Changes</span>
                ) : (
                  <span>Create Course</span>
                )}
              </button>
            </div>
          </form>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
