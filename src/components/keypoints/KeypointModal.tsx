import React, { useEffect, useState } from "react";
import {
  IKeypoint,
  KeypointPayload,
} from "../../types/interface/keypoint.interface";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { ITranslation } from "../../utils/translate";
import { updateTranslationValue, cleanTranslation } from "../../utils/translation";

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
  const [image, setImage] = useState("");
  const [tag, setTag] = useState<string[]>([]);

  const [newTag, setNewTag] = useState("");

  useEffect(() => {
    if (keypoint) {
      setTitle(keypoint.title ?? {});
      setDescription(keypoint.description ?? {});
      setImage(keypoint.image ?? "");
      setTag(keypoint.tag || []);
      setNewTag("");
    } else {
      setTitle({});
      setDescription({});
      setImage("");
      setTag([]);
      setNewTag("");
    }
  }, [keypoint]);

  const addTag = () => {
    if (newTag.trim()) {
      setTag((prev) => [...prev, newTag.trim()]);
      setNewTag("");
    }
  };

  const removeTag = (index: number) => {
    setTag((prev) => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Update and clean translations
    const cleanedTitle = cleanTranslation(
      updateTranslationValue(title, lang, title[lang] || "")
    );
    const cleanedDescription = cleanTranslation(
      updateTranslationValue(description, lang, description[lang] || "")
    );

    // Create KeypointPayload with cleaned translations
    const payload: KeypointPayload = {
      title: cleanedTitle || { [lang]: "" }, // Always include title
      ...(cleanedDescription && { description: cleanedDescription }),
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
            onChange={(e) => setDescription((prev) => updateTranslationValue(prev, lang, e.target.value))}
            rows={3}
          />

          {/* Tag */}
          <label className="block text-sm font-medium mb-1">Tags</label>

          {/* Hiển thị các tag hiện có */}
          {tag && tag.length > 0 && (
            <div className="flex flex-wrap gap-2 mb-2">
              {tag.map((tagItem, index) => (
                <div
                  key={index}
                  className="flex items-center bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm"
                >
                  <span>{tagItem}</span>
                  <button
                    type="button"
                    className="ml-2 text-blue-600 hover:text-blue-800"
                    onClick={() => removeTag(index)}
                  >
                    ×
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* Input để thêm tag mới */}
          <div className="flex gap-2">
            <input
              type="text"
              className="flex-1 border rounded-lg px-3 py-2"
              placeholder="Add a tag"
              value={newTag}
              onChange={(e) => setNewTag(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  addTag();
                }
              }}
            />
            <button
              type="button"
              className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
              onClick={addTag}
            >
              Add
            </button>
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
