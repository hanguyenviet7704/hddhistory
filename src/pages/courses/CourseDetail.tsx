import React, { useEffect, useMemo, useState } from "react";
import { useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { useNotification } from "../../utils/hooks/useNotification";

// Types
import {
  IRoadmap,
  IRoadmapLevel,
  IRoadmapNode,
  CoursePayload,
} from "../../types/interface/cource.interface";
import { ILessonBrief } from "../../types/interface/lesson.interface";
import { LessonType } from "../../types/enum/lesson.enum";
import { CourseLevel } from "../../types/enum/course.enum";
import { getTranslationValue, updateTranslationValue, cleanTranslation } from "../../utils/translation";

// Services
import { courseService } from "../../services/courseService";
import { lessonService } from "../../services/lessonService";

// ---------- Helpers ----------
const levelBadgeClass = (level: CourseLevel) => {
  switch (level) {
    case CourseLevel.LEVEL1:
      return "bg-blue-100 text-blue-800";
    case CourseLevel.LEVEL2:
      return "bg-purple-100 text-purple-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

type FieldKey = "entrance" | "lessons" | "output";

// Reusable icon-only button
const IconButton: React.FC<
  React.ButtonHTMLAttributes<HTMLButtonElement> & { sr?: string }
> = ({ className = "", sr, children, ...props }) => (
  <button
    {...props}
    className={
      "inline-flex items-center justify-center rounded-full p-2 transition-colors " +
      "bg-gray-100 hover:bg-gray-200 text-gray-700 shadow " +
      className
    }
  >
    {children}
    {sr ? <span className="sr-only">{sr}</span> : null}
  </button>
);

// ---------- Component ----------
const RoadmapPage: React.FC = () => {
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showSuccess, showError } = useNotification();
  const { courseId } = useParams<{ courseId: string }>();

  const [roadmap, setRoadmap] = useState<IRoadmap | null>(null);
  const [loading, setLoading] = useState(true);

  // Level create/edit
  const [isCreatingLevel, setIsCreatingLevel] = useState(false);
  const [newLevel, setNewLevel] = useState<CourseLevel>(CourseLevel.LEVEL1);

  // Node create/edit
  const [isCreatingNode, setIsCreatingNode] = useState<{
    on: boolean;
    levelIndex: number;
  }>({ on: false, levelIndex: -1 });
  const [newNodeTitle, setNewNodeTitle] = useState("");
  const [titleError, setTitleError] = useState("");

  // Modal edit for picking lessons
  const [editingNode, setEditingNode] = useState<{
    levelIndex: number;
    nodeIndex: number;
    field: FieldKey;
    lessonList: ILessonBrief[];
    currentValues: string | string[];
  } | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedLessons, setSelectedLessons] = useState<string[]>([]);
  const [loadingLessons, setLoadingLessons] = useState(false);

  // Cached lesson lists by type
  const [entranceLessons, setEntranceLessons] = useState<ILessonBrief[]>([]);
  const [outputLessons, setOutputLessons] = useState<ILessonBrief[]>([]);
  const [lessonLessons, setLessonLessons] = useState<ILessonBrief[]>([]);

  // Delete confirms
  const [deleteLevel, setDeleteLevel] = useState<{
    show: boolean;
    levelIndex: number;
  }>({ show: false, levelIndex: -1 });
  const [deleteNode, setDeleteNode] = useState<{
    show: boolean;
    levelIndex: number;
    nodeIndex: number;
  }>({
    show: false,
    levelIndex: -1,
    nodeIndex: -1,
  });

  // ---------- Data fetching ----------
  useEffect(() => {
    const fetchRoadmap = async () => {
      try {
        const res = await courseService.getRoadmap(courseId!);
        const data: IRoadmap = res.data?.data || res.data;
        if (!data?.levels) data.levels = [];
        setRoadmap(data);
      } catch (e) {
        console.error(e);
        showError("Không thể tải roadmap");
      } finally {
        setLoading(false);
      }
    };
    fetchRoadmap();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId]);

  const fetchLessonsByType = async (type: LessonType, search = "") => {
    try {
      setLoadingLessons(true);
      const res = await lessonService.getList({ courseId, type, search });
      const items: ILessonBrief[] = res.data?.items || [];
      switch (type) {
        case LessonType.ENTRANCE:
          setEntranceLessons(items);
          break;
        case LessonType.OUTPUT:
          setOutputLessons(items);
          break;
        case LessonType.LESSON:
          setLessonLessons(items);
          break;
      }
      return items;
    } catch (e) {
      console.error(e);
      return [];
    } finally {
      setLoadingLessons(false);
    }
  };

  // ---------- Level actions ----------
  const nextLevelId = useMemo(() => {
    if (!roadmap?.levels?.length) return 1;
    return Math.max(...roadmap.levels.map((l) => l.id)) + 1;
  }, [roadmap]);

  const handleCreateLevel = () => {
    if (!roadmap) return;
    const newLevelObj: IRoadmapLevel = {
      id: nextLevelId,
      level: newLevel,
      nodes: [],
    };
    setRoadmap({ ...roadmap, levels: [...roadmap.levels, newLevelObj] });
    setIsCreatingLevel(false);
    setNewLevel(CourseLevel.LEVEL1);
  };

  const handleDeleteLevel = () => {
    if (!roadmap || deleteLevel.levelIndex < 0) return;
    const newLevels = roadmap.levels.filter(
      (_, idx) => idx !== deleteLevel.levelIndex
    );
    setRoadmap({ ...roadmap, levels: newLevels });
    setDeleteLevel({ show: false, levelIndex: -1 });
  };

  // ---------- Node actions ----------
  const openCreateNode = async (levelIndex: number) => {
    setTitleError("");
    if (!entranceLessons.length) await fetchLessonsByType(LessonType.ENTRANCE);
    if (!outputLessons.length) await fetchLessonsByType(LessonType.OUTPUT);
    setIsCreatingNode({ on: true, levelIndex });
  };

  const handleCreateNode = () => {
    setTitleError("");
    if (!roadmap) return;
    if (!newNodeTitle.trim()) {
      setTitleError("Vui lòng nhập tiêu đề node");
      return;
    }

    const levelIndex = isCreatingNode.levelIndex;
    if (levelIndex < 0) return;

    const entrance = entranceLessons[0] || null;
    const output = outputLessons[0] || null;

    const newNode: IRoadmapNode = {
      title: updateTranslationValue(undefined, lang, newNodeTitle),
      entranceId: entrance?._id || "",
      lessonIds: [],
      outputId: output?._id || "",
      entrance,
      lessons: [],
      output,
    };

    const newLevels = [...roadmap.levels];
    newLevels[levelIndex] = {
      ...newLevels[levelIndex],
      nodes: [...newLevels[levelIndex].nodes, newNode],
    };

    setRoadmap({ ...roadmap, levels: newLevels });
    setIsCreatingNode({ on: false, levelIndex: -1 });
    setNewNodeTitle("");
  };

  const confirmDeleteNode = () => {
    if (!roadmap || deleteNode.levelIndex < 0 || deleteNode.nodeIndex < 0)
      return;
    const newLevels = [...roadmap.levels];
    const level = newLevels[deleteNode.levelIndex];
    level.nodes = level.nodes.filter((_, idx) => idx !== deleteNode.nodeIndex);
    newLevels[deleteNode.levelIndex] = { ...level };
    setRoadmap({ ...roadmap, levels: newLevels });
    setDeleteNode({ show: false, levelIndex: -1, nodeIndex: -1 });
  };

  // ---------- Edit modal ----------
  const handleEditClick = async (
    levelIndex: number,
    nodeIndex: number,
    field: FieldKey
  ) => {
    let lessonList: ILessonBrief[] = [];
    if (field === "entrance") {
      lessonList = entranceLessons.length
        ? entranceLessons
        : await fetchLessonsByType(LessonType.ENTRANCE);
    } else if (field === "output") {
      lessonList = outputLessons.length
        ? outputLessons
        : await fetchLessonsByType(LessonType.OUTPUT);
    } else {
      lessonList = lessonLessons.length
        ? lessonLessons
        : await fetchLessonsByType(LessonType.LESSON);
    }

    const node = roadmap?.levels[levelIndex]?.nodes[nodeIndex];
    if (!node) return;

    setSelectedLessons(field === "lessons" ? [...(node.lessonIds || [])] : []);
    setEditingNode({
      levelIndex,
      nodeIndex,
      field,
      lessonList,
      currentValues:
        field === "lessons"
          ? [...(node.lessonIds || [])]
          : field === "entrance"
          ? node.entranceId
          : node.outputId,
    });
  };

  const applyNodeUpdate = (
    levelIndex: number,
    nodeIndex: number,
    updater: (node: IRoadmapNode) => IRoadmapNode
  ) => {
    if (!roadmap) return;
    const newLevels = [...roadmap.levels];
    const level = { ...newLevels[levelIndex] };
    const nodes = [...level.nodes];
    const updated = updater({ ...nodes[nodeIndex] });
    nodes[nodeIndex] = updated;
    level.nodes = nodes;
    newLevels[levelIndex] = level;
    setRoadmap({ ...roadmap, levels: newLevels });
  };

  const handleLessonSelect = (lessonId: string) => {
    if (!editingNode) return;
    const { field, levelIndex, nodeIndex, lessonList } = editingNode;

    if (field === "lessons") {
      const currentSelected = new Set(selectedLessons);
      if (currentSelected.has(lessonId)) currentSelected.delete(lessonId);
      else currentSelected.add(lessonId);
      const newSelected = Array.from(currentSelected);
      setSelectedLessons(newSelected);

      applyNodeUpdate(levelIndex, nodeIndex, (node) => ({
        ...node,
        lessonIds: newSelected,
        lessons: lessonList.filter((l) => newSelected.includes(l._id)),
      }));
    } else {
      const selected = lessonList.find((l) => l._id === lessonId) || null;
      if (field === "entrance") {
        applyNodeUpdate(levelIndex, nodeIndex, (node) => ({
          ...node,
          entranceId: selected?._id || "",
          entrance: selected,
        }));
      } else if (field === "output") {
        applyNodeUpdate(levelIndex, nodeIndex, (node) => ({
          ...node,
          outputId: selected?._id || "",
          output: selected,
        }));
      }
      setEditingNode(null);
      setSearchTerm("");
    }
  };

  const handleCompleteLessonSelection = () => {
    setEditingNode(null);
    setSearchTerm("");
    setSelectedLessons([]);
  };

  // ---------- Save ----------
  const handleSaveRoadmap = async () => {
    if (!roadmap) return;

    const payload: any = {
      levels: roadmap.levels.map((level) => ({
        id: level.id,
        level: level.level,
        nodes: level.nodes.map((n) => {
          const cleanedTitle = cleanTranslation(n.title);
          const nodePayload: any = {
            entranceId: n.entranceId || "",
            lessonIds: n.lessonIds || [],
            outputId: n.outputId || "",
          };

          // Only include title if it has values
          if (cleanedTitle) {
            nodePayload.title = cleanedTitle;
          }

          return nodePayload;
        }),
      })),
    };

    try {
      await courseService.updateRoadmap(courseId!, payload);
      showSuccess("Lưu roadmap thành công");
    } catch (e) {
      console.error(e);
      showError("Lưu roadmap thất bại");
    }
  };

  // ---------- Render helpers ----------
  const renderLessonBadge = (lesson: ILessonBrief | null | undefined) => {
    if (!lesson)
      return <div className="text-gray-500 italic">Chưa chọn bài học</div>;
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
    const title =
      getTranslationValue(lesson.title, lang) || "(Không có tiêu đề)";
    return (
      <div className={`flex items-center px-3 py-2 rounded-lg ${color} mb-2`}>
        <span className="mr-2">{icon}</span>
        <span>{title}</span>
      </div>
    );
  };

  const renderLessonSelector = () => {
    if (!editingNode) return null;
    const { field, lessonList } = editingNode;
    const isMultiple = field === "lessons";

    const filtered = searchTerm
      ? lessonList.filter((l) =>
          getTranslationValue(l.title, lang)
            .toLowerCase()
            .includes(searchTerm.toLowerCase())
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
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto" />
              <p className="mt-4 text-gray-600">Đang tải bài học...</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 max-h-96 overflow-y-auto">
              {filtered.map((lesson) => {
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
                    {renderLessonBadge(lesson)}
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

  // ---------- UI blocks ----------
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
        </div>

        {/* Levels, each with its own axis only when nodes exist */}
        <div className="space-y-20">
          {roadmap.levels.map((level, levelIndex) => (
            <div key={`lvl-${level.id}`} className="relative">
              {/* Level header with delete icon */}
              <div className="relative my-8">
                <div
                  onClick={() => setDeleteLevel({ show: true, levelIndex })}
                  className="bg-slate-100 shadow-lg rounded-full px-5 py-2 border inline-flex items-center space-x-3 cursor-pointer"
                >
                  <span
                    className={`px-3 py-1 text-lg font-semibold text-blue-600`}
                  >
                    {level.level}
                  </span>
                </div>
              </div>

              {/* Nodes section with its own central axis (only if nodes exist) */}
              <div className="relative">
                {level.nodes.length > 0 && (
                  <div className="absolute left-1/2 transform -translate-x-1/2 top-0 bottom-0 w-2 bg-gradient-to-b from-blue-400 to-blue-600 rounded-full" />
                )}

                <div className="space-y-16">
                  {level.nodes.length === 0 ? (
                    <div className="text-center text-gray-500 italic">
                      Chưa có node nào trong level này
                    </div>
                  ) : (
                    level.nodes.map((node, nodeIndex) => {
                      const isLeft = nodeIndex % 2 === 0;
                      const nodeTitle =
                        getTranslationValue(node.title, lang) ||
                        "Node chưa đặt tên";
                      return (
                        <div
                          key={`node-${levelIndex}-${nodeIndex}`}
                          className="relative"
                        >
                          {/* connection line from axis to card */}
                          <div
                            className={`absolute top-1/2 left-1/2 h-1 bg-blue-300 ${
                              isLeft
                                ? "-translate-y-1/2 -translate-x-full w-16"
                                : "-translate-y-1/2 w-16"
                            }`}
                          />
                          {/* center dot */}
                          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-4 h-4 bg-blue-500 rounded-full border-4 border-white shadow-lg z-10" />
                          {/* card */}
                          <div
                            className={`relative ${isLeft ? "pr-8" : "pl-8"}`}
                          >
                            <div
                              className={`bg-white rounded-xl shadow-lg p-6 w-full max-w-md ${
                                isLeft ? "mr-auto" : "ml-auto"
                              }`}
                            >
                              <div className="flex justify-between items-start mb-4">
                                <h3 className="text-lg font-semibold">
                                  {nodeTitle}
                                </h3>
                                {/* Delete node - icon only */}
                                <IconButton
                                  onClick={() =>
                                    setDeleteNode({
                                      show: true,
                                      levelIndex,
                                      nodeIndex,
                                    })
                                  }
                                  title="Xóa node"
                                  aria-label="Xóa node"
                                  className="bg-red-100 hover:bg-red-200 text-red-600"
                                >
                                  <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    className="w-5 h-5"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    strokeWidth={2}
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                  >
                                    <polyline points="3 6 5 6 21 6" />
                                    <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
                                    <path d="M10 11v6M14 11v6" />
                                    <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />
                                  </svg>
                                </IconButton>
                              </div>

                              <div className="space-y-4">
                                <div className="border-l-4 border-blue-500 pl-4">
                                  <div className="flex justify-between items-center mb-2">
                                    <h4 className="font-medium text-gray-700">
                                      Bài Đầu Vào
                                    </h4>
                                    <button
                                      className="text-blue-600 text-sm"
                                      onClick={() =>
                                        handleEditClick(
                                          levelIndex,
                                          nodeIndex,
                                          "entrance"
                                        )
                                      }
                                    >
                                      Chỉnh sửa
                                    </button>
                                  </div>
                                  {renderLessonBadge(node.entrance)}
                                </div>

                                <div className="border-l-4 border-purple-500 pl-4">
                                  <div className="flex justify-between items-center mb-2">
                                    <h4 className="font-medium text-gray-700">
                                      Các Bài Học
                                    </h4>
                                    <button
                                      className="text-blue-600 text-sm"
                                      onClick={() =>
                                        handleEditClick(
                                          levelIndex,
                                          nodeIndex,
                                          "lessons"
                                        )
                                      }
                                    >
                                      Chỉnh sửa
                                    </button>
                                  </div>
                                  {node.lessons && node.lessons.length > 0 ? (
                                    <ul className="space-y-2">
                                      {node.lessons.map((l) => (
                                        <li
                                          key={l._id}
                                          className="flex items-center"
                                        >
                                          <span className="mr-2">📖</span>
                                          <span className="text-sm">
                                            {getTranslationValue(
                                              l.title,
                                              lang
                                            ) || "Bài học chưa đặt tên"}
                                          </span>
                                        </li>
                                      ))}
                                    </ul>
                                  ) : (
                                    <p className="text-gray-500 italic text-sm">
                                      Chưa có bài học nào
                                    </p>
                                  )}
                                </div>

                                <div className="border-l-4 border-green-500 pl-4">
                                  <div className="flex justify-between items-center mb-2">
                                    <h4 className="font-medium text-gray-700">
                                      Bài Kết Thúc
                                    </h4>
                                    <button
                                      className="text-blue-600 text-sm"
                                      onClick={() =>
                                        handleEditClick(
                                          levelIndex,
                                          nodeIndex,
                                          "output"
                                        )
                                      }
                                    >
                                      Chỉnh sửa
                                    </button>
                                  </div>
                                  {renderLessonBadge(node.output)}
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              </div>

              {/* Level footer actions (below nodes) */}
              <div className="mt-8 flex justify-center">
                <div className="inline-flex gap-3">
                  {/* Add node - icon only */}
                  <IconButton
                    onClick={() => openCreateNode(levelIndex)}
                    title="Thêm node"
                    aria-label="Thêm node"
                    className="bg-green-100 hover:bg-green-200 text-green-600"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      className="w-5 h-5"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth={2}
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <line x1="12" y1="5" x2="12" y2="19" />
                      <line x1="5" y1="12" x2="19" y2="12" />
                    </svg>
                  </IconButton>
                </div>
              </div>

              {/* Create Node form below nodes */}
              {isCreatingNode.on &&
                isCreatingNode.levelIndex === levelIndex && (
                  <div className="mt-6 flex justify-center">
                    <div className="bg-white rounded-xl shadow p-5 w-full max-w-2xl">
                      <h4 className="font-semibold mb-3">Tạo Node Mới</h4>
                      <div className="mb-3">
                        <label className="block text-gray-700 mb-2">
                          Tiêu đề Node
                        </label>
                        <input
                          type="text"
                          className={`w-full px-3 py-2 border rounded-lg ${
                            titleError ? "border-red-500" : ""
                          }`}
                          value={newNodeTitle}
                          onChange={(e) => setNewNodeTitle(e.target.value)}
                          placeholder="Nhập tiêu đề node"
                        />
                        {titleError && (
                          <p className="text-red-500 text-sm mt-1">
                            {titleError}
                          </p>
                        )}
                      </div>
                      <div className="flex justify-end">
                        <button
                          className="px-4 py-2 bg-gray-200 rounded-lg mr-2"
                          onClick={() => {
                            setIsCreatingNode({ on: false, levelIndex: -1 });
                            setTitleError("");
                          }}
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
                  </div>
                )}
            </div>
          ))}
        </div>

        <div className="flex space-x-3 justify-end mt-6">
          <button
            className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors shadow-md"
            onClick={() => setIsCreatingLevel(true)}
          >
            Thêm Level
          </button>
          <button
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-md"
            onClick={handleSaveRoadmap}
          >
            Lưu Roadmap
          </button>
        </div>

        {/* Create Level */}
        {isCreatingLevel && (
          <div className="bg-white rounded-xl shadow-md p-6 mb-10">
            <h3 className="text-xl font-bold mb-4">Tạo Level Mới</h3>
            <div className="mb-4">
              <label className="block text-gray-700 mb-2">Cấp độ</label>
              <select
                className="w-full px-3 py-2 border rounded-lg"
                value={newLevel}
                onChange={(e) => setNewLevel(e.target.value as CourseLevel)}
              >
                <option value={CourseLevel.LEVEL1}>Level 1</option>
                <option value={CourseLevel.LEVEL2}>Level 2</option>
              </select>
            </div>
            <div className="flex justify-end">
              <button
                className="px-4 py-2 bg-gray-200 rounded-lg mr-2"
                onClick={() => setIsCreatingLevel(false)}
              >
                Hủy
              </button>
              <button
                className="px-4 py-2 bg-blue-600 text-white rounded-lg"
                onClick={handleCreateLevel}
              >
                Tạo Level
              </button>
            </div>
          </div>
        )}

        {/* Modals */}
        {renderLessonSelector()}

        {/* Delete Level Confirm */}
        {deleteLevel.show && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-lg p-6 w-full max-w-md">
              <h3 className="text-lg font-medium mb-2">Xóa Level</h3>
              <p className="text-sm text-gray-500 mb-4">
                Bạn có chắc muốn xóa level này?
              </p>
              <div className="flex justify-end">
                <button
                  className="px-4 py-2 bg-gray-200 rounded-lg mr-2"
                  onClick={() =>
                    setDeleteLevel({ show: false, levelIndex: -1 })
                  }
                >
                  Hủy
                </button>
                <button
                  className="px-4 py-2 bg-red-600 text-white rounded-lg"
                  onClick={handleDeleteLevel}
                >
                  Xóa
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Delete Node Confirm */}
        {deleteNode.show && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-lg p-6 w-full max-w-md">
              <h3 className="text-lg font-medium mb-2">Xóa Node</h3>
              <p className="text-sm text-gray-500 mb-4">
                Bạn có chắc muốn xóa node này?
              </p>
              <div className="flex justify-end">
                <button
                  className="px-4 py-2 bg-gray-200 rounded-lg mr-2"
                  onClick={() =>
                    setDeleteNode({
                      show: false,
                      levelIndex: -1,
                      nodeIndex: -1,
                    })
                  }
                >
                  Hủy
                </button>
                <button
                  className="px-4 py-2 bg-red-600 text-white rounded-lg"
                  onClick={confirmDeleteNode}
                >
                  Xóa
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default RoadmapPage;
