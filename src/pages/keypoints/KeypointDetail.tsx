import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { learningItemService } from "../../services/learningItemService";
import { keypointService } from "../../services/keypointService";
import { IKeypoint } from "../../types/interface/keypoint.interface";
import { ArrowLeftIcon } from "@heroicons/react/24/outline";
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  DragEndEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  sortableKeyboardCoordinates,
  rectSortingStrategy,
} from "@dnd-kit/sortable";
import { useSortable } from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { SaveIcon } from "lucide-react";
import {
  ILearningItemBrief,
  LearningItemsIndexPayload,
} from "../../types/interface/learning-item/learning-item.interface";
import { LearningItemType } from "../../types/enum/learningItem.enum";
import { getTranslationValue } from "../../utils/translation";

// Custom SortableItem for grid layout
const SortableItem = ({
  id,
  children,
}: {
  id: string;
  children: React.ReactNode;
}) => {
  const { attributes, listeners, setNodeRef, transform, transition } =
    useSortable({ id });

  const style: React.CSSProperties = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      className="cursor-grab active:cursor-grabbing h-full"
    >
      {children}
    </div>
  );
};

const KeypointDetail: React.FC = () => {
  const { keypointId } = useParams<{ keypointId: string }>();
  const navigate = useNavigate();
  const lang = useSelector((state: RootState) => state.lang.code);

  const [keypoint, setKeypoint] = useState<IKeypoint | null>(null);
  const [learningItems, setLearningItems] = useState<ILearningItemBrief[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [hasChanges, setHasChanges] = useState(false);

  // Cảm biến cho dnd-kit
  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  // Fetch keypoint details
  useEffect(() => {
    const fetchKeypoint = async () => {
      if (!keypointId) return;

      try {
        const res = await keypointService.getById(keypointId);
        setKeypoint(res.data);
      } catch (err) {
        console.error("Failed to fetch keypoint:", err);
      }
    };

    fetchKeypoint();
  }, [keypointId]);

  // Fetch learning items
  useEffect(() => {
    const fetchLearningItems = async () => {
      if (!keypointId) return;

      setLoading(true);
      try {
        const res = await learningItemService.getList({ keypointId });
        // Sort by index initially (giả sử index từ API đã bắt đầu từ 1)
        const sortedItems = [...res.data.items].sort(
          (a, b) => a.index - b.index
        );
        setLearningItems(sortedItems);
      } catch (err) {
        console.error("Failed to fetch learning items:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchLearningItems();
  }, [keypointId]);

  // Handle drag end - THAY ĐỔI Ở ĐÂY
  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;

    if (active.id !== over?.id) {
      setLearningItems((items) => {
        const oldIndex = items.findIndex((item) => item._id === active.id);
        const newIndex = items.findIndex((item) => item._id === over?.id);

        // Tạo một bản sao của mảng để không thay đổi trực tiếp state
        const newItems = [...items];

        // Hoán đổi vị trí giữa hai phần tử
        const temp = newItems[oldIndex];
        newItems[oldIndex] = newItems[newIndex];
        newItems[newIndex] = temp;

        // Cập nhật lại index cho tất cả các phần tử, bắt đầu từ 1
        return newItems.map((item, index) => ({
          ...item,
          index: index + 1,
        }));
      });

      setHasChanges(true);
    }
  };

  // Save the new order
  const handleSaveOrder = async () => {
    if (!keypointId || !hasChanges) return;

    setSaving(true);
    try {
      const payload: LearningItemsIndexPayload = {
        keypointId: keypointId,
        learningItems: learningItems.map((item) => ({
          id: item._id,
          index: item.index, // Index đã được tính lại bắt đầu từ 1
        })),
      };

      await learningItemService.updatelearningItemIndex(payload);
      setHasChanges(false);
    } catch (err) {
      console.error("Failed to save order:", err);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="p-6 max-w-6xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate(-1)}
            className="p-2 rounded-lg hover:bg-gray-100 transition-colors"
          >
            <ArrowLeftIcon className="w-5 h-5" />
          </button>
          <h1 className="text-2xl font-bold">
            {getTranslationValue(keypoint?.title, lang) || "Keypoint Details"}
          </h1>
        </div>

        {hasChanges && (
          <button
            onClick={handleSaveOrder}
            disabled={saving}
            className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition-colors disabled:opacity-50"
          >
            <SaveIcon className="w-4 h-4" />
            {saving ? "Saving..." : "Save Order"}
          </button>
        )}
      </div>

      {/* Loading state */}
      {loading && (
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-10 w-10 border-4 border-blue-200 border-t-blue-600"></div>
        </div>
      )}

      {/* Learning items grid */}
      {!loading && (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          {learningItems.length === 0 ? (
            <div className="text-center py-12">
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
                    d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
                  />
                </svg>
              </div>
              <h3 className="mt-2 text-lg font-medium text-gray-900">
                No learning items found
              </h3>
              <p className="mt-1 text-sm text-gray-500">
                This keypoint doesn't have any learning items yet.
              </p>
            </div>
          ) : (
            <DndContext
              sensors={sensors}
              collisionDetection={closestCenter}
              onDragEnd={handleDragEnd}
            >
              <SortableContext
                items={learningItems.map((item) => item._id)}
                strategy={rectSortingStrategy}
              >
                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                  {learningItems.map((item) => (
                    <SortableItem key={item._id} id={item._id}>
                      <div className="relative bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow h-full flex flex-col">
                        <div className="flex items-center mb-4">
                          <div className="flex-shrink-0 bg-indigo-100 rounded-md p-3">
                            <svg
                              className="w-6 h-6"
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
                          <div className="ml-4 flex-1">
                            <h3 className="text-lg font-medium text-gray-900 line-clamp-2 overflow-hidden">
                              {getTranslationValue(item.title, lang) || ""}
                            </h3>
                            {item.type === LearningItemType.THEORY ? (
                              <p className="text-sm text-green-500">Theory</p>
                            ) : (
                              <p className="text-sm text-orange-400">
                                Exercise
                              </p>
                            )}
                          </div>
                        </div>

                        <div>
                          <span className="text-gray-500">isSub:</span>
                          <span
                            className={`ml-2 font-medium ${
                              item.isSub ? "text-green-600" : "text-violet-300"
                            }`}
                          >
                            {item.isSub ? "Yes" : "No"}
                          </span>
                        </div>
                        <div className="absolute bottom-3 right-3 bg-indigo-100 text-indigo-800 text-xs font-medium px-2 py-1 rounded-full">
                          {item.index}{" "}
                          {/* Hiển thị index trực tiếp, vì nó đã bắt đầu từ 1 */}
                        </div>
                      </div>
                    </SortableItem>
                  ))}
                </div>
              </SortableContext>
            </DndContext>
          )}
        </div>
      )}
    </div>
  );
};

export default KeypointDetail;
