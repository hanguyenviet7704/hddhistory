import React, { useEffect, useState } from "react";
import {
  IKeypoint,
  KeypointPayload,
} from "../../types/interface/keypoint.interface";
import CloudflareFileUpload from "../files/CloudflareFileUpload";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { ITranslation } from "../../utils/translate";
import { LangCode } from "../../types/enum/common.enum";
import { updateTranslationValue, cleanTranslation } from "../../utils/translation";
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
  onSave: (data: KeypointPayload) => void;
}

const KeypointModal: React.FC<Props> = ({
  open,
  onClose,
  keypoint,
  onSave,
}) => {
  const lang = useSelector((state: RootState) => state.lang.code);

  const [title, setTitle] = useState<ITranslation>({});
  const [description, setDescription] = useState<ITranslation>({});
  const [estimateCompleTime, setEstimateCompleTime] = useState<ITranslation>({});
  const [estimateCompleTimeInput, setEstimateCompleTimeInput] = useState("");
  const [estimateCompleTimeUnit, setEstimateCompleTimeUnit] =
    useState<EstimateCompleteTimeUnit>("minute");
  const [image, setImage] = useState("");
  const [tag, setTag] = useState<string[]>([]);

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

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Update and clean translations
    const cleanedTitle = cleanTranslation(
      updateTranslationValue(title, lang, title[lang] || "")
    );
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
      updateTranslationValue(
        estimateCompleTime,
        lang,
        estimateCompleTimeLabel
      )
    );

    // Create KeypointPayload with cleaned translations
    const payload: KeypointPayload = {
      title: cleanedTitle || { [lang]: "" }, // Always include title
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

    onSave(payload);
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-40 z-50">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-lg p-6">
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
              className="px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700"
            >
              Save
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default KeypointModal;
