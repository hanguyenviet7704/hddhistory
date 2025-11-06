import React, { useState, useEffect } from "react";
import {
  IRoadmap,
  IRoadmapNode,
  RoadmapPayload,
} from "../../types/interface/cource.interface";
import { ILessonBrief } from "../../types/interface/lesson.interface";
import { LessonType } from "../../types/enum/lesson.enum";
import { courseService } from "../../services/courseService";
import { lessonService } from "../../services/lessonService";
import { useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { useNotification } from "../../utils/hooks/useNotification";

interface RoadmapPageProps {}

const RoadmapPage: React.FC<RoadmapPageProps> = () => {
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showSuccess, showError } = useNotification();

  const { courseId } = useParams<{ courseId: string }>();
  const [roadmap, setRoadmap] = useState<IRoadmap | null>(null);
  const [loading, setLoading] = useState(true);
  const [editingNode, setEditingNode] = useState<{
    nodeIndex: number;
    field: "entrance" | "lessons" | "output";
    currentValues: string | string[];
    lessonList: ILessonBrief[];
  } | null>(null);
  const [isCreatingNode, setIsCreatingNode] = useState(false);
  const [newNodeTitle, setNewNodeTitle] = useState("");
  const [entranceLessons, setEntranceLessons] = useState<ILessonBrief[]>([]);
  const [outputLessons, setOutputLessons] = useState<ILessonBrief[]>([]);
  const [lessonLessons, setLessonLessons] = useState<ILessonBrief[]>([]);
  const [loadingLessons, setLoadingLessons] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedLessons, setSelectedLessons] = useState<string[]>([]);

  // Lấy dữ liệu roadmap
  useEffect(() => {
    const fetchRoadmap = async () => {
      try {
        const roadmapRes = await courseService.getRoadmap(courseId!);
        const roadmapData = (await roadmapRes.data?.data) || roadmapRes.data;
        setRoadmap(roadmapData);
      } catch (error) {
        console.error("Error fetching roadmap:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchRoadmap();
  }, [courseId]);

  // Lấy danh sách bài học theo loại khi cần
  const fetchLessonsByType = async (type: LessonType, search = "") => {
    try {
      setLoadingLessons(true);
      const res = await lessonService.getList({ courseId, type, search });
      const data = res.data.items || [];

      switch (type) {
        case LessonType.ENTRANCE:
          setEntranceLessons(data);
          break;
        case LessonType.OUTPUT:
          setOutputLessons(data);
          break;
        case LessonType.LESSON:
          setLessonLessons(data);
          break;
      }

      return data;
    } catch (error) {
      console.error(`Error fetching ${type} lessons:`, error);
      return [];
    } finally {
      setLoadingLessons(false);
    }
  };

  // Tạo node mới
  const handleCreateNode = async () => {
    if (!newNodeTitle.trim()) {
      alert("Vui lòng nhập tiêu đề node");
      return;
    }

    // Lấy danh sách lesson nếu chưa có
    if (entranceLessons.length === 0) {
      await fetchLessonsByType(LessonType.ENTRANCE);
    }
    if (outputLessons.length === 0) {
      await fetchLessonsByType(LessonType.OUTPUT);
    }

    const newNode: IRoadmapNode = {
      title: { vi: newNodeTitle, en: newNodeTitle },
      entrance: entranceLessons[0] || null,
      lessons: [],
      output: outputLessons[0] || null,
    };

    const updatedRoadmap = roadmap
      ? {
          ...roadmap,
          node: [...roadmap.node, newNode],
        }
      : {
          courseId: courseId!,
          node: [newNode],
        };

    setRoadmap(updatedRoadmap);
    setIsCreatingNode(false);
    setNewNodeTitle("");
  };

  // Xóa node
  const handleDeleteNode = (nodeIndex: number) => {
    if (!roadmap) return;

    if (window.confirm("Bạn có chắc muốn xóa node này?")) {
      const updatedRoadmap = {
        ...roadmap,
        node: roadmap.node.filter((_, index) => index !== nodeIndex),
      };
      setRoadmap(updatedRoadmap);
    }
  };

  // Xử lý khi nhấn nút chỉnh sửa
  const handleEditClick = async (
    nodeIndex: number,
    field: "entrance" | "lessons" | "output"
  ) => {
    // Lấy danh sách lesson nếu chưa có
    let lessonList: ILessonBrief[] = [];

    if (field === "entrance") {
      if (entranceLessons.length === 0) {
        lessonList = await fetchLessonsByType(LessonType.ENTRANCE);
      } else {
        lessonList = entranceLessons;
      }
    } else if (field === "output") {
      if (outputLessons.length === 0) {
        lessonList = await fetchLessonsByType(LessonType.OUTPUT);
      } else {
        lessonList = outputLessons;
      }
    } else {
      if (lessonLessons.length === 0) {
        lessonList = await fetchLessonsByType(LessonType.LESSON);
      } else {
        lessonList = lessonLessons;
      }
    }

    const node = roadmap?.node[nodeIndex];
    if (!node) return;

    // Reset selectedLessons khi mở modal
    setSelectedLessons(
      field === "lessons" ? node.lessons.map((l) => l._id) : []
    );

    setEditingNode({
      nodeIndex,
      field,
      currentValues:
        field === "lessons"
          ? node.lessons.map((l) => l._id)
          : node[field]?._id || "",
      lessonList,
    });
  };

  // Xử lý khi chọn bài học
  const handleLessonSelect = (lessonId: string) => {
    if (!editingNode || !roadmap) return;

    const updatedRoadmap = { ...roadmap };
    const node = { ...updatedRoadmap.node[editingNode.nodeIndex] };

    if (editingNode.field === "lessons") {
      // Xử lý chọn nhiều bài học
      const currentSelected = [...selectedLessons];
      const isSelected = currentSelected.includes(lessonId);

      if (isSelected) {
        // Bỏ chọn
        const newSelected = currentSelected.filter((id) => id !== lessonId);
        setSelectedLessons(newSelected);

        // Cập nhật node
        node.lessons = editingNode.lessonList.filter((lesson) =>
          newSelected.includes(lesson._id)
        );
      } else {
        // Chọn thêm
        const newSelected = [...currentSelected, lessonId];
        setSelectedLessons(newSelected);

        // Cập nhật node
        node.lessons = editingNode.lessonList.filter((lesson) =>
          newSelected.includes(lesson._id)
        );
      }

      // Cập nhật state roadmap
      updatedRoadmap.node[editingNode.nodeIndex] = node;
      setRoadmap(updatedRoadmap);
    } else {
      // Với entrance và output, chọn một bài học và đóng modal ngay
      const selectedLesson = editingNode.lessonList.find(
        (lesson) => lesson._id === lessonId
      );
      if (selectedLesson) {
        node[editingNode.field] = selectedLesson;
        updatedRoadmap.node[editingNode.nodeIndex] = node;
        setRoadmap(updatedRoadmap);
        setEditingNode(null);
        setSearchTerm("");
      }
    }
  };

  // Hoàn thành chọn nhiều bài học
  const handleCompleteLessonSelection = () => {
    setEditingNode(null);
    setSearchTerm("");
    setSelectedLessons([]);
  };

  // Lưu roadmap
  const handleSaveRoadmap = async () => {
    if (!roadmap) return;

    const payload: RoadmapPayload = {
      node: roadmap.node.map((node) => ({
        title: node.title[lang] ?? "",
        entranceId: node.entrance?._id || "",
        lessonIds: node.lessons.map((lesson) => lesson._id),
        outputId: node.output?._id || "",
      })),
    };

    try {
      const response = await courseService.updateRoadmap(courseId!, payload);
      showSuccess("Saved roadmap successfully");
    } catch (error) {
      console.error("Error updating roadmap:", error);
      showError("Failed to save roadmap");
    }
  };

  // Render bài học với icon phù hợp
  const renderLesson = (lesson: ILessonBrief | null) => {
    if (!lesson) {
      return <div className="text-gray-500 italic">Chưa chọn bài học</div>;
    }

    let icon = "";
    let color = "";

    switch (lesson.type) {
      case LessonType.ENTRANCE:
        icon = "🧭";
        color = "bg-blue-100 text-blue-800";
        break;
      case LessonType.OUTPUT:
        icon = "🧠";
        color = "bg-green-100 text-green-800";
        break;
      default:
        icon = "📖";
        color = "bg-purple-100 text-purple-800";
    }

    const title = lesson.title[lang];

    return (
      <div className={`flex items-center px-3 py-2 rounded-lg ${color} mb-2`}>
        <span className="mr-2">{icon}</span>
        <span>{title}</span>
      </div>
    );
  };

  // Render modal chọn bài học
  const renderLessonSelector = () => {
    if (!editingNode) return null;

    const { field, lessonList } = editingNode;
    const isMultiple = field === "lessons";

    // Lọc bài học theo từ khóa tìm kiếm
    const filteredLessons = searchTerm
      ? lessonList.filter((lesson) =>
          lesson.title[lang]?.toLowerCase().includes(searchTerm.toLowerCase())
        )
      : lessonList;

    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div className="bg-white rounded-lg p-6 w-full max-w-2xl">
          <h3 className="text-xl font-bold mb-4">
            {field === "entrance"
              ? "Chọn Bài Đầu Vào"
              : field === "output"
              ? "Chọn Bài Kết Thúc"
              : "Chọn Bài Học"}
          </h3>

          {/* Ô tìm kiếm */}
          <div className="mb-4">
            <input
              type="text"
              placeholder="Tìm kiếm bài học..."
              className="w-full px-3 py-2 border rounded-lg"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          {loadingLessons ? (
            <div className="text-center py-8">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
              <p className="mt-4 text-gray-600">Đang tải bài học...</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 max-h-96 overflow-y-auto">
              {filteredLessons.map((lesson) => {
                if (!lesson) return null;

                const isSelected = isMultiple
                  ? selectedLessons.includes(lesson._id)
                  : (editingNode.currentValues as string) === lesson._id;

                return (
                  <div
                    key={lesson._id}
                    className={`p-4 rounded-lg border cursor-pointer transition-all ${
                      isSelected
                        ? "border-blue-500 bg-blue-50"
                        : "border-gray-200 hover:bg-gray-50"
                    }`}
                    onClick={() => handleLessonSelect(lesson._id)}
                  >
                    {renderLesson(lesson)}
                    {isMultiple && (
                      <div className="mt-2 text-sm text-gray-600">
                        {isSelected ? "✓ Đã chọn" : "Chọn bài học"}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}

          <div className="mt-6 flex justify-end">
            {/* Hiển thị nút Hoàn thành khi chọn nhiều lessons */}
            {isMultiple && (
              <button
                className="px-4 py-2 bg-blue-600 text-white rounded-lg mr-2"
                onClick={handleCompleteLessonSelection}
              >
                Hoàn thành
              </button>
            )}

            <button
              className="px-4 py-2 bg-gray-200 rounded-lg"
              onClick={() => {
                setEditingNode(null);
                setSearchTerm("");
                setSelectedLessons([]);
              }}
            >
              Hủy
            </button>
          </div>
        </div>
      </div>
    );
  };

  // Render form tạo node mới
  const renderCreateNodeForm = () => {
    if (!isCreatingNode) return null;

    return (
      <div className="bg-white rounded-xl shadow-md p-6 mb-6">
        <h3 className="text-xl font-bold mb-4">Tạo Node Mới</h3>

        <div className="mb-4">
          <label className="block text-gray-700 mb-2">Tiêu đề Node</label>
          <input
            type="text"
            className="w-full px-3 py-2 border rounded-lg"
            value={newNodeTitle}
            onChange={(e) => setNewNodeTitle(e.target.value)}
            placeholder="Nhập tiêu đề node"
          />
        </div>

        <div className="flex justify-end">
          <button
            className="px-4 py-2 bg-gray-200 rounded-lg mr-2"
            onClick={() => setIsCreatingNode(false)}
          >
            Hủy
          </button>
          <button
            className="px-4 py-2 bg-blue-600 text-white rounded-lg"
            onClick={handleCreateNode}
          >
            Tạo Node
          </button>
        </div>
      </div>
    );
  };

  // Render mỗi node trong roadmap với UI mới
  const renderNode = (
    node: IRoadmapNode,
    nodeIndex: number,
    totalNodes: number
  ) => {
    const isLeft = nodeIndex % 2 === 0;

    return (
      <div key={nodeIndex} className="relative">
        {/* Connection line to next node - only if not the last node */}
        {nodeIndex < totalNodes - 1 && (
          <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 w-1 h-12 bg-blue-500"></div>
        )}

        {/* Node container */}
        <div className={`relative ${isLeft ? "pr-8" : "pl-8"} mb-16`}>
          {/* Vertical line (only for the main vertical line) */}
          <div className="absolute top-0 bottom-0 left-1/2 transform -translate-x-1/2 w-1 bg-blue-300"></div>

          {/* Horizontal connection line from center to node */}
          <div
            className={`absolute top-1/2 left-1/2 transform -translate-y-1/2 h-1 bg-blue-300 ${
              isLeft ? "w-16 -translate-x-full" : "w-16 translate-x-0"
            }`}
          ></div>

          {/* Node content */}
          <div
            className={`bg-white rounded-xl shadow-lg p-6 w-full max-w-md ${
              isLeft ? "mr-auto" : "ml-auto"
            }`}
          >
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-bold text-gray-800">
                {node.title[lang]}
              </h2>
              <button
                className="px-3 py-1 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors"
                onClick={() => handleDeleteNode(nodeIndex)}
              >
                Xóa
              </button>
            </div>

            <div className="space-y-4">
              {/* Entrance */}
              <div className="border-l-4 border-blue-500 pl-4">
                <div className="flex justify-between items-center mb-2">
                  <h3 className="font-medium text-gray-700">Bài Đầu Vào</h3>
                  <button
                    className="text-blue-600 hover:text-blue-800 text-sm"
                    onClick={() => handleEditClick(nodeIndex, "entrance")}
                  >
                    Chỉnh sửa
                  </button>
                </div>
                {renderLesson(node.entrance)}
              </div>

              {/* Lessons */}
              <div className="border-l-4 border-purple-500 pl-4">
                <div className="flex justify-between items-center mb-2">
                  <h3 className="font-medium text-gray-700">Các Bài Học</h3>
                  <button
                    className="text-blue-600 hover:text-blue-800 text-sm"
                    onClick={() => handleEditClick(nodeIndex, "lessons")}
                  >
                    Chỉnh sửa
                  </button>
                </div>
                <div className="space-y-2">
                  {node.lessons.length > 0 ? (
                    node.lessons.map((lesson) => (
                      <div key={lesson._id} className="flex items-center">
                        <span className="mr-2">📖</span>
                        <span className="text-sm">{lesson.title[lang]}</span>
                      </div>
                    ))
                  ) : (
                    <p className="text-gray-500 italic text-sm">
                      Chưa có bài học nào
                    </p>
                  )}
                </div>
              </div>

              {/* Output */}
              <div className="border-l-4 border-green-500 pl-4">
                <div className="flex justify-between items-center mb-2">
                  <h3 className="font-medium text-gray-700">Bài Kết Thúc</h3>
                  <button
                    className="text-blue-600 hover:text-blue-800 text-sm"
                    onClick={() => handleEditClick(nodeIndex, "output")}
                  >
                    Chỉnh sửa
                  </button>
                </div>
                {renderLesson(node.output)}
              </div>
            </div>
          </div>

          {/* Node position indicator (circle at the center) */}
          <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-4 h-4 bg-blue-500 rounded-full border-4 border-white shadow-lg z-10"></div>
        </div>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-xl">Đang tải roadmap...</div>
      </div>
    );
  }

  if (!roadmap) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-xl">Không tìm thấy roadmap</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 py-12">
      <div className="max-w-6xl mx-auto px-4">
        {/* Header */}
        <div className="flex justify-between items-center mb-12">
          <h1 className="text-3xl font-bold text-gray-800">Roadmap Khóa Học</h1>
          <div className="flex space-x-3">
            <button
              className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors shadow-md"
              onClick={() => setIsCreatingNode(true)}
            >
              <span className="flex items-center">
                <svg
                  className="w-5 h-5 mr-2"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                Thêm Node
              </span>
            </button>
            <button
              className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-md"
              onClick={handleSaveRoadmap}
            >
              <span className="flex items-center">
                <svg
                  className="w-5 h-5 mr-2"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4"
                  />
                </svg>
                Lưu Roadmap
              </span>
            </button>
          </div>
        </div>

        {renderCreateNodeForm()}

        {/* Roadmap container */}
        <div className="relative">
          {/* Main vertical line */}
          <div className="absolute left-1/2 transform -translate-x-1/2 top-0 bottom-0 w-2 bg-gradient-to-b from-blue-400 to-blue-600 rounded-full"></div>
          {/* Nodes */}
          <div className="space-y-20">
            {roadmap.node.map((node, index) =>
              renderNode(node, index, roadmap.node.length)
            )}
          </div>
        </div>

        {editingNode && renderLessonSelector()}
      </div>
    </div>
  );
};

export default RoadmapPage;
