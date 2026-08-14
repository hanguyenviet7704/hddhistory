import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  CircularProgress,
  FormControlLabel,
  Paper,
  Switch,
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
import { Plus } from "lucide-react";

import SortableItem from "../../components/common/SortableItem";
import HomeBannerSlideCard from "../../components/home-banner/HomeBannerSlideCard";
import {
  HomeBannerConfig,
  HomeBannerSlide,
  homeBannerService,
} from "../../services/homeBannerService";
import { segmentService } from "../../services/segmentService";
import { SegmentOption } from "../../types/interface/segment.interface";
import { PromoCampaignStats } from "../../utils/promoCampaignForm";
import { useNotification } from "../../utils/hooks/useNotification";

/** Same cap the API enforces (`@ArrayMaxSize(10)`) — fail here, not on Save. */
const MAX_SLIDES = 10;

const emptySlide = (): HomeBannerSlide => ({
  name: "",
  imageUrl: "",
  linkUrl: "",
  countries: [],
  locales: [],
  segmentIds: [],
  priority: 0,
  startAt: null,
  endAt: null,
  enabled: true,
});

/**
 * A slide row needs a stable key for drag-and-drop, and slides have no id (their
 * position IS their identity — see the schema). So the editor keeps a local one
 * that never leaves this page.
 */
type EditableSlide = HomeBannerSlide & { uid: string };

let uidCounter = 0;
const withUid = (slide: HomeBannerSlide): EditableSlide => ({
  ...slide,
  uid: `slide-${++uidCounter}`,
});

/**
 * Carousel khuyến mãi trên màn Home của app (design "2 · Home"): dải ảnh
 * full-width nằm giữa "Khóa học mới hôm nay" và "Jump back in". Ảnh, link, thị
 * trường và bật/tắt đều là config nên chạy chiến dịch không cần phát hành app.
 */
const HomeBannerPage: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [enabled, setEnabled] = useState(false);
  const [slides, setSlides] = useState<EditableSlide[]>([]);
  // Read-only, aligned by index with `slides` as loaded — never touched by edits.
  const [slideStats, setSlideStats] = useState<PromoCampaignStats[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploadingCount, setUploadingCount] = useState(0);
  const [error, setError] = useState<string | null>(null);
  // Loaded once here and shared across every slide card — not re-fetched per card.
  const [segments, setSegments] = useState<SegmentOption[]>([]);

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } }),
  );

  useEffect(() => {
    (async () => {
      try {
        const res = await segmentService.list();
        setSegments((res.data ?? []).map((s: { _id: string; name: string }) => ({
          _id: s._id,
          name: s.name,
        })));
      } catch (err) {
        // Non-critical: targeting by segment just falls back to an empty
        // picker, everything else on this page still works.
        console.error("Failed to load segments", err);
      }
    })();
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await homeBannerService.get();
      const d = (res?.data ?? {}) as Partial<HomeBannerConfig>;
      setEnabled(d.enabled ?? false);
      // A config saved before the carousel existed has no `slides` and one
      // banner: seed it as slide 1 so the campaign already staged is not lost
      // and the first Save writes it into the new shape. Mirrors
      // `resolveConfiguredSlides` on the server.
      const stored = d.slides?.length
        ? d.slides
        : d.imageUrl
          ? [
              {
                name: "",
                imageUrl: d.imageUrl,
                linkUrl: d.linkUrl ?? "",
                countries: d.countries ?? [],
                locales: [],
                priority: 0,
                startAt: null,
                endAt: null,
                enabled: true,
              },
            ]
          : [];
      setSlides(stored.map(withUid));
      setSlideStats(d.slideStats ?? []);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được cấu hình");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const save = async () => {
    setSaving(true);
    try {
      await homeBannerService.update({
        enabled,
        // uid is editor-local and must not reach the API.
        slides: slides.map(({ uid, ...slide }) => slide),
      });
      showSuccess("Đã lưu cấu hình");
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Lưu thất bại");
    } finally {
      setSaving(false);
    }
  };

  const patchSlide = (uid: string, patch: Partial<HomeBannerSlide>) =>
    setSlides((prev) =>
      prev.map((slide) => (slide.uid === uid ? { ...slide, ...patch } : slide)),
    );

  const removeSlide = (uid: string) =>
    setSlides((prev) => prev.filter((slide) => slide.uid !== uid));

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;
    setSlides((prev) => {
      const from = prev.findIndex((s) => s.uid === active.id);
      const to = prev.findIndex((s) => s.uid === over.id);
      if (from < 0 || to < 0) return prev;
      return arrayMove(prev, from, to);
    });
  };

  const busy = saving || uploadingCount > 0;
  const shownCount = slides.filter((s) => s.enabled && s.imageUrl).length;

  return (
    <div className="p-6">
      <header className="mb-5">
        <h1 className="text-xl font-semibold">Banner Home</h1>
        <p className="mt-1 max-w-2xl text-sm text-gray-500">
          Carousel ảnh full-width trên màn Home của app, nằm giữa khối "Khóa học
          mới hôm nay" và "Jump back in". Nhiều slide thì app tự chạy 5 giây một
          slide và hiện dots; một slide thì đứng yên như banner thường.
        </p>
      </header>

      {loading ? (
        <div className="flex justify-center py-16">
          <CircularProgress size={26} />
        </div>
      ) : (
        <Paper variant="outlined" className="max-w-xl p-5">
          {error && (
            <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-700">
              {error}
            </p>
          )}

          <FormControlLabel
            control={
              <Switch
                checked={enabled}
                onChange={(e) => setEnabled(e.target.checked)}
              />
            }
            label="Hiện banner trên app"
          />
          <p className="mb-5 mt-1 text-xs text-gray-500">
            Tắt là cả khu banner biến mất khỏi app ngay (app cache tối đa 60
            giây), không cần phát hành bản mới. Mỗi slide còn có công tắc riêng
            để chuẩn bị trước chiến dịch.
          </p>

          <div className="mb-2 flex items-baseline justify-between">
            <p className="text-sm font-medium text-gray-700">
              Slide ({slides.length}/{MAX_SLIDES})
            </p>
            <p className="text-xs text-gray-500">
              {shownCount === 0
                ? "Chưa slide nào hiện được"
                : `${shownCount} slide sẽ hiện — kéo để đổi thứ tự`}
            </p>
          </div>

          {slides.length === 0 ? (
            <p className="mb-4 rounded border border-dashed border-gray-300 px-3 py-6 text-center text-sm text-gray-500">
              Chưa có slide nào. Thêm slide rồi tải ảnh lên.
            </p>
          ) : (
            <DndContext
              sensors={sensors}
              collisionDetection={closestCenter}
              onDragEnd={handleDragEnd}
            >
              <SortableContext
                items={slides.map((s) => s.uid)}
                strategy={verticalListSortingStrategy}
              >
                <div className="mb-4 flex flex-col gap-3">
                  {slides.map((slide, index) => (
                    <SortableItem key={slide.uid} id={slide.uid}>
                      <HomeBannerSlideCard
                        slide={slide}
                        position={index + 1}
                        stats={slideStats[index]}
                        segments={segments}
                        onChange={(patch) => patchSlide(slide.uid, patch)}
                        onRemove={() => removeSlide(slide.uid)}
                        onUploadingChange={(uploading) =>
                          setUploadingCount((n) => n + (uploading ? 1 : -1))
                        }
                        onError={showError}
                        onSuccess={showSuccess}
                      />
                    </SortableItem>
                  ))}
                </div>
              </SortableContext>
            </DndContext>
          )}

          <Button
            size="small"
            startIcon={<Plus className="h-4 w-4" />}
            disabled={slides.length >= MAX_SLIDES}
            onClick={() => setSlides((prev) => [...prev, withUid(emptySlide())])}
          >
            Thêm slide
          </Button>

          <div className="mt-6 flex items-center gap-3">
            <Button variant="contained" onClick={save} disabled={busy}>
              {saving ? "Đang lưu..." : "Lưu"}
            </Button>
            <Button onClick={load} disabled={busy}>
              Khôi phục
            </Button>
          </div>

          <p className="mt-5 border-t pt-4 text-xs leading-relaxed text-gray-500">
            App chỉ hiện một slide khi <strong>công tắc tổng đang bật</strong>,{" "}
            <strong>slide đang bật</strong> và <strong>có ảnh</strong>. Ảnh hiển
            thị cao 78pt, bo góc 18 — nên dùng ảnh tỉ lệ ~5:1 (ví dụ 1170 × 234)
            để không bị crop lệch.
          </p>
        </Paper>
      )}
    </div>
  );
};

export default HomeBannerPage;
