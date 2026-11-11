import { useEffect, useMemo, useState } from "react";
import {
  Autocomplete,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  MenuItem,
  Switch,
  TextField,
} from "@mui/material";
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
import { Trash2 } from "lucide-react";

import SegmentPicker from "../common/SegmentPicker";
import SortableItem from "../common/SortableItem";
import {
  COLLECTION_MAX_COURSES,
  CourseCollectionPayload,
  CourseCollectionSlot,
  CourseCollectionStatus,
  ICourseCollection,
} from "../../types/interface/course-collection.interface";
import { SegmentOption } from "../../types/interface/segment.interface";
import { ITranslation } from "../../utils/translate";

/** The five locales the app ships. A key missing here never reaches a reader. */
const LOCALES: { code: keyof ITranslation; label: string }[] = [
  { code: "vi", label: "Tiếng Việt" },
  { code: "en", label: "English" },
  { code: "zh", label: "中文" },
  { code: "ja", label: "日本語" },
  { code: "ko", label: "한국어" },
];

export interface CourseOption {
  _id: string;
  label: string;
}

interface Props {
  open: boolean;
  /** null = creating a new collection. */
  collection: ICourseCollection | null;
  segments: SegmentOption[];
  courses: CourseOption[];
  onClose: () => void;
  onSave: (payload: CourseCollectionPayload) => Promise<void>;
}

export default function CollectionEditDialog({
  open,
  collection,
  segments,
  courses,
  onClose,
  onSave,
}: Props) {
  const [title, setTitle] = useState<ITranslation>({});
  const [slot, setSlot] = useState<CourseCollectionSlot>(
    CourseCollectionSlot.BOTTOM,
  );
  const [published, setPublished] = useState(false);
  const [segmentIds, setSegmentIds] = useState<string[]>([]);
  const [courseIds, setCourseIds] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);

  // Reset from props on every open: reusing one dialog instance for "edit row
  // A" then "create new" would otherwise carry A's courses into the new row.
  useEffect(() => {
    if (!open) return;
    setTitle(collection?.title ?? {});
    setSlot(collection?.slot ?? CourseCollectionSlot.BOTTOM);
    setPublished(collection?.status === CourseCollectionStatus.PUBLISHED);
    setSegmentIds(collection?.segmentIds ?? []);
    setCourseIds(collection?.courseIds ?? []);
  }, [open, collection]);

  const sensors = useSensors(useSensor(PointerSensor));
  const courseById = useMemo(
    () => new Map(courses.map((c) => [c._id, c])),
    [courses],
  );

  const onDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;
    const from = courseIds.indexOf(String(active.id));
    const to = courseIds.indexOf(String(over.id));
    if (from < 0 || to < 0) return;
    setCourseIds(arrayMove(courseIds, from, to));
  };

  const canSave = Boolean(title.vi?.trim() || title.en?.trim());

  const handleSave = async () => {
    setSaving(true);
    try {
      await onSave({
        title,
        slot,
        status: published
          ? CourseCollectionStatus.PUBLISHED
          : CourseCollectionStatus.DRAFT,
        segmentIds,
        courseIds,
      });
      onClose();
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="md">
      <DialogTitle>
        {collection ? "Sửa bộ sưu tập" : "Bộ sưu tập mới"}
      </DialogTitle>

      <DialogContent dividers>
        <div className="grid grid-cols-2 gap-3">
          {LOCALES.map((locale) => (
            <TextField
              key={`title-${locale.code}`}
              size="small"
              label={`Tên (${locale.label})`}
              value={title[locale.code] ?? ""}
              onChange={(e) =>
                setTitle({ ...title, [locale.code]: e.target.value })
              }
            />
          ))}
        </div>


        <div className="h-4" />

        <div className="grid grid-cols-2 gap-3">
          <TextField
            select
            size="small"
            label="Vị trí trên tab Khám phá"
            value={slot}
            onChange={(e) => setSlot(e.target.value as CourseCollectionSlot)}
            helperText="Đầu trang = dải nằm trên mục Được học nhiều nhất. Cuối trang = nằm dưới các chip chủ đề."
          >
            <MenuItem value={CourseCollectionSlot.TOP}>Đầu trang</MenuItem>
            <MenuItem value={CourseCollectionSlot.BOTTOM}>Cuối trang</MenuItem>
          </TextField>

          <FormControlLabel
            control={
              <Switch
                checked={published}
                onChange={(e) => setPublished(e.target.checked)}
              />
            }
            label={published ? "Đang hiện trong app" : "Nháp (không hiện)"}
          />
        </div>

        <div className="h-4" />

        <SegmentPicker
          segments={segments}
          value={segmentIds}
          onChange={setSegmentIds}
          helperText="Bỏ trống = mọi người dùng. Muốn làm mục chỉ dành cho người mới thì chọn phân khúc có vòng đời D0–D7."
        />

        <div className="h-6" />

        <Autocomplete
          size="small"
          disabled={courseIds.length >= COLLECTION_MAX_COURSES}
          options={courses.filter((c) => !courseIds.includes(c._id))}
          getOptionLabel={(c) => c.label}
          value={null}
          // Clearing after each pick turns the field into an "add" control:
          // the chosen course moves down into the ordered list below, which is
          // the thing that actually decides what readers see.
          onChange={(_, selected) => {
            if (selected) setCourseIds([...courseIds, selected._id]);
          }}
          renderInput={(params) => (
            <TextField
              {...params}
              label="Thêm khoá học"
              helperText={
                courseIds.length >= COLLECTION_MAX_COURSES
                  ? `Đã đủ ${COLLECTION_MAX_COURSES} khoá — bỏ bớt một khoá nếu muốn thêm khoá khác.`
                  : `Tối đa ${COLLECTION_MAX_COURSES} khoá, đang có ${courseIds.length}.`
              }
            />
          )}
        />

        <div className="h-3" />

        <DndContext
          sensors={sensors}
          collisionDetection={closestCenter}
          onDragEnd={onDragEnd}
        >
          <SortableContext
            items={courseIds}
            strategy={verticalListSortingStrategy}
          >
            <div className="flex flex-col gap-2">
              {courseIds.map((id, index) => (
                <SortableItem key={id} id={id}>
                  <div className="flex items-center justify-between gap-3 rounded border border-gray-200 px-3 py-2">
                    <span className="text-sm">
                      <span className="text-gray-400 mr-2">{index + 1}.</span>
                      {/* A pinned course that no longer resolves still shows,
                          as its id — silently dropping it would hide from the
                          editor why their strip renders short. */}
                      {courseById.get(id)?.label ?? `(không còn khoá ${id})`}
                    </span>
                    <button
                      type="button"
                      aria-label="Bỏ khoá học khỏi bộ sưu tập"
                      className="text-gray-400 hover:text-red-500"
                      onClick={() =>
                        setCourseIds(courseIds.filter((c) => c !== id))
                      }
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </SortableItem>
              ))}

              {courseIds.length === 0 && (
                <p className="text-sm text-gray-500">
                  Chưa có khoá học nào. Bộ sưu tập rỗng sẽ không hiện trong app.
                </p>
              )}
            </div>
          </SortableContext>
        </DndContext>
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose}>Huỷ</Button>
        <Button
          variant="contained"
          disabled={!canSave || saving}
          onClick={handleSave}
        >
          {saving ? "Đang lưu…" : "Lưu"}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
