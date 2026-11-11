import React, { useEffect, useState } from "react";
import { Volume2Icon } from "lucide-react";
import {
  IKeypoint,
  KeypointPayload,
} from "../../types/interface/keypoint.interface";
import CloudflareFileUpload from "../files/CloudflareFileUpload";
import { voiceoverService } from "../../services/voiceoverService";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { ITranslation } from "../../utils/translate";
import { LangCode } from "../../types/enum/common.enum";
import { updateTranslationValue, cleanTranslation } from "../../utils/translation";
import { useNotification } from "../../utils/hooks/useNotification";
import {
  EstimateCompleteTimeUnit,
  buildEstimateCompleteTimeValue,
  getEstimateCompleteTimeUnitLabel,
  parseEstimateCompleteTimeInput,
} from "../../utils/estimate-complete-time";

interface Props {
  open: boolean;
  onClose: () => void;
  keypoint: IKeypoint | null;
  onSave: (data: KeypointPayload) => Promise<void> | void;
}

interface BuildKeypointPayloadParams {
  title: ITranslation;
  description: ITranslation;
  estimateCompleTime: ITranslation;
  estimateCompleTimeInput: string;
  estimateCompleTimeUnit: EstimateCompleteTimeUnit;
  image: string;
  tag: string[];
  lang: LangCode;
  keypoint: IKeypoint | null;
}

export const buildKeypointPayload = ({
  title,
  description,
  estimateCompleTime,
  estimateCompleTimeInput,
  estimateCompleTimeUnit,
  image,
  tag,
  lang,
}: BuildKeypointPayloadParams): KeypointPayload => {
  const cleanedTitle = cleanTranslation(title);
  const cleanedDescription = cleanTranslation(
    updateTranslationValue(description, lang, description[lang] || "")
  );
  const {
    label: estimateCompleTimeLabel,
    estimateCompleTimeNumber,
  } = buildEstimateCompleteTimeValue(
    estimateCompleTimeInput,
    estimateCompleTimeUnit,
    lang
  );
  const cleanedEstimateCompleTime = cleanTranslation(
    updateTranslationValue(estimateCompleTime, lang, estimateCompleTimeLabel)
  );

  // Audio is intentionally NOT part of the keypoint payload anymore — it is
  // produced only by the TTS voiceover flow (keypoint.audio.url), so saving a
  // keypoint here never touches or wipes generated audio.
  return {
    title: cleanedTitle || {},
    ...(cleanedDescription && { description: cleanedDescription }),
    ...(cleanedEstimateCompleTime && {
      estimateCompleTime: cleanedEstimateCompleTime,
    }),
    ...(Number.isFinite(estimateCompleTimeNumber) && {
      estimateCompleTimeNumber,
    }),
    image,
    tag,
  };
};

const KeypointModal: React.FC<Props> = ({
  open,
  onClose,
  keypoint,
  onSave,
}) => {
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showSuccess, showError } = useNotification();

  const [title, setTitle] = useState<ITranslation>({});
  const [description, setDescription] = useState<ITranslation>({});
  const [estimateCompleTime, setEstimateCompleTime] = useState<ITranslation>({});
  const [generatingVoiceover, setGeneratingVoiceover] = useState(false);
  const [estimateCompleTimeInput, setEstimateCompleTimeInput] = useState("");
  const [estimateCompleTimeUnit, setEstimateCompleTimeUnit] =
    useState<EstimateCompleteTimeUnit>("minute");
  const [image, setImage] = useState("");
  const [tag, setTag] = useState<string[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const applyEstimateCompleTime = (
    amount: string,
    unit: EstimateCompleteTimeUnit
  ) => {
    const { label } = buildEstimateCompleteTimeValue(amount, unit, lang);
    setEstimateCompleTime((prev) => updateTranslationValue(prev, lang, label));
  };

  useEffect(() => {
    if (keypoint) {
      setTitle(keypoint.title ?? {});
      setDescription(keypoint.description ?? {});
      setEstimateCompleTime(keypoint.estimateCompleTime ?? {});
      setImage(keypoint.image ?? "");
      setTag(keypoint.tag || []);

      const parsed = parseEstimateCompleteTimeInput(
        keypoint.estimateCompleTime,
        keypoint.estimateCompleTimeNumber,
        lang
      );
      setEstimateCompleTimeInput(parsed.amount);
      setEstimateCompleTimeUnit(parsed.unit);
    } else {
      setTitle({});
      setDescription({});
      setEstimateCompleTime({});
      setEstimateCompleTimeInput("");
      setEstimateCompleTimeUnit("minute");
      setImage("");
      setTag([]);
    }
  }, [keypoint, lang]);

  const handleGenerateVoiceover = async () => {
    if (!keypoint?._id) return;
    try {
      setGeneratingVoiceover(true);
      const res = await voiceoverService.generateForKeypoint(keypoint._id);
      const r = res?.data ?? res;
      const gen = r?.generated?.length ?? 0;
      const skip = r?.skipped?.length ?? 0;
      const fail = r?.failed?.length ?? 0;
      const empty = r?.empty?.length ?? 0;
      if (gen === 0 && skip === 0) {
        showError(
          empty > 0
            ? "No theory content to voice for this keypoint"
            : "Voiceover generated nothing"
        );
      } else {
        showSuccess(
          `Voiceover: ${gen} generated, ${skip} unchanged` +
            (fail ? `, ${fail} failed` : "")
        );
      }
    } catch (err) {
      console.error("Generate voiceover failed:", err);
      showError(
        (err as any)?.response?.data?.message || "Failed to generate voiceover"
      );
    } finally {
      setGeneratingVoiceover(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!cleanTranslation(title)) {
      showError("Title is required");
      return;
    }

    const payload = buildKeypointPayload({
      title,
      description,
      estimateCompleTime,
      estimateCompleTimeInput,
      estimateCompleTimeUnit,
      image,
      tag,
      lang,
      keypoint,
    });

    try {
      setIsSubmitting(true);
      await onSave(payload);
      showSuccess(
        keypoint ? "Saved keypoint successfully" : "Create keypoint successfully"
      );
    } catch (err) {
      console.error("Save keypoint failed:", err);
      showError((err as any)?.response?.data?.message || "Failed to save keypoint");
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-40 z-50">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-3xl p-6 max-h-[90vh] overflow-y-auto">
        <h2 className="text-xl font-semibold mb-4">
          {keypoint ? "Edit Keypoint" : "Create Keypoint"}
        </h2>

        <form onSubmit={handleSubmit} className="space-y-3">
          {/* Title */}
          <label className="block text-sm font-medium mb-1">Title</label>
          <input
            className="w-full border rounded-lg px-3 py-2"
            placeholder="Title"
            value={title[lang] || ""}
            onChange={(e) => setTitle((prev) => updateTranslationValue(prev, lang, e.target.value))}
          />

          {/* Description */}
          <label className="block text-sm font-medium mb-1">Description</label>
          <textarea
            className="w-full border rounded-lg px-3 py-2"
            placeholder="Description"
            value={description[lang] || ""}
            onChange={(e) =>
              setDescription((prev) =>
                updateTranslationValue(prev, lang, e.target.value)
              )
            }
            rows={3}
          />

          {/* Time complete */}
          <label className="block text-sm font-medium mb-1">
            Time complete
          </label>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <select
              value={estimateCompleTimeUnit}
              onChange={(e) => {
                const nextUnit = e.target.value as EstimateCompleteTimeUnit;
                setEstimateCompleTimeUnit(nextUnit);
                applyEstimateCompleTime(estimateCompleTimeInput, nextUnit);
              }}
              className="w-full border rounded-lg px-3 py-2 bg-white"
            >
              <option value="minute">
                {getEstimateCompleteTimeUnitLabel(
                  "minute",
                  lang as LangCode,
                  2
                )}
              </option>
              <option value="hour">
                {getEstimateCompleteTimeUnitLabel("hour", lang as LangCode, 2)}
              </option>
            </select>
            <input
              type="number"
              min={1}
              step={1}
              className="w-full border rounded-lg px-3 py-2 sm:col-span-2"
              placeholder="Enter number..."
              value={estimateCompleTimeInput}
              onChange={(e) => {
                const nextAmount = e.target.value;
                setEstimateCompleTimeInput(nextAmount);
                applyEstimateCompleTime(nextAmount, estimateCompleTimeUnit);
              }}
            />
          </div>

          {/* Image */}
          <div>
            <label className="block text-sm font-medium mb-1">Image URL</label>
            <CloudflareFileUpload
              initialUrl={image || ""}
              onUrlChange={setImage}
              label=""
              uploadPayload={{
                prefix: "",
                folder: "keypoints",
              }}
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">
              Listening audio (voiceover)
            </label>
            <div className="rounded-lg border border-gray-200 bg-gray-50 p-3">
              <p className="text-xs text-gray-600 mb-2">
                Audio nghe được sinh tự động bằng TTS từ nội dung Theory của
                keypoint này (không nhập tay nữa). Lưu keypoint trước, rồi bấm
                để sinh/cập nhật giọng đọc cho mọi ngôn ngữ.
              </p>
              <button
                type="button"
                onClick={handleGenerateVoiceover}
                disabled={!keypoint?._id || generatingVoiceover}
                className="inline-flex items-center gap-2 rounded-lg bg-bronze-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-bronze-700 disabled:cursor-not-allowed disabled:opacity-60"
              >
                <Volume2Icon className="h-4 w-4" />
                {generatingVoiceover ? "Generating…" : "Generate voiceover"}
              </button>
              {!keypoint?._id && (
                <p className="mt-2 text-xs text-gray-400">
                  Tạo/lưu keypoint trước để bật nút này.
                </p>
              )}
            </div>
          </div>

          {/* Actions */}
          <div className="flex justify-end gap-2 pt-4">
            <button
              type="button"
              className="px-4 py-2 rounded-lg border hover:bg-gray-100"
              onClick={onClose}
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-4 py-2 rounded-lg bg-brand-600 text-white hover:bg-brand-700"
            >
              {isSubmitting ? "Saving..." : "Save"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default KeypointModal;
