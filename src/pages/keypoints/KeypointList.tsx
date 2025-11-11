import React, { useEffect, useState, useRef, useCallback } from "react";
import { PencilIcon, TrashIcon, PlusIcon } from "@heroicons/react/24/outline";
import { keypointService } from "../../services/keypointService";
import {
  IKeypoint,
  KeypointPayload,
  KeypointListQuery,
} from "../../types/interface/keypoint.interface";
import KeypointModal from "../../components/keypoints/KeypointModal";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import KeypointConfirm from "../../components/keypoints/KeypointConfirm";
import { PuzzlePieceIcon } from "@heroicons/react/24/solid";
import { useNavigate } from "react-router-dom";

const KeypointList: React.FC = () => {
  const navigate = useNavigate();
  const lang = useSelector((state: RootState) => state.lang.code);
  const [keypoints, setKeypoints] = useState<IKeypoint[]>([]);
  const [selected, setSelected] = useState<IKeypoint | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [loading, setLoading] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const observer = useRef<IntersectionObserver | null>(null);

  // Bộ lọc
  const [search, setSearch] = useState("");

  // Fetch dữ liệu ban đầu
  useEffect(() => {
    resetAndFetch();
  }, [search]);

  // Reset state khi filter thay đổi
  const resetAndFetch = useCallback(() => {
    setKeypoints([]);
    setPage(1);
    setHasMore(true);
    fetchKeypoints(1, false);
  }, [search]);

  // Fetch dữ liệu
  const fetchKeypoints = async (pageNum = 1, isLoadMore = false) => {
    if (loading || loadingMore) return;

    if (isLoadMore) {
      setLoadingMore(true);
    } else {
      setLoading(true);
    }

    try {
      // Sử dụng KeypointListQuery để build params
      const query = new KeypointListQuery({
        search,
        page: pageNum,
        take: 10,
      });

      const res = await keypointService.getList(query);
      const newKeypoints = res.data.items || [];
      const totalPages =
        res.data.totalPages || Math.ceil(res.data.total / res.data.limit);

      if (isLoadMore) {
        setKeypoints((prev) => [...prev, ...newKeypoints]);
      } else {
        setKeypoints(newKeypoints);
      }

      // Cập nhật trang và kiểm tra còn dữ liệu không
      setPage(pageNum);
      setHasMore(pageNum < totalPages);
    } catch (err) {
      console.error("Fetch failed", err);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  // Load more khi scroll
  const lastKeypointRef = useCallback(
    (node: HTMLDivElement) => {
      if (loading || loadingMore || !hasMore) return;

      if (observer.current) observer.current.disconnect();

      observer.current = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting && hasMore) {
          fetchKeypoints(page + 1, true);
        }
      });

      if (node) observer.current.observe(node);
    },
    [loading, loadingMore, hasMore, page]
  );

  // Xóa keypoint
  const handleConfirmDelete = async (id: string) => {
    try {
      await keypointService.remove(id);
      setKeypoints((prev) => prev.filter((c) => c._id !== id));
      setIsConfirmOpen(false);
      setSelected(null);
    } catch (err) {
      console.error("Delete failed", err);
    }
  };

  // Mở modal xác nhận xóa
  const openDelete = (k: IKeypoint) => {
    setSelected(k);
    setIsConfirmOpen(true);
  };

  // Lưu keypoint
  const handleSave = async (data: KeypointPayload) => {
    try {
      if (selected) {
        await keypointService.update(selected._id, data);
      } else {
        await keypointService.create(data);
      }
      setIsModalOpen(false);
      setSelected(null);
      resetAndFetch();
    } catch (err) {
      console.error("Save failed", err);
    }
  };

  return (
    <div className="p-6 max-w-7xl mx-auto">
      {/* Header + Bộ lọc */}
      <div className="flex flex-wrap items-center justify-between mb-6 gap-4">
        <h1 className="text-2xl font-bold">🎯 Keypoints</h1>

        <div className="flex flex-wrap items-center gap-3">
          {/* Search */}
          <input
            type="text"
            placeholder="Search keypoint..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="border rounded-lg px-3 py-2 w-64 focus:outline-none focus:ring-2 focus:ring-blue-500"
          />

          {/* Nút tạo */}
          <button
            onClick={() => {
              setSelected(null);
              setIsModalOpen(true);
            }}
            className="flex items-center bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition"
          >
            <PlusIcon className="w-4 h-4 mr-2" />
            New Keypoint
          </button>
        </div>
      </div>

      {/* Danh sách Keypoint */}
      <div className="space-y-4">
        {keypoints.map((kp, index) => (
          <div
            key={kp._id}
            ref={index === keypoints.length - 1 ? lastKeypointRef : null}
            className="flex justify-between items-center bg-white border border-gray-100 rounded-xl p-5 shadow-sm hover:shadow-lg transition-all duration-200 transform"
          >
            <div className="flex items-center gap-4 w-full">
              <div className="p-3 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-xl shadow-md">
                <PuzzlePieceIcon className="h-7 w-7 text-white" />
              </div>
              <div className="flex-1">
                <h2
                  className="text-xl font-semibold text-gray-800 cursor-pointer"
                  onClick={() => {
                    navigate(`/keypoint/${kp._id}`);
                  }}
                >
                  {kp.title[lang]}
                </h2>
                <p className="text-gray-600 mt-1.5 leading-relaxed">
                  {kp.description[lang]}
                </p>
                {/* Hiển thị tag nếu có */}
                {kp.tag && kp.tag.length > 0 && (
                  <div className="flex flex-wrap gap-2 mt-3">
                    {kp.tag.map((t, index) => (
                      <span
                        key={index}
                        className="inline-block px-3 py-1 text-xs font-medium bg-gradient-to-r from-blue-100 to-indigo-100 text-blue-800 rounded-full"
                      >
                        {t}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </div>
            <div className="flex gap-2">
              <button
                className="p-2.5 bg-blue-50 rounded-lg hover:bg-blue-100 transition-all duration-200 group"
                onClick={() => {
                  setSelected(kp);
                  setIsModalOpen(true);
                }}
              >
                <PencilIcon className="w-5 h-5 text-blue-600 group-hover:text-blue-700" />
              </button>
              <button
                className="p-2.5 bg-red-50 rounded-lg hover:bg-red-100 transition-all duration-200 group"
                onClick={() => openDelete(kp)}
              >
                <TrashIcon className="w-5 h-5 text-red-600 group-hover:text-red-700" />
              </button>
            </div>
          </div>
        ))}

        {/* Loading indicator for initial load */}
        {loading && keypoints.length === 0 && (
          <div className="flex justify-center py-8">
            <div className="animate-spin rounded-full h-10 w-10 border-4 border-blue-200 border-t-blue-600"></div>
          </div>
        )}

        {/* Loading more indicator */}
        {loadingMore && (
          <div className="flex justify-center py-4">
            <div className="animate-spin rounded-full h-8 w-8 border-4 border-blue-200 border-t-blue-600"></div>
          </div>
        )}

        {/* Nếu không có dữ liệu */}
        {keypoints.length === 0 && !loading && (
          <div className="text-center py-12 bg-white rounded-xl shadow-sm border border-gray-100">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-blue-100 to-indigo-100 rounded-full mb-4">
              <svg
                className="h-8 w-8 text-blue-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <h3 className="mt-2 text-lg font-medium text-gray-900">
              No keypoints found
            </h3>
            <p className="mt-1 text-sm text-gray-500">
              Try adjusting your search
            </p>
          </div>
        )}

        {/* Không còn dữ liệu để load thêm */}
        {!hasMore && keypoints.length > 0 && (
          <div className="text-center py-4 px-4 bg-gray-50 rounded-lg border border-gray-100">
            <p className="text-sm text-gray-600">No more content to load</p>
          </div>
        )}
      </div>

      {/* Modal thêm/sửa */}
      {isModalOpen && (
        <KeypointModal
          open={isModalOpen}
          onClose={() => setIsModalOpen(false)}
          keypoint={selected}
          onSave={handleSave}
        />
      )}

      {/* Modal xác nhận xoá */}
      <KeypointConfirm
        isOpen={isConfirmOpen}
        keypoint={selected ?? undefined}
        onClose={() => {
          setIsConfirmOpen(false);
          setSelected(null);
        }}
        onConfirm={() => selected && handleConfirmDelete(selected._id)}
      />
    </div>
  );
};

export default KeypointList;
