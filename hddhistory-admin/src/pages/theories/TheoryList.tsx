import { useNavigate } from "react-router-dom";
import { ILearningItem } from "../../types/interface/learning-item/learning-item.interface";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { learningItemService } from "../../services/learningItemService";
import { keypointService } from "../../services/keypointService";
import { LearningItemType } from "../../types/enum/learningItem.enum";
import { PlusIcon, Trash2Icon } from "lucide-react";
import { Combobox } from "@headlessui/react";
import { motion, AnimatePresence } from "framer-motion";
import { useEffect, useRef, useState, useCallback } from "react";
import { IKeypoint } from "../../types/interface/keypoint.interface";
import { getTranslationValue } from "../../utils/translation";
import CloudflareAssetPreview from "../../components/files/CloudflareAssetPreview";
import AsyncExcelImportButton from "../../components/imports/AsyncExcelImportButton";
import { downloadBlob } from "../../utils/downloadBlob";
import { useNotification } from "../../utils/hooks/useNotification";
import LearningItemConfirm from "../../components/learning-item/LearningItemConfirm";

const TheoryList: React.FC = () => {
  const navigate = useNavigate();
  const { showError, showSuccess } = useNotification();
  const [theories, setTheories] = useState<ILearningItem[]>([]);
  const [keypoints, setKeypoints] = useState<IKeypoint[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedKeypoint, setSelectedKeypoint] = useState<any>(null);
  const [keypointQuery, setKeypointQuery] = useState("");
  const [isDeleteMode, setIsDeleteMode] = useState(false);
  const [selectedTheoryIds, setSelectedTheoryIds] = useState<string[]>([]);
  const [confirmBulkDelete, setConfirmBulkDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const debounceRef = useRef<number | undefined>(undefined);
  const observer = useRef<IntersectionObserver | null>(null);
  const lang = useSelector((state: RootState) => state.lang.code);

  // fetch keypoints (with search)
  const fetchKeypoints = async (query = "") => {
    try {
      const res = await keypointService.getList({ search: query });
      const list: IKeypoint[] = res.data.items;
      setKeypoints(list);
    } catch (err) {
      console.error("Failed to fetch keypoints:", err);
    }
  };

  // fetch theories with pagination
  const fetchTheories = async (
    search = "",
    keypointId?: string,
    pageNum = 1,
    isLoadMore = false
  ) => {
    if (!hasMore && pageNum > 1) return;

    if (isLoadMore) {
      setLoadingMore(true);
    } else {
      setLoading(true);
    }

    try {
      const res = await learningItemService.getList({
        type: LearningItemType.THEORY,
        keypointId,
        search,
        page: pageNum,
        take: 12,
      });
      const list: ILearningItem[] = res.data.items;
      const totalPages =
        res.data.totalPages || Math.ceil(res.data.total / res.data.limit);

      if (pageNum === 1) {
        setTheories(list);
      } else {
        setTheories((prev) => [...prev, ...list]);
      }

      setHasMore(pageNum < totalPages);
      setPage(pageNum);
    } catch (err) {
      console.error("Failed to fetch theories:", err);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  useEffect(() => {
    fetchKeypoints();
    fetchTheories("", selectedKeypoint?._id, 1, false);
  }, []);

  useEffect(() => {
    fetchTheories(searchTerm.trim(), selectedKeypoint?._id, 1, false);
  }, [selectedKeypoint]);

  useEffect(() => {
    setSelectedTheoryIds((prev) =>
      prev.filter((id) => theories.some((theory) => theory._id === id))
    );
  }, [theories]);

  // debounce search theories
  useEffect(() => {
    window.clearTimeout(debounceRef.current);
    debounceRef.current = window.setTimeout(() => {
      fetchTheories(searchTerm.trim(), selectedKeypoint?._id, 1, false);
    }, 500);
    return () => window.clearTimeout(debounceRef.current);
  }, [searchTerm]);

  // debounce search keypoints
  useEffect(() => {
    window.clearTimeout(debounceRef.current);
    debounceRef.current = window.setTimeout(() => {
      fetchKeypoints(keypointQuery.trim());
    }, 400);
    return () => window.clearTimeout(debounceRef.current);
  }, [keypointQuery]);

  // Using IntersectionObserver for infinite scroll
  const lastTheoryRef = useCallback(
    (node: any) => {
      if (loading || loadingMore) return;
      if (observer.current) observer.current.disconnect();
      observer.current = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting && hasMore) {
          fetchTheories(
            searchTerm.trim(),
            selectedKeypoint?._id,
            page + 1,
            true
          );
        }
      });
      if (node) observer.current.observe(node);
    },
    [loading, loadingMore, hasMore, page, searchTerm, selectedKeypoint]
  );

  const selectedCount = selectedTheoryIds.length;
  const visibleTheoryIds = theories.map((theory) => theory._id);
  const allVisibleSelected =
    visibleTheoryIds.length > 0 &&
    visibleTheoryIds.every((id) => selectedTheoryIds.includes(id));

  const toggleTheorySelection = (id: string) => {
    setSelectedTheoryIds((prev) =>
      prev.includes(id) ? prev.filter((itemId) => itemId !== id) : [...prev, id]
    );
  };

  const toggleAllVisibleTheories = () => {
    if (allVisibleSelected) {
      setSelectedTheoryIds((prev) =>
        prev.filter((id) => !visibleTheoryIds.includes(id))
      );
      return;
    }

    setSelectedTheoryIds((prev) =>
      Array.from(new Set([...prev, ...visibleTheoryIds]))
    );
  };

  const handleBulkDelete = async () => {
    if (selectedTheoryIds.length === 0) return;

    setDeleting(true);
    setConfirmBulkDelete(false);
    try {
      await Promise.all(
        selectedTheoryIds.map((id) => learningItemService.remove(id))
      );
      setTheories((prev) =>
        prev.filter((theory) => !selectedTheoryIds.includes(theory._id))
      );
      showSuccess(`Deleted ${selectedTheoryIds.length} theories successfully`);
      setSelectedTheoryIds([]);
      setIsDeleteMode(false);
    } catch (err) {
      console.error("Failed to delete selected theories:", err);
      showError("Failed to delete selected theories");
    } finally {
      setDeleting(false);
    }
  };

  const cancelDeleteMode = () => {
    setIsDeleteMode(false);
    setSelectedTheoryIds([]);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      {/* Header */}
      <div className="max-w-7xl mx-auto mb-8">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">💡 Theories</h1>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {/* Combobox search keypoint */}
            <Combobox value={selectedKeypoint} onChange={setSelectedKeypoint}>
              <div className="relative">
                <Combobox.Input
                  className="border rounded-lg px-3 py-2 w-56 focus:outline-none focus:ring-2 focus:ring-brand-500"
                  placeholder="Search keypoint..."
                  displayValue={(keypoint: IKeypoint) =>
                    getTranslationValue(keypoint?.title, lang)
                  }
                  onChange={(e) => setKeypointQuery(e.target.value)}
                />
                <Combobox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg border bg-white shadow-lg">
                  <Combobox.Option
                    value={null}
                    className="cursor-pointer px-3 py-2 hover:bg-gray-100 text-gray-500"
                  >
                    All Keypoints
                  </Combobox.Option>
                  {keypoints.map((kp) => (
                    <Combobox.Option
                      key={kp._id}
                      value={kp}
                      className="cursor-pointer px-3 py-2 hover:bg-gray-100"
                    >
                      {getTranslationValue(kp.title, lang)}
                    </Combobox.Option>
                  ))}
                </Combobox.Options>
              </div>
            </Combobox>

            <div className="relative">
              <input
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Search theories..."
                className="border rounded-lg pl-10 pr-4 py-2 w-72 focus:outline-none focus:ring-2 focus:ring-brand-500"
              />
              <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  className="h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                  />
                </svg>
              </div>
            </div>

            <button
              type="button"
              onClick={async () => {
                try {
                  const res = await learningItemService.exportTheories();
                  downloadBlob(res.data, "theory-export.xlsx");
                } catch {
                  showError("Export theories failed");
                }
              }}
              className="inline-flex items-center gap-2 border border-slate-400 text-slate-600 hover:bg-slate-50 px-3 py-2 rounded-lg transition text-sm"
            >
              Export
            </button>

            <button
              onClick={() => navigate("/theory/create")}
              className="inline-flex items-center gap-2 bg-gradient-to-r from-brand-600 to-bronze-600 text-white px-4 py-2 rounded-lg hover:from-brand-700 hover:to-bronze-700 transition-all shadow-md hover:shadow-lg"
            >
              <PlusIcon className="h-5 w-5" />
              <span>New Theory</span>
            </button>

            <AsyncExcelImportButton
              label="Import"
              target="theories"
              onError={showError}
            />
          </div>
        </div>
      </div>

      {/* List */}
      <div className="max-w-7xl mx-auto">
        {loading && theories.length === 0 ? (
          <div className="flex items-center justify-center py-20">
            <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-brand-500"></div>
          </div>
        ) : theories.length === 0 ? (
          <div className="py-20 text-center">
            <div className="text-gray-400 mb-4">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-16 w-16 mx-auto"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
                />
              </svg>
            </div>
            <h3 className="text-xl font-medium text-gray-900 mb-1">
              No theories found
            </h3>
            <p className="text-gray-500">
              Get started by creating a new theory.
            </p>
          </div>
        ) : (
          <>
            {isDeleteMode && (
              <div className="mb-4 flex flex-col gap-3 rounded-lg border border-gray-200 bg-white p-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
                <label className="inline-flex items-center gap-2 text-sm font-medium text-gray-700">
                  <input
                    type="checkbox"
                    checked={allVisibleSelected}
                    onChange={toggleAllVisibleTheories}
                    className="h-4 w-4 rounded border-gray-300 text-brand-600 focus:ring-brand-500"
                  />
                  Select all visible theories
                </label>

                <div className="flex flex-wrap items-center gap-3">
                  <span className="text-sm text-gray-500">
                    {selectedCount} selected
                  </span>
                  <button
                    type="button"
                    onClick={cancelDeleteMode}
                    disabled={deleting}
                    className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-60"
                  >
                    Cancel
                  </button>
                  <button
                    type="button"
                    onClick={() => setConfirmBulkDelete(true)}
                    disabled={deleting || selectedCount === 0}
                    className="inline-flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-60"
                  >
                    <Trash2Icon className="h-4 w-4" />
                    Delete selected
                  </button>
                </div>
              </div>
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <AnimatePresence>
                {theories.map((theory, index) => {
                  // Add ref to the last element
                  const isLast = index === theories.length - 1;
                  const isSelected = selectedTheoryIds.includes(theory._id);
                  return (
                    <motion.div
                      key={theory._id}
                      ref={isLast ? lastTheoryRef : null}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, scale: 0.9 }}
                      transition={{ duration: 0.3 }}
                      className={`relative bg-white rounded-xl shadow-md overflow-hidden hover:shadow-xl transition duration-300 group flex flex-col h-full cursor-pointer ${
                        isDeleteMode && isSelected ? "ring-2 ring-red-500" : ""
                      }`}
                      onClick={() => {
                        if (isDeleteMode) {
                          toggleTheorySelection(theory._id);
                          return;
                        }
                        navigate(`/theory/${theory._id}`);
                      }}
                    >
                      {isDeleteMode && (
                        <label
                          className="absolute right-3 top-3 z-10 inline-flex h-9 w-9 items-center justify-center rounded-full bg-white/95 shadow-md"
                          onClick={(event) => event.stopPropagation()}
                        >
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => toggleTheorySelection(theory._id)}
                            className="h-4 w-4 rounded border-gray-300 text-red-600 focus:ring-red-500"
                            aria-label={`Select ${getTranslationValue(
                              theory.title,
                              lang
                            )}`}
                          />
                        </label>
                      )}

                      {/* Image */}
                      {theory.image && (
                        <div className="relative h-48 overflow-hidden flex-shrink-0">
                          <CloudflareAssetPreview
                            src={theory.image}
                            alt={getTranslationValue(theory.title, lang)}
                            className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-500"
                          />
                        </div>
                      )}

                      {/* Content */}
                      <div className="relative p-5 flex flex-col flex-grow">
                        <div className="flex items-center mb-4">
                          <div className="flex-shrink-0 bg-bronze-100 rounded-md p-3">
                            <svg
                              className="h-6 w-6 text-bronze-600"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke="currentColor"
                            >
                              <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth={2}
                                d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
                              />
                            </svg>
                          </div>
                          <div className="ml-4">
                            <h3 className="text-lg font-medium text-gray-900">
                              {getTranslationValue(theory.title, lang)}
                            </h3>
                            <p className="text-sm text-green-500">Theory</p>
                          </div>
                        </div>

                        {/* Tags */}
                        <div className="flex flex-wrap gap-2 mb-4">
                          {theory.tag.map((tag, index) => (
                            <span
                              key={index}
                              className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-bronze-100 text-bronze-800"
                            >
                              {tag}
                            </span>
                          ))}
                        </div>

                        {/* Additional info */}
                        <div className="grid grid-cols-2 gap-4 text-sm mt-auto">
                          <div>
                            <span className="text-gray-500">Documents:</span>
                            <span className="ml-2 font-medium">
                              {theory.documents.length}
                            </span>
                          </div>
                        </div>
                      </div>
                    </motion.div>
                  );
                })}
              </AnimatePresence>
            </div>

            {/* Loading more indicator */}
            {loadingMore && (
              <div className="flex justify-center mt-6">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-brand-500"></div>
              </div>
            )}

            {/* No more theories message */}
            {!hasMore && theories.length > 0 && (
              <div className="text-center mt-6 text-gray-500">
                No more theories to load
              </div>
            )}
          </>
        )}
      </div>

      <button
        type="button"
        onClick={() => {
          if (isDeleteMode) {
            cancelDeleteMode();
            return;
          }
          setIsDeleteMode(true);
        }}
        title={isDeleteMode ? "Cancel quick delete" : "Quick delete"}
        aria-label={isDeleteMode ? "Cancel quick delete" : "Quick delete"}
        className={`fixed bottom-6 left-1/2 z-40 inline-flex h-12 w-12 -translate-x-1/2 items-center justify-center rounded-full border shadow-lg transition ${
          isDeleteMode
            ? "border-red-500 bg-red-600 text-white hover:bg-red-700"
            : "border-gray-200 bg-white text-red-600 hover:bg-red-50"
        }`}
      >
        <Trash2Icon className="h-5 w-5" />
      </button>

      {confirmBulkDelete && (
        <LearningItemConfirm
          title="Confirm Bulk Delete"
          message={`Are you sure you want to delete ${selectedCount} selected theories? This action cannot be undone.`}
          onCancel={() => setConfirmBulkDelete(false)}
          onConfirm={handleBulkDelete}
        />
      )}
    </div>
  );
};

export default TheoryList;
