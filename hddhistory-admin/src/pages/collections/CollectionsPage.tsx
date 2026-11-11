import { useCallback, useEffect, useMemo, useState } from "react";
import { Button, Chip, CircularProgress } from "@mui/material";
import {
  closestCenter,
  DndContext,
  DragEndEvent,
  PointerSensor,
  useSensor,
  useSensors,
} from "@dnd-kit/core";
import {
  arrayMove,
  SortableContext,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { Pencil, Plus, Trash2 } from "lucide-react";

import CollectionEditDialog, {
  CourseOption,
} from "../../components/collections/CollectionEditDialog";
import SortableItem from "../../components/common/SortableItem";
import courseCollectionService from "../../services/courseCollectionService";
import { courseService } from "../../services/courseService";
import { segmentService } from "../../services/segmentService";
import {
  CourseCollectionPayload,
  CourseCollectionSlot,
  CourseCollectionStatus,
  ICourseCollection,
} from "../../types/interface/course-collection.interface";
import { SegmentOption } from "../../types/interface/segment.interface";
import unwrapApi from "../../utils/unwrapApi";

const SLOTS: { slot: CourseCollectionSlot; label: string; hint: string }[] = [
  {
    slot: CourseCollectionSlot.TOP,
    label: "Đầu trang",
    hint: "Nằm trên mục “Được học nhiều nhất”.",
  },
  {
    slot: CourseCollectionSlot.BOTTOM,
    label: "Cuối trang",
    hint: "Nằm dưới các chip “Tìm kiếm theo chủ đề”.",
  },
];

export default function CollectionsPage() {
  const [collections, setCollections] = useState<ICourseCollection[]>([]);
  const [segments, setSegments] = useState<SegmentOption[]>([]);
  const [courses, setCourses] = useState<CourseOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<ICourseCollection | null>(null);

  const sensors = useSensors(useSensor(PointerSensor));

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [rows, segmentBody, courseBody] = await Promise.all([
        courseCollectionService.list(),
        segmentService.list(),
        courseService.getList({ page: 1, take: 500, isAll: true }),
      ]);

      setCollections(rows);
      setSegments(unwrapApi<SegmentOption[]>(segmentBody) ?? []);

      const courseList =
        unwrapApi<{ items?: any[] }>(courseBody)?.items ?? [];
      setCourses(
        courseList.map((c) => ({
          _id: c._id,
          label: c.title?.vi || c.title?.en || c._id,
        })),
      );
    } catch (e: any) {
      setError(e?.message ?? "Không tải được danh sách bộ sưu tập");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const bySlot = useMemo(() => {
    const grouped = new Map<CourseCollectionSlot, ICourseCollection[]>();
    for (const { slot } of SLOTS) grouped.set(slot, []);
    for (const row of collections) {
      grouped.get(row.slot)?.push(row);
    }
    // Iterating the Map's values needs downlevelIteration under this
    // tsconfig; walking SLOTS gets the same job done without the flag.
    for (const { slot } of SLOTS) {
      grouped.get(slot)?.sort((a, b) => a.index - b.index);
    }
    return grouped;
  }, [collections]);

  const handleDragEnd = async (
    slot: CourseCollectionSlot,
    event: DragEndEvent,
  ) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;

    const list = bySlot.get(slot) ?? [];
    const from = list.findIndex((c) => c._id === active.id);
    const to = list.findIndex((c) => c._id === over.id);
    if (from < 0 || to < 0) return;

    const reordered = arrayMove(list, from, to);
    // Optimistic: the row moves under the cursor immediately. A failed save
    // reloads from the server rather than leaving the screen lying about the
    // order.
    setCollections((prev) =>
      prev.map((row) => {
        const position = reordered.findIndex((r) => r._id === row._id);
        return position < 0 ? row : { ...row, index: position };
      }),
    );

    try {
      await courseCollectionService.reorder(reordered.map((r) => r._id));
    } catch {
      await load();
    }
  };

  const handleSave = async (payload: CourseCollectionPayload) => {
    if (editing) {
      await courseCollectionService.update(editing._id, payload);
    } else {
      await courseCollectionService.create(payload);
    }
    await load();
  };

  const handleDelete = async (row: ICourseCollection) => {
    const name = row.title?.vi || row.title?.en || "bộ sưu tập này";
    if (!window.confirm(`Xoá “${name}”? Thao tác này không hoàn tác được.`)) {
      return;
    }
    await courseCollectionService.remove(row._id);
    await load();
  };

  if (loading) {
    return (
      <div className="flex justify-center p-10">
        <CircularProgress />
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-2">
        <div>
          <h1 className="text-xl font-semibold">Bộ sưu tập khoá học</h1>
          <p className="text-sm text-gray-500">
            Các dải khoá học do biên tập tự xếp trên tab Khám phá. Thứ tự ở đây
            là thứ tự người dùng nhìn thấy.
          </p>
        </div>
        <Button
          variant="contained"
          startIcon={<Plus className="w-4 h-4" />}
          onClick={() => {
            setEditing(null);
            setDialogOpen(true);
          }}
        >
          Tạo bộ sưu tập
        </Button>
      </div>

      {error && (
        <div className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-700">
          {error}{" "}
          <button className="underline" onClick={() => void load()}>
            Thử lại
          </button>
        </div>
      )}

      {SLOTS.map(({ slot, label, hint }) => {
        const list = bySlot.get(slot) ?? [];
        return (
          <section key={slot} className="mt-6">
            <h2 className="text-base font-semibold">{label}</h2>
            <p className="mb-3 text-sm text-gray-500">{hint}</p>

            {list.length === 0 ? (
              <p className="text-sm text-gray-400">Chưa có bộ sưu tập nào.</p>
            ) : (
              <DndContext
                sensors={sensors}
                collisionDetection={closestCenter}
                onDragEnd={(event) => void handleDragEnd(slot, event)}
              >
                <SortableContext
                  items={list.map((c) => c._id)}
                  strategy={verticalListSortingStrategy}
                >
                  <div className="flex flex-col gap-2">
                    {list.map((row) => (
                      <SortableItem key={row._id} id={row._id}>
                        <div className="flex items-center justify-between gap-3 rounded border border-gray-200 bg-white px-3 py-2">
                          <div className="min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="truncate font-medium">
                                {row.title?.vi || row.title?.en || "(chưa đặt tên)"}
                              </span>
                              {row.status ===
                              CourseCollectionStatus.PUBLISHED ? (
                                <Chip size="small" color="success" label="Đang hiện" />
                              ) : (
                                <Chip size="small" label="Nháp" />
                              )}
                            </div>
                            <div className="text-xs text-gray-500">
                              {row.courseIds?.length ?? 0} khoá ·{" "}
                              {row.segmentIds?.length
                                ? `${row.segmentIds.length} phân khúc`
                                : "mọi người dùng"}
                            </div>
                          </div>

                          <div className="flex items-center gap-1">
                            <button
                              type="button"
                              aria-label="Sửa bộ sưu tập"
                              className="p-2 text-gray-400 hover:text-gray-700"
                              onClick={() => {
                                setEditing(row);
                                setDialogOpen(true);
                              }}
                            >
                              <Pencil className="w-4 h-4" />
                            </button>
                            <button
                              type="button"
                              aria-label="Xoá bộ sưu tập"
                              className="p-2 text-gray-400 hover:text-red-500"
                              onClick={() => void handleDelete(row)}
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </div>
                      </SortableItem>
                    ))}
                  </div>
                </SortableContext>
              </DndContext>
            )}
          </section>
        );
      })}

      <CollectionEditDialog
        open={dialogOpen}
        collection={editing}
        segments={segments}
        courses={courses}
        onClose={() => setDialogOpen(false)}
        onSave={handleSave}
      />
    </div>
  );
}
