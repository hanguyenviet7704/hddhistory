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
import HomePopupCampaignCard from "../../components/home-popup/HomePopupCampaignCard";
import {
  HomePopupConfig,
  HomePopupItem,
  homePopupService,
} from "../../services/homePopupService";
import { segmentService } from "../../services/segmentService";
import { SegmentOption } from "../../types/interface/segment.interface";
import { PromoCampaignStats } from "../../utils/promoCampaignForm";
import { useNotification } from "../../utils/hooks/useNotification";

/** Same cap the API enforces (`@ArrayMaxSize(10)`) — fail here, not on Save. */
const MAX_POPUPS = 10;

const emptyItem = (): HomePopupItem => ({
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
  alwaysShow: false,
});

/**
 * A campaign card needs a stable key for drag-and-drop, and campaigns have no
 * id (their position IS part of their identity — see the schema). So the
 * editor keeps a local one that never leaves this page.
 */
type EditableItem = HomePopupItem & { uid: string };

let uidCounter = 0;
const withUid = (item: HomePopupItem): EditableItem => ({
  ...item,
  uid: `popup-${++uidCounter}`,
});

/**
 * Popup khuyến mãi trên màn Home: có thể xếp nhiều chiến dịch cùng lúc, app
 * chỉ hiện MỘT lần mỗi lần mở — chiến dịch còn trong khung thời gian, ưu tiên
 * (priority) cao nhất, và người đó chưa bấm. Ai bấm vào ảnh thì không thấy lại
 * đúng chiến dịch đó nữa; ai đóng đi thì lần mở app sau vẫn thấy. Ảnh, link,
 * thị trường/ngôn ngữ và bật/tắt đều là config nên chạy chiến dịch không cần
 * phát hành app.
 */
const HomePopupPage: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [enabled, setEnabled] = useState(false);
  const [items, setItems] = useState<EditableItem[]>([]);
  // Read-only, aligned by index with `items` as loaded — never touched by edits.
  const [popupStats, setPopupStats] = useState<PromoCampaignStats[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploadingCount, setUploadingCount] = useState(0);
  const [error, setError] = useState<string | null>(null);
  // Loaded once here and shared across every campaign card — not re-fetched per card.
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
      const res = await homePopupService.get();
      const d = (res?.data ?? {}) as Partial<HomePopupConfig>;
      setEnabled(d.enabled ?? false);
      // A config saved before the campaign list existed has no `popups` and one
      // flat popup: seed it as campaign 1 so it is not lost, and the first Save
      // writes it into the new shape. Mirrors the Home banner editor and the
      // server's own `resolveConfiguredPopups`.
      const stored = d.popups?.length
        ? d.popups
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
                // Cấu hình cũ (một popup phẳng) chưa từng có ô này.
                alwaysShow: false,
              },
            ]
          : [];
      setItems(stored.map(withUid));
      setPopupStats(d.popupStats ?? []);
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
      await homePopupService.update({
        enabled,
        // uid is editor-local and must not reach the API.
        popups: items.map(({ uid, ...item }) => item),
      });
      showSuccess("Đã lưu cấu hình");
      // Reload so the campaign keys/stats shown are what the server computed,
      // not a guess made here.
      await load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Lưu thất bại");
    } finally {
      setSaving(false);
    }
  };

  const patchItem = (uid: string, patch: Partial<HomePopupItem>) =>
    setItems((prev) =>
      prev.map((item) => (item.uid === uid ? { ...item, ...patch } : item)),
    );

  const removeItem = (uid: string) =>
    setItems((prev) => prev.filter((item) => item.uid !== uid));

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;
    setItems((prev) => {
      const from = prev.findIndex((i) => i.uid === active.id);
      const to = prev.findIndex((i) => i.uid === over.id);
      if (from < 0 || to < 0) return prev;
      return arrayMove(prev, from, to);
    });
  };

  const busy = saving || uploadingCount > 0;
  const liveCount = items.filter((i) => (i.enabled ?? true) && i.imageUrl).length;

  return (
    <div className="p-6">
      <header className="mb-5">
        <h1 className="text-xl font-semibold">Popup Home</h1>
        <p className="mt-1 max-w-2xl text-sm text-gray-500">
          Popup hiện trên màn Home, tối đa một lần mỗi lần mở app. Có thể xếp
          nhiều chiến dịch — app chọn chiến dịch còn trong khung thời gian,
          ưu tiên (priority) cao nhất mà người đó chưa bấm. Ai{" "}
          <strong>bấm vào ảnh</strong> thì không thấy lại đúng chiến dịch đó
          nữa; ai đóng đi thì lần mở app sau vẫn thấy. Chữ nằm trong ảnh,
          không có ô nhập text — nhờ vậy không phải dịch ra 5 ngôn ngữ app
          đang chạy.
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
            label="Hiện popup trên app"
          />
          <p className="mb-5 mt-1 text-xs text-gray-500">
            Tắt là popup ngừng hiện ngay (app cache tối đa 60 giây), không cần
            phát hành bản mới. Bật/tắt <strong>không</strong> làm mới chiến
            dịch nào — ai đã bấm vẫn không thấy lại. Mỗi chiến dịch còn có
            công tắc riêng để chuẩn bị trước.
          </p>

          <div className="mb-2 flex items-baseline justify-between">
            <p className="text-sm font-medium text-gray-700">
              Chiến dịch ({items.length}/{MAX_POPUPS})
            </p>
            <p className="text-xs text-gray-500">
              {liveCount === 0
                ? "Chưa chiến dịch nào hiện được"
                : `${liveCount} chiến dịch sẵn sàng — kéo để đổi thứ tự ưu tiên khi bằng điểm`}
            </p>
          </div>

          {items.length === 0 ? (
            <p className="mb-4 rounded border border-dashed border-gray-300 px-3 py-6 text-center text-sm text-gray-500">
              Chưa có chiến dịch nào. Thêm chiến dịch rồi tải ảnh lên.
            </p>
          ) : (
            <DndContext
              sensors={sensors}
              collisionDetection={closestCenter}
              onDragEnd={handleDragEnd}
            >
              <SortableContext
                items={items.map((i) => i.uid)}
                strategy={verticalListSortingStrategy}
              >
                <div className="mb-4 flex flex-col gap-3">
                  {items.map((item, index) => (
                    <SortableItem key={item.uid} id={item.uid}>
                      <HomePopupCampaignCard
                        item={item}
                        position={index + 1}
                        stats={popupStats[index]}
                        segments={segments}
                        onChange={(patch) => patchItem(item.uid, patch)}
                        onRemove={() => removeItem(item.uid)}
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
            disabled={items.length >= MAX_POPUPS}
            onClick={() => setItems((prev) => [...prev, withUid(emptyItem())])}
          >
            Thêm chiến dịch
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
            App chỉ hiện một chiến dịch khi <strong>công tắc tổng đang bật</strong>
            , <strong>chiến dịch đang bật</strong>, <strong>có ảnh</strong> và còn
            trong khung thời gian. Ảnh hiện nguyên tỉ lệ, không crop.
          </p>
        </Paper>
      )}
    </div>
  );
};

export default HomePopupPage;
