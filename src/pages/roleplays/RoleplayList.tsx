import { Link, useNavigate } from "react-router-dom";
import { ILearningItem } from "../../types/interface/learning-item/learning-item.interface";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { learningItemService } from "../../services/learningItemService";
import { keypointService } from "../../services/keypointService";
import { LearningItemType } from "../../types/enum/learningItem.enum";
import { PlusIcon } from "lucide-react";
import { Combobox } from "@headlessui/react";
import { motion, AnimatePresence } from "framer-motion";
import { useEffect, useRef, useState, useCallback } from "react";
import { IKeypoint } from "../../types/interface/keypoint.interface";
import { getTranslationValue } from "../../utils/translation";

const RoleplayList: React.FC = () => {
  const navigate = useNavigate();
  const [roleplays, setRoleplays] = useState<ILearningItem[]>([]);
  const [keypoints, setKeypoints] = useState<IKeypoint[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedKeypoint, setSelectedKeypoint] = useState<any>(null);
  const [keypointQuery, setKeypointQuery] = useState("");

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

  // fetch roleplays with pagination
  const fetchRoleplays = async (
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
        type: LearningItemType.ROLEPLAY,
        keypointId,
        search,
        page: pageNum,
        take: 12,
      });
      const list: ILearningItem[] = res.data.items;
      const totalPages =
        res.data.totalPages || Math.ceil(res.data.total / res.data.limit);

      if (pageNum === 1) {
        setRoleplays(list);
      } else {
        setRoleplays((prev) => [...prev, ...list]);
      }

      setHasMore(pageNum < totalPages);
      setPage(pageNum);
    } catch (err) {
      console.error("Failed to fetch roleplays:", err);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  useEffect(() => {
    fetchKeypoints();
    fetchRoleplays("", selectedKeypoint?._id, 1, false);
  }, []);

  useEffect(() => {
    fetchRoleplays(searchTerm.trim(), selectedKeypoint?._id, 1, false);
  }, [selectedKeypoint]);

  // debounce search roleplays
  useEffect(() => {
    window.clearTimeout(debounceRef.current);
    debounceRef.current = window.setTimeout(() => {
      fetchRoleplays(searchTerm.trim(), selectedKeypoint?._id, 1, false);
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
  const lastRoleplayRef = useCallback(
    (node: any) => {
      if (loading || loadingMore) return;
      if (observer.current) observer.current.disconnect();
      observer.current = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting && hasMore) {
          fetchRoleplays(
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

  return (
    <div className="roleplay-list">
      <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
        {/* Header */}
        <div className="max-w-7xl mx-auto mb-8">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">👥 Roleplays</h1>
            </div>

            <div className="flex flex-wrap items-center gap-3">
              {/* Combobox search keypoint */}
              <Combobox value={selectedKeypoint} onChange={setSelectedKeypoint}>
                <div className="relative">
                  <Combobox.Input
                    className="border rounded-lg px-3 py-2 w-56 focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="Search keypoint..."
                    displayValue={(keypoint: IKeypoint) =>
                      keypoint?.title?.[lang] || ""
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

              {/* Search input for roleplays */}
              <div className="relative">
                <input
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Search roleplays..."
                  className="border rounded-lg pl-10 pr-4 py-2 w-72 focus:outline-none focus:ring-2 focus:ring-blue-500"
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
                onClick={() => navigate("/roleplay/create")}
                className="inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-4 py-2 rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg"
              >
                <PlusIcon className="h-5 w-5" />
                <span>New Roleplay</span>
              </button>
            </div>
          </div>
        </div>

        {/* List */}
        <div className="max-w-7xl mx-auto">
          {loading && roleplays.length === 0 ? (
            <div className="flex items-center justify-center py-20">
              <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
            </div>
          ) : roleplays.length === 0 ? (
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
                No roleplays found
              </h3>
              <p className="text-gray-500">
                Get started by creating a new roleplay.
              </p>
            </div>
          ) : (
            <>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <AnimatePresence>
                  {roleplays.map((roleplay, index) => {
                    // Add ref to the last element
                    const isLast = index === roleplays.length - 1;
                    return (
                      <motion.div
                        key={roleplay._id}
                        ref={isLast ? lastRoleplayRef : null}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.9 }}
                        transition={{ duration: 0.3 }}
                        className="bg-white rounded-xl shadow-md overflow-hidden hover:shadow-xl transition-shadow duration-300 group flex flex-col h-full cursor-pointer"
                        onClick={() => navigate(`/roleplay/${roleplay._id}`)}
                      >
                        {/* Image */}
                        <div className="relative h-48 overflow-hidden flex-shrink-0">
                          <img
                            src={
                              roleplay.image ||
                              "https://placehold.co/600x400/?text=Roleplay+Image&font=roboto"
                            }
                            alt={getTranslationValue(roleplay.title, lang)}
                            className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-500"
                          />
                        </div>

                        {/* Content */}
                        <div className="relative p-5 flex flex-col flex-grow">
                          <div className="flex items-center mb-4">
                            <div className="flex-shrink-0 bg-indigo-100 rounded-md p-3">
                              <svg
                                className="h-6 w-6 text-indigo-600"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                              >
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  strokeWidth={2}
                                  d="M7 8h10M7 12h6m5 8l-4-4H7a2 2 0 01-2-2V7a2 2 0 012-2h10a2 2 0 012 2v11z"
                                />
                              </svg>
                            </div>
                            <div className="ml-4">
                              <h3 className="text-lg font-medium text-gray-900">
                                {getTranslationValue(roleplay.title, lang)}
                              </h3>
                              <p className="text-sm text-purple-600">
                                Roleplay
                              </p>
                            </div>
                          </div>

                          {/* Tags */}
                          <div className="flex flex-wrap gap-2 mb-4">
                            {roleplay.tag.map((tag, index) => (
                              <span
                                key={index}
                                className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800"
                              >
                                {tag}
                              </span>
                            ))}
                          </div>

                          {/* Additional info */}
                          <div className="grid grid-cols-2 gap-4 text-sm mt-auto">
                            <div>
                              <span className="text-gray-500">Section:</span>
                              <span className="ml-2 font-medium">
                                {roleplay.sections?.length}
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
                  <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
                </div>
              )}

              {/* No more roleplays message */}
              {!hasMore && roleplays.length > 0 && (
                <div className="text-center mt-6 text-gray-500">
                  No more roleplays to load
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default RoleplayList;
