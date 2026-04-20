import React, { useEffect, useState } from "react";
import {
  IKeypoint,
  IKeypointAudio,
  KeypointPayload,
} from "../../types/interface/keypoint.interface";
import CloudflareFileUpload from "../files/CloudflareFileUpload";
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
  audio: IKeypointAudio;
  image: string;
  tag: string[];
  lang: LangCode;
  keypoint: IKeypoint | null;
}

const hasKeypointAudioContent = (audio?: IKeypointAudio) =>
  Boolean(cleanTranslation(audio?.url) || cleanTranslation(audio?.text));

export const buildKeypointPayload = ({
  title,
  description,
  estimateCompleTime,
  estimateCompleTimeInput,
  estimateCompleTimeUnit,
  audio,
  image,
  tag,
  lang,
  keypoint,
}: BuildKeypointPayloadParams): KeypointPayload => {
  const titleValue = (title[lang] || "").trim();
  const cleanedTitle = cleanTranslation(
    updateTranslationValue(title, lang, titleValue)
  );
  const cleanedDescription = cleanTranslation(
    updateTranslationValue(description, lang, description[lang] || "")
  );
  const cleanedAudioUrl = cleanTranslation(
    updateTranslationValue(audio.url, lang, (audio.url?.[lang] || "").trim())
  );
  const cleanedAudioText = cleanTranslation(
    updateTranslationValue(audio.text, lang, audio.text?.[lang] || "")
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
  const shouldClearAudio =
    Boolean(keypoint?._id) &&
    hasKeypointAudioContent(keypoint?.audio) &&
    !cleanedAudioUrl &&
    !cleanedAudioText;

  return {
    title: cleanedTitle || { [lang]: "" },
    ...(cleanedDescription && { description: cleanedDescription }),
    ...(cleanedEstimateCompleTime && {
      estimateCompleTime: cleanedEstimateCompleTime,
    }),
    ...((cleanedAudioUrl || cleanedAudioText) && {
      audio: {
        ...(cleanedAudioUrl && { url: cleanedAudioUrl }),
        ...(cleanedAudioText && { text: cleanedAudioText }),
      },
    }),
    ...(shouldClearAudio && { audio: {} }),
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
  const [audio, setAudio] = useState<IKeypointAudio>({});
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
      setAudio(keypoint.audio ?? {});
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
      setAudio({});
      setEstimateCompleTimeInput("");
      setEstimateCompleTimeUnit("minute");
      setImage("");
      setTag([]);
    }
  }, [keypoint, lang]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const titleValue = (title[lang] || "").trim();

    if (!titleValue) {
      showError("Title is required");
      return;
    }

    const payload = buildKeypointPayload({
      title,
      description,
      estimateCompleTime,
      estimateCompleTimeInput,
      estimateCompleTimeUnit,
      audio,
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
            required
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
            <label className="block text-sm font-medium mb-1">Audio</label>
            <CloudflareFileUpload
              initialUrl={audio.url?.[lang] || ""}
              onUrlChange={(newUrl) =>
                setAudio((prev) => ({
                  ...prev,
                  url: updateTranslationValue(prev.url, lang, newUrl),
                }))
              }
              label=""
              accept="audio/*"
              uploadPayload={{
                prefix: "",
                folder: "keypoints/audio",
              }}
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Audio text</label>
            <textarea
              className="w-full border rounded-lg px-3 py-2"
              placeholder="Enter transcript or audio text"
              value={audio.text?.[lang] || ""}
              onChange={(e) =>
                setAudio((prev) => ({
                  ...prev,
                  text: updateTranslationValue(
                    prev.text,
                    lang,
                    e.target.value
                  ),
                }))
              }
              rows={8}
            />
            <p className="mt-1 text-xs text-gray-500">
              Có thể nhập transcript dài trực tiếp trong modal này.
            </p>
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
              className="px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700"
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
