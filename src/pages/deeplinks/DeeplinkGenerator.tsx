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
  TextField,
  Tooltip,
} from "@mui/material";
import { Copy } from "lucide-react";

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
  buildDeeplinkUrl,
} from "../../utils/deeplinkUrl";
import { useNotification } from "../../utils/hooks/useNotification";

interface Option {
  id: string;
  label: string;
}

const labelOf = (title?: ITranslation): string =>
  title?.vi || title?.en || "(chưa có tên)";

/** Nhãn tiếng Việt cho từng tham số, để marketer không phải đọc tên khoá. */
const PARAM_LABELS: Record<string, string> = {
  courseId: "Khoá học",
  keypointId: "Keypoint (bài cụ thể)",
  skillsetId: "Kỹ năng",
  variant: "Biến thể paywall",
};

const paramLabel = (param: IDeeplinkParam): string =>
  PARAM_LABELS[param.name] ?? param.name;

export default function DeeplinkGenerator() {
  const { showSuccess, showError } = useNotification();

  const [destinations, setDestinations] = useState<IDeeplinkDestination[]>([]);
  const [isLoadingCatalog, setIsLoadingCatalog] = useState(true);
  const [catalogError, setCatalogError] = useState("");

  const [selectedKey, setSelectedKey] = useState("");
  const [paramValues, setParamValues] = useState<Record<string, string>>({});
  const [campaign, setCampaign] = useState("");

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

  const canCopy = Boolean(selected) && missingRequired.length === 0;

  const webUrl = selected
    ? buildDeeplinkUrl(DEEPLINK_WEB_BASE, selected.key, paramValues, campaign)
    : "";
  const appUrl = selected
    ? buildDeeplinkUrl(DEEPLINK_APP_BASE, selected.key, paramValues, campaign)
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

  const quickPicks = useMemo(
    () => destinations.filter((destination) => destination.params.length === 0),
    [destinations]
  );

  const copy = async (value: string) => {
    try {
      await navigator.clipboard.writeText(value);
      showSuccess("Đã copy link");
    } catch (error) {
      console.error("Clipboard write failed", error);
      showError("Không copy được — bôi đen rồi copy tay nhé");
    }
  };

  const setParam = (name: string, value: string) =>
    setParamValues((previous) => ({ ...previous, [name]: value }));

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
            {!param.required && <MenuItem value="">(không chọn)</MenuItem>}
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

  const renderUrlRow = (label: string, url: string, hint: string) => (
    <div className="mb-4">
      <div className="flex items-start gap-2">
        <TextField
          fullWidth
          size="small"
          label={label}
          value={url}
          InputProps={{ readOnly: true }}
        />
        <Tooltip title={canCopy ? `Copy ${label}` : "Còn thiếu thông tin"}>
          <span>
            <IconButton
              aria-label={`Copy ${label}`}
              disabled={!canCopy || !url}
              onClick={() => copy(url)}
            >
              <Copy size={18} />
            </IconButton>
          </span>
        </Tooltip>
      </div>
      <p className="mt-1 text-xs text-gray-500">{hint}</p>
    </div>
  );

  return (
    <div className="p-6">
      <header className="mb-5">
        <h1 className="text-xl font-semibold">Link vào màn</h1>
        <p className="mt-1 max-w-3xl text-sm text-gray-500">
          Sinh link dẫn thẳng vào một màn trong app — dán vào push notification,
          vào ô link của Banner/Popup Home, vào bài Zalo/Facebook, hay email gửi
          riêng. Người <strong>đã cài app</strong> bấm link web sẽ mở app đúng
          màn; người <strong>chưa cài</strong> được đưa ra store (mở app lần đầu
          vẫn phải qua onboarding, không vào thẳng màn được).
          <br />
          Đây không phải trang <strong>Link tải app</strong> — trang đó dùng cho
          link tải kèm thống kê lượt bấm.
        </p>
      </header>

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
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          {/* Màn phổ biến: các màn không cần tham số, copy một nhát là xong. */}
          <Paper className="p-4">
            <h2 className="mb-1 text-base font-semibold">Màn phổ biến</h2>
            <p className="mb-3 text-sm text-gray-500">
              Không cần chọn gì thêm — bấm copy là dùng được.
            </p>
            <div className="divide-y">
              {quickPicks.map((destination) => (
                <div
                  key={destination.key}
                  className="flex items-center justify-between gap-3 py-2"
                >
                  <div className="min-w-0">
                    <div className="truncate text-sm font-medium">
                      {destination.label}
                    </div>
                    <div className="truncate font-mono text-xs text-gray-500">
                      {`${DEEPLINK_WEB_BASE}/${destination.key}`}
                    </div>
                  </div>
                  <IconButton
                    aria-label={`Copy link ${destination.label}`}
                    onClick={() =>
                      copy(`${DEEPLINK_WEB_BASE}/${destination.key}`)
                    }
                  >
                    <Copy size={18} />
                  </IconButton>
                </div>
              ))}
            </div>
          </Paper>

          <Paper className="p-4">
            <h2 className="mb-3 text-base font-semibold">Sinh link</h2>

            <FormControl fullWidth size="small" className="mb-4">
              <InputLabel id="destination-label">Màn đích</InputLabel>
              <Select
                labelId="destination-label"
                label="Màn đích"
                value={selectedKey}
                onChange={(e) => handleSelectDestination(e.target.value)}
              >
                {groups.map(([group, items]) => [
                  <ListSubheader key={`group-${group}`}>{group}</ListSubheader>,
                  ...items.map((destination) => (
                    <MenuItem key={destination.key} value={destination.key}>
                      {destination.label}
                    </MenuItem>
                  )),
                ])}
              </Select>
            </FormControl>

            {!selected ? (
              <p className="py-6 text-center text-sm text-gray-500">
                Chọn một màn đích để sinh link.
              </p>
            ) : (
              <>
                {selected.note && (
                  <Alert severity="info" className="mb-4">
                    {selected.note}
                  </Alert>
                )}

                <Alert severity="warning" className="mb-4">
                  {`Chỉ hoạt động trên bản app build ≥ ${selected.minAppBuild}. Người dùng bản cũ hơn sẽ về Trang chủ.`}
                </Alert>

                <div className="mb-2 flex flex-col gap-1">
                  {selected.params.map(renderParamField)}
                </div>

                <TextField
                  fullWidth
                  size="small"
                  className="mb-4"
                  label="Nhãn campaign (tuỳ chọn)"
                  placeholder="tet-2027"
                  value={campaign}
                  helperText="Chỉ dùng để đo trong Analytics, không ảnh hưởng màn đích."
                  onChange={(e) => setCampaign(e.target.value)}
                />

                {renderUrlRow(
                  "Link web",
                  webUrl,
                  "Dán vào push, Zalo/Facebook, email, QR."
                )}
                {renderUrlRow(
                  "Link trong app",
                  appUrl,
                  "Dán vào ô link của Banner Home / Popup Home."
                )}
              </>
            )}
          </Paper>
        </div>
      )}
    </div>
  );
}
