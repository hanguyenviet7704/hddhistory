import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  Alert,
  Button,
  CircularProgress,
  FormControl,
  IconButton,
  InputLabel,
  ListSubheader,
  MenuItem,
  Paper,
  Select,
  Tab,
  Tabs,
  TextField,
  Tooltip,
} from "@mui/material";
import { Copy, HelpCircle } from "lucide-react";

import { courseService } from "../../services/courseService";
import { deeplinkService } from "../../services/deeplinkService";
import { lessonService } from "../../services/lessonService";
import { skillsetService } from "../../services/skillsetService";
import { IRoadmap } from "../../types/interface/course.interface";
import {
  IDeeplinkDestination,
  IDeeplinkParam,
} from "../../types/interface/deeplink.interface";
import { ITranslation } from "../../utils/translate";
import {
  DEEPLINK_APP_BASE,
  DEEPLINK_WEB_BASE,
  DeeplinkUtm,
  buildDeeplinkUrl,
} from "../../utils/deeplinkUrl";
import { useNotification } from "../../utils/hooks/useNotification";

interface Option {
  id: string;
  label: string;
}

const labelOf = (title?: ITranslation): string =>
  title?.vi || title?.en || "(chưa có tên)";

/** Nhãn tiếng Việt cho tham số, để marketer không phải đọc tên khoá. */
const PARAM_LABELS: Record<string, string> = {
  courseId: "Khoá học",
  keypointId: "Keypoint (bài cụ thể)",
  skillsetId: "Kỹ năng",
  variant: "Biến thể paywall",
};

const paramLabel = (param: IDeeplinkParam): string =>
  PARAM_LABELS[param.name] ?? param.name;

/**
 * Preset UTM. Cố tình để ở admin, KHÔNG lấy từ API như danh mục màn: đây là
 * phân loại kênh marketing, app không đọc và không route theo nó, nên nó không
 * phải hợp đồng giữa các stack. Thêm một kênh mới chỉ cần sửa file này.
 *
 * `utm_campaign` / `utm_content` / `utm_term` để nhập tay chứ không dropdown:
 * tên chiến dịch là mới mỗi lần, một danh sách preset sẽ cũ ngay tuần sau.
 */
const UTM_SOURCES = [
  "facebook",
  "instagram",
  "zalo",
  "tiktok",
  "telegram",
  "youtube",
  "google",
  "email",
  "sms",
  "qr",
];

const UTM_MEDIUMS = [
  "cpc",
  "paid_social",
  "organic_social",
  "push",
  "email",
  "sms",
  "referral",
  "qr",
  "banner",
];

const NOT_USED = "";

/** Nhãn + dấu (?) kèm tooltip, dùng lại cho mọi field và mọi ô kết quả. */
function LabelWithHelp({ text, help }: { text: string; help: string }) {
  return (
    <span className="flex items-center gap-1">
      {text}
      <Tooltip title={help} arrow>
        <span className="flex cursor-help items-center text-gray-400">
          <HelpCircle size={14} aria-label={`Giải thích: ${text}`} />
        </span>
      </Tooltip>
    </span>
  );
}

export default function DeeplinkGenerator() {
  const { showSuccess, showError } = useNotification();

  const [destinations, setDestinations] = useState<IDeeplinkDestination[]>([]);
  const [isLoadingCatalog, setIsLoadingCatalog] = useState(true);
  const [catalogError, setCatalogError] = useState("");

  const [selectedKey, setSelectedKey] = useState("");
  const [paramValues, setParamValues] = useState<Record<string, string>>({});
  const [utm, setUtm] = useState<DeeplinkUtm>({});
  const [tab, setTab] = useState(0);

  const [courses, setCourses] = useState<Option[]>([]);
  const [skillsets, setSkillsets] = useState<Option[]>([]);
  const [lessons, setLessons] = useState<Option[]>([]);
  const [keypoints, setKeypoints] = useState<Option[]>([]);
  const [isLoadingLessons, setIsLoadingLessons] = useState(false);
  const [isLoadingKeypoints, setIsLoadingKeypoints] = useState(false);
  // Bước trung gian của picker keypoint. KHÔNG phải tham số của link.
  const [lessonId, setLessonId] = useState("");

  const loadCatalog = useCallback(async () => {
    setIsLoadingCatalog(true);
    setCatalogError("");
    try {
      setDestinations(await deeplinkService.getDestinations());
    } catch (error) {
      console.error("Failed to load deeplink destinations", error);
      setCatalogError("Không tải được danh mục màn.");
    } finally {
      setIsLoadingCatalog(false);
    }
  }, []);

  useEffect(() => {
    loadCatalog();
  }, [loadCatalog]);

  const selected = useMemo(
    () => destinations.find((destination) => destination.key === selectedKey),
    [destinations, selectedKey]
  );

  // Đổi màn thì xoá hết giá trị cũ: giữ lại một courseId của màn trước sẽ sinh
  // ra link trông hợp lệ mà trỏ vào tham số của màn khác.
  const handleSelectDestination = (key: string) => {
    setSelectedKey(key);
    setParamValues({});
    setLessonId("");
    setLessons([]);
    setKeypoints([]);
  };

  const needsPicker = useCallback(
    (picker: IDeeplinkParam["picker"]) =>
      selected?.params.some((param) => param.picker === picker) ?? false,
    [selected]
  );

  const needsCourses = needsPicker("course") || needsPicker("keypoint");
  const needsSkillsets = needsPicker("skillset");
  const needsKeypoints = needsPicker("keypoint");

  useEffect(() => {
    if (!needsCourses) return;
    let isActive = true;
    (async () => {
      try {
        const response = await courseService.getList({
          isAll: true,
          take: 1000,
        });
        if (!isActive) return;
        setCourses(
          (response.data?.items ?? []).map((course: any) => ({
            id: course._id,
            label: labelOf(course.title),
          }))
        );
      } catch (error) {
        console.error("Failed to load courses", error);
        showError("Không tải được danh sách khoá học");
      }
    })();
    return () => {
      isActive = false;
    };
  }, [needsCourses, showError]);

  useEffect(() => {
    if (!needsSkillsets) return;
    let isActive = true;
    (async () => {
      try {
        const response = await skillsetService.getList({
          isAll: true,
          take: 1000,
        });
        if (!isActive) return;
        setSkillsets(
          (response.data?.items ?? []).map((skillset: any) => ({
            id: skillset._id,
            label: labelOf(skillset.title),
          }))
        );
      } catch (error) {
        console.error("Failed to load skillsets", error);
        showError("Không tải được danh sách kỹ năng");
      }
    })();
    return () => {
      isActive = false;
    };
  }, [needsSkillsets, showError]);

  const courseId = paramValues.courseId ?? "";

  // Course đổi → nạp lại danh sách bài từ roadmap, và bỏ keypoint đã chọn:
  // keypoint của course cũ không còn nghĩa gì ở course mới.
  useEffect(() => {
    if (!needsKeypoints || !courseId) {
      setLessons([]);
      return;
    }
    let isActive = true;
    setIsLoadingLessons(true);
    setLessonId("");
    setKeypoints([]);
    setParamValues((previous) => ({ ...previous, keypointId: "" }));
    (async () => {
      try {
        const res = await courseService.getRoadmap(courseId);
        const roadmap: IRoadmap = res.data?.data || res.data;
        if (!isActive) return;
        setLessons(
          (roadmap?.levels ?? []).flatMap((level) =>
            (level.nodes ?? []).flatMap((node) =>
              (node.lessons ?? []).map((lesson) => ({
                id: lesson._id,
                label: labelOf(lesson.title),
              }))
            )
          )
        );
      } catch (error) {
        console.error("Failed to load roadmap lessons", error);
        if (isActive) setLessons([]);
      } finally {
        if (isActive) setIsLoadingLessons(false);
      }
    })();
    return () => {
      isActive = false;
    };
  }, [courseId, needsKeypoints]);

  useEffect(() => {
    if (!lessonId) {
      setKeypoints([]);
      return;
    }
    let isActive = true;
    setIsLoadingKeypoints(true);
    (async () => {
      try {
        const res = await lessonService.getById(lessonId);
        const lesson = res.data?.data ?? res.data;
        if (!isActive) return;
        setKeypoints(
          (lesson?.keypoints ?? []).map((keypoint: any) => ({
            id: keypoint._id,
            label: labelOf(keypoint.title),
          }))
        );
      } catch (error) {
        console.error("Failed to load keypoints", error);
        if (isActive) setKeypoints([]);
      } finally {
        if (isActive) setIsLoadingKeypoints(false);
      }
    })();
    return () => {
      isActive = false;
    };
  }, [lessonId]);

  const missingRequired = useMemo(
    () =>
      (selected?.params ?? []).filter(
        (param) => param.required && !(paramValues[param.name] ?? "").trim()
      ),
    [selected, paramValues]
  );

  const isReady = Boolean(selected) && missingRequired.length === 0;

  const webUrl = selected
    ? buildDeeplinkUrl(DEEPLINK_WEB_BASE, selected.key, paramValues, utm)
    : "";
  const appUrl = selected
    ? buildDeeplinkUrl(DEEPLINK_APP_BASE, selected.key, paramValues)
    : "";

  const groups = useMemo<[string, IDeeplinkDestination[]][]>(() => {
    const byGroup = new Map<string, IDeeplinkDestination[]>();
    destinations.forEach((destination) => {
      byGroup.set(destination.group, [
        ...(byGroup.get(destination.group) ?? []),
        destination,
      ]);
    });
    // Array.from, không phải spread: target tsconfig của CRA này chưa bật
    // downlevelIteration nên spread một IterableIterator là lỗi biên dịch.
    return Array.from(byGroup.entries());
  }, [destinations]);

  const copy = async (value: string) => {
    if (!value) return;
    try {
      await navigator.clipboard.writeText(value);
      showSuccess("Đã copy");
    } catch (error) {
      console.error("Clipboard write failed", error);
      showError("Không copy được — bôi đen rồi copy tay nhé");
    }
  };

  const setParam = (name: string, value: string) =>
    setParamValues((previous) => ({ ...previous, [name]: value }));

  const setUtmField = (field: keyof DeeplinkUtm, value: string) =>
    setUtm((previous) => ({ ...previous, [field]: value }));

  const renderParamField = (param: IDeeplinkParam) => {
    const value = paramValues[param.name] ?? "";
    const isMissing = param.required && !value.trim();
    const label = `${paramLabel(param)}${param.required ? " *" : ""}`;

    if (param.picker === "text") {
      return (
        <TextField
          key={param.name}
          fullWidth
          size="small"
          label={label}
          value={value}
          error={isMissing}
          helperText={isMissing ? "Bắt buộc" : " "}
          onChange={(e) => setParam(param.name, e.target.value)}
        />
      );
    }

    let options: Option[] = [];
    let isLoadingOptions = false;
    let emptyHint = "";

    if (param.picker === "course") {
      options = courses;
      emptyHint = "Chưa tải được khoá học nào";
    } else if (param.picker === "skillset") {
      options = skillsets;
      emptyHint = "Chưa tải được kỹ năng nào";
    } else if (param.picker === "select") {
      options = (param.options ?? []).map((option) => ({
        id: option,
        label: option,
      }));
    } else if (param.picker === "keypoint") {
      options = keypoints;
      isLoadingOptions = isLoadingKeypoints;
      emptyHint = lessonId
        ? "Bài này chưa có keypoint"
        : "Chọn bài học ở trên trước";
    }

    return (
      <div key={param.name}>
        {param.picker === "keypoint" && (
          <FormControl fullWidth size="small" className="mb-3">
            <InputLabel id={`lesson-label-${param.name}`}>Bài học</InputLabel>
            <Select
              labelId={`lesson-label-${param.name}`}
              label="Bài học"
              value={lessonId}
              disabled={!courseId || isLoadingLessons}
              onChange={(e) => setLessonId(e.target.value)}
            >
              {lessons.length === 0 && (
                <MenuItem value="" disabled>
                  {isLoadingLessons
                    ? "Đang tải…"
                    : courseId
                      ? "Khoá học này chưa có bài học"
                      : "Chọn khoá học trước"}
                </MenuItem>
              )}
              {lessons.map((lesson) => (
                <MenuItem key={lesson.id} value={lesson.id}>
                  {lesson.label}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        )}

        <FormControl fullWidth size="small" error={isMissing}>
          <InputLabel id={`param-label-${param.name}`}>{label}</InputLabel>
          <Select
            labelId={`param-label-${param.name}`}
            label={label}
            value={value}
            onChange={(e) => setParam(param.name, e.target.value)}
          >
            {!param.required && <MenuItem value="">— Không dùng —</MenuItem>}
            {options.length === 0 && (
              <MenuItem value="" disabled>
                {isLoadingOptions ? "Đang tải…" : emptyHint}
              </MenuItem>
            )}
            {options.map((option) => (
              <MenuItem key={option.id} value={option.id}>
                {option.label}
              </MenuItem>
            ))}
          </Select>
          <p className="mt-1 min-h-[20px] text-xs text-red-600">
            {isMissing ? "Bắt buộc" : ""}
          </p>
        </FormControl>
      </div>
    );
  };

  const renderUtmSelect = (
    field: keyof DeeplinkUtm,
    label: string,
    help: string,
    options: string[]
  ) => (
    <FormControl fullWidth size="small">
      <InputLabel id={`utm-${field}`} shrink>
        {label}
      </InputLabel>
      <Select
        labelId={`utm-${field}`}
        label={label}
        notched
        displayEmpty
        value={utm[field] ?? NOT_USED}
        onChange={(e) => setUtmField(field, e.target.value)}
      >
        <MenuItem value={NOT_USED}>— Không dùng —</MenuItem>
        {options.map((option) => (
          <MenuItem key={option} value={option}>
            {option}
          </MenuItem>
        ))}
      </Select>
      <p className="mt-1 text-xs text-gray-500">{help}</p>
    </FormControl>
  );

  /** Ô kết quả: tiêu đề + (?) + nút Copy ở hàng tiêu đề, giá trị mono bên dưới. */
  const renderResultBox = (
    title: string,
    help: string,
    value: string,
    hint: string
  ) => (
    <div className="rounded-lg border border-gray-200 bg-gray-50 p-4">
      <div className="mb-2 flex items-start justify-between gap-3">
        <div className="text-sm font-semibold">
          <LabelWithHelp text={title} help={help} />
        </div>
        <Button
          size="small"
          variant="outlined"
          startIcon={<Copy size={14} />}
          disabled={!isReady || !value}
          onClick={() => copy(value)}
        >
          Copy
        </Button>
      </div>
      <p className="break-all font-mono text-sm text-gray-800">
        {isReady ? value : "— chọn màn hình (và điền ô bắt buộc) để sinh link —"}
      </p>
      <p className="mt-2 text-xs text-gray-500">{hint}</p>
    </div>
  );

  const sectionTitle = (title: string, desc: string) => (
    <div className="mb-4">
      <h2 className="text-base font-semibold">{title}</h2>
      <p className="mt-1 text-sm text-gray-500">{desc}</p>
    </div>
  );

  return (
    <div className="p-6">
      <h1 className="mb-5 text-2xl font-semibold">Link Builder</h1>

      {isLoadingCatalog ? (
        <div className="flex justify-center py-16">
          <CircularProgress size={26} />
        </div>
      ) : catalogError ? (
        <Alert
          severity="error"
          action={
            <Button color="inherit" size="small" onClick={loadCatalog}>
              Thử lại
            </Button>
          }
        >
          {catalogError}
        </Alert>
      ) : (
        <Paper variant="outlined" className="p-6">
          {/* ── Chọn đích đến ─────────────────────────────────────────────── */}
          <section>
            {sectionTitle(
              "Chọn đích đến",
              "Chọn màn hình cần dẫn tới — các ô bên cạnh hiện theo màn đã chọn."
            )}

            <FormControl fullWidth size="small">
              <InputLabel id="destination-label">
                <LabelWithHelp
                  text="Màn hình"
                  help="Khoá trong ngoặc là thứ đi vào link. Đổi tên màn trong app không làm chết link đã phát ra, vì link mang khoá này chứ không mang đường dẫn."
                />
              </InputLabel>
              <Select
                labelId="destination-label"
                label="Màn hình"
                value={selectedKey}
                onChange={(e) => handleSelectDestination(e.target.value)}
              >
                {groups.map(([group, items]) => [
                  <ListSubheader key={`group-${group}`}>{group}</ListSubheader>,
                  ...items.map((destination) => (
                    <MenuItem key={destination.key} value={destination.key}>
                      {`${destination.label} (${destination.key})`}
                    </MenuItem>
                  )),
                ])}
              </Select>
            </FormControl>

            {selected && (
              <>
                {selected.params.length > 0 && (
                  <div className="mt-4 grid grid-cols-1 gap-x-4 md:grid-cols-2">
                    {selected.params.map(renderParamField)}
                  </div>
                )}

                <div className="mt-3 flex flex-col gap-2">
                  {selected.note && (
                    <Alert severity="info">{selected.note}</Alert>
                  )}
                  <Alert severity="warning">
                    {`Chỉ hoạt động trên bản app build ≥ ${selected.minAppBuild}. Người dùng bản cũ hơn sẽ về Trang chủ.`}
                  </Alert>
                </div>
              </>
            )}
          </section>

          <hr className="my-6 border-gray-200" />

          {/* ── Gắn UTM ──────────────────────────────────────────────────── */}
          <section>
            {sectionTitle(
              "Gắn UTM (tuỳ chọn)",
              "Để biết người dùng đến từ kênh nào. Bỏ trống hết thì link giữ nguyên như trước. UTM chỉ gắn vào Link URL (web→app)."
            )}

            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-5">
              {renderUtmSelect(
                "source",
                "Nguồn (utm_source)",
                "Kênh cụ thể: zalo, facebook, tiktok…",
                UTM_SOURCES
              )}
              {renderUtmSelect(
                "medium",
                "Hình thức (utm_medium)",
                "Loại kênh: push, cpc, email, qr…",
                UTM_MEDIUMS
              )}
              <TextField
                fullWidth
                size="small"
                label="Chiến dịch (utm_campaign)"
                placeholder="VD: tet-2027"
                value={utm.campaign ?? ""}
                helperText="Nhập tay — tên chiến dịch mới mỗi lần."
                onChange={(e) => setUtmField("campaign", e.target.value)}
              />
              <TextField
                fullWidth
                size="small"
                label="Nội dung (utm_content)"
                placeholder="VD: banner-a"
                value={utm.content ?? ""}
                helperText="Phân biệt hai mẫu cùng chiến dịch."
                onChange={(e) => setUtmField("content", e.target.value)}
              />
              <TextField
                fullWidth
                size="small"
                label="Từ khoá (utm_term)"
                placeholder="VD: hoc_tieng_anh"
                value={utm.term ?? ""}
                helperText="Từ khoá quảng cáo, nếu có."
                onChange={(e) => setUtmField("term", e.target.value)}
              />
            </div>
          </section>

          <hr className="my-6 border-gray-200" />

          {/* ── Kết quả ──────────────────────────────────────────────────── */}
          <section>
            {sectionTitle(
              "Kết quả",
              "Tự cập nhật khi bạn chọn/nhập. Bấm Copy trên tiêu đề mỗi ô để sao chép."
            )}

            <Tabs
              value={tab}
              onChange={(_, next) => setTab(next)}
              variant="scrollable"
              scrollButtons="auto"
              className="mb-4 border-b border-gray-200"
            >
              <Tab label="Link & Link rút gọn" />
              <Tab label="Notification" />
              <Tab label="Popup" />
              <Tab label="Banner" />
            </Tabs>

            {tab === 0 && (
              <div className="flex flex-col gap-4">
                {renderResultBox(
                  "Link URL (web→app)",
                  "Người ĐÃ cài app bấm vào sẽ mở app đúng màn. Người CHƯA cài được đưa ra store — mở app lần đầu vẫn phải qua onboarding, không vào thẳng màn được.",
                  webUrl,
                  "Dán vào push (OneSignal), bài Zalo/Facebook, email, QR."
                )}

                <div className="rounded-lg border border-gray-200 bg-gray-50 p-4">
                  <div className="mb-2 flex items-start justify-between gap-3">
                    <div className="text-sm font-semibold">
                      <LabelWithHelp
                        text="Link rút gọn"
                        help="Cần phần server của giai đoạn 2: một slug lưu trong DB mang đích, cộng endpoint để app hỏi slug đó nghĩa là gì."
                      />
                    </div>
                    <Button size="small" variant="contained" color="warning" disabled>
                      Tạo link rút gọn
                    </Button>
                  </div>
                  <Alert severity="info" className="mt-1">
                    Chưa làm được ở bản này. Link ngắn dạng <code>/s/abc123</code>{" "}
                    cần server lưu slug kèm đích, và vì{" "}
                    <code>apple-app-site-association</code> khai{" "}
                    <code>paths: ["*"]</code> nên app sẽ bắt luôn cả{" "}
                    <code>/s/…</code> mà không hiểu nó là gì → rơi về Trang chủ.
                    Dùng Link URL ở trên; cần link ngắn để in QR thì nói để làm
                    giai đoạn 2 (kèm thống kê lượt bấm + đổi được đích sau khi in).
                  </Alert>
                </div>
              </div>
            )}

            {tab === 1 && (
              <div className="flex flex-col gap-4">
                {renderResultBox(
                  "Link cho push ngoài (OneSignal…)",
                  "Công cụ push ngoài mở URL, nên dùng bản https. Người nhận đã cài app nên link mở thẳng màn.",
                  webUrl,
                  "Dán vào ô Launch URL / deep link của công cụ push."
                )}
                <Alert severity="warning">
                  Trang <strong>Thông báo định kỳ</strong> của Meup{" "}
                  <strong>không</strong> nhận URL — nó chọn đích bằng danh sách có
                  sẵn (<code>home</code>, <code>resume_lesson</code>,{" "}
                  <code>habit_tracker</code>, <code>new_course</code>,{" "}
                  <code>explore</code>). Link ở đây là để dán vào công cụ push
                  bên ngoài.
                </Alert>
              </div>
            )}

            {tab === 2 &&
              renderResultBox(
                "Link cho Popup Home",
                "Popup nằm trong app nên dùng scheme meup:// — mở thẳng màn, không phải đi vòng qua OS.",
                appUrl,
                "Dán vào ô link của Popup Home. UTM không gắn vào đây: người dùng đã ở trong app."
              )}

            {tab === 3 &&
              renderResultBox(
                "Link cho Banner Home",
                "Banner nằm trong app nên dùng scheme meup:// — mở thẳng màn, không phải đi vòng qua OS.",
                appUrl,
                "Dán vào ô link của Banner Home. UTM không gắn vào đây: người dùng đã ở trong app."
              )}
          </section>
        </Paper>
      )}
    </div>
  );
}
